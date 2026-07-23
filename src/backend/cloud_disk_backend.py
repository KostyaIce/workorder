#!/usr/bin/env python3
"""Cloud disk backend: Yandex Disk OAuth + DB upload/download."""

from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request

from qt_compat import QDesktopServices, QObject, QUrl, pyqtProperty, pyqtSignal, pyqtSlot

from app_paths import data_dir
from utils.qsettings_store import QSettingsStore


_KEY_TOKEN = "cloud_disk/token"
_KEY_DISK_URL = "cloud_disk/disk_url"
_KEY_CLIENT_ID_LEGACY = "cloud_disk/client_id"
_DEFAULT_DISK_URL = "https://cloud-api.yandex.net/v1/disk"
_AUTH_BASE_URL = "https://oauth.yandex.ru/authorize"
_YANDEX_CLIENT_ID = "d3e1a705454a448b841e617117fec451"
_WORKORDER_FOLDER_PATH = "app:/workOrder"
_TOKEN_IN_URL_RE = re.compile(r"access_token=([^&\s#]+)")
_LIST_LIMIT = 1000


class CloudDiskBackend(QObject):
    """Connect to Yandex Disk via OAuth token; list/upload/download DB files."""

    connectionChanged = pyqtSignal()
    busyChanged = pyqtSignal()
    statusMessageChanged = pyqtSignal()
    entriesChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._disk_url = _DEFAULT_DISK_URL
        self._token = ""
        self._status_message = ""
        self._entries = []
        self._busy = False
        self._load_persisted()
        if not self._token:
            self._set_status_message("Диск не подключён")
        else:
            self._set_status_message("Диск подключён")

    def _load_persisted(self):
        with QSettingsStore() as store:
            self._token = (store.read(_KEY_TOKEN, "", value_type=str) or "").strip()
            saved_url = store.read(_KEY_DISK_URL, "", value_type=str) or ""
            self._disk_url = self._normalize_disk_url(
                saved_url if saved_url else _DEFAULT_DISK_URL
            )
            store.remove(_KEY_CLIENT_ID_LEGACY)

    def _persist_credentials(self):
        with QSettingsStore() as store:
            if self._token:
                store.write(_KEY_TOKEN, self._token)
            else:
                store.remove(_KEY_TOKEN)
            store.write(_KEY_DISK_URL, self._disk_url)
            store.remove(_KEY_CLIENT_ID_LEGACY)

    @staticmethod
    def _normalize_disk_url(value: str) -> str:
        url = (value or "").strip() or _DEFAULT_DISK_URL
        return url.rstrip("/")

    @staticmethod
    def _extract_token(token_or_url: str) -> str:
        raw = (token_or_url or "").strip()
        if not raw:
            return ""
        match = _TOKEN_IN_URL_RE.search(raw)
        if match:
            return urllib.parse.unquote(match.group(1)).strip()
        if " " in raw or "\n" in raw:
            return ""
        return raw

    def _set_busy(self, value: bool):
        if self._busy == value:
            return
        self._busy = value
        self.busyChanged.emit()

    def _set_status_message(self, message: str):
        if self._status_message == message:
            return
        self._status_message = message
        self.statusMessageChanged.emit()

    def _set_entries(self, entries):
        self._entries = list(entries)
        self.entriesChanged.emit()

    def _resources_url(self, path: str = _WORKORDER_FOLDER_PATH, limit: int | None = 100) -> str:
        params = {"path": path}
        if limit is not None and limit > 0:
            params["limit"] = str(limit)
        query = urllib.parse.urlencode(params)
        return f"{self._disk_url}/resources?{query}"

    def _upload_url(self, remote_path: str, overwrite: bool = True) -> str:
        query = urllib.parse.urlencode(
            {"path": remote_path, "overwrite": "true" if overwrite else "false"}
        )
        return f"{self._disk_url}/resources/upload?{query}"

    def _download_url(self, remote_path: str) -> str:
        query = urllib.parse.urlencode({"path": remote_path})
        return f"{self._disk_url}/resources/download?{query}"

    def _remote_db_path(self, file_name: str) -> str:
        return f"{_WORKORDER_FOLDER_PATH}/{file_name}"

    def _authorized_request(self, url: str, method: str = "GET", data=None, headers=None):
        hdrs = {
            "Authorization": f"OAuth {self._token}",
            "Accept": "application/json",
        }
        if headers:
            hdrs.update(headers)
        return urllib.request.Request(url, data=data, headers=hdrs, method=method)

    def _perform_request(self, method: str, url: str, data=None, headers=None):
        request = self._authorized_request(url, method=method, data=data, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                return response.getcode(), response.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()

    def _list_folder_items(self):
        status, body = self._perform_request(
            "GET", self._resources_url(_WORKORDER_FOLDER_PATH, limit=_LIST_LIMIT)
        )
        if status != 200:
            return status, []
        payload = json.loads(body.decode("utf-8"))
        return status, payload.get("_embedded", {}).get("items", []) or []

    @staticmethod
    def _local_database_names():
        root = data_dir()
        if not root.is_dir():
            return []
        return sorted(path.name for path in root.iterdir() if path.suffix.lower() == ".db")

    @staticmethod
    def _clear_local_database_files() -> bool:
        root = data_dir()
        if not root.is_dir():
            return True
        for path in root.iterdir():
            name = path.name.lower()
            if not (
                name.endswith(".db")
                or name.endswith(".db-wal")
                or name.endswith(".db-shm")
            ):
                continue
            try:
                path.unlink()
            except OSError:
                return False
        return True

    def _ensure_folder(self) -> bool:
        self._set_status_message("Проверка каталога workOrder...")
        url = self._resources_url(_WORKORDER_FOLDER_PATH, limit=None)
        try:
            status, body = self._perform_request("GET", url)
        except Exception as exc:
            self._set_status_message(f"Ошибка сети: {exc}")
            return False

        if status == 200:
            payload = json.loads(body.decode("utf-8"))
            if payload.get("type") == "dir":
                return True
            self._set_status_message("Путь workOrder существует, но это не каталог")
            return False

        if status != 404:
            self._set_status_message(f"Не удалось проверить каталог workOrder ({status})")
            return False

        self._set_status_message("Создание каталога workOrder...")
        try:
            put_status, _ = self._perform_request("PUT", url)
        except Exception as exc:
            self._set_status_message(f"Ошибка сети: {exc}")
            return False

        if put_status in (201, 409):
            return True
        self._set_status_message(f"Не удалось создать каталог workOrder ({put_status})")
        return False

    def _clear_cloud_folder(self) -> bool:
        self._set_status_message("Очистка облачного каталога...")
        status, items = self._list_folder_items()
        if status != 200:
            self._set_status_message(f"Не удалось прочитать облачный каталог ({status})")
            return False

        for item in items:
            path = item.get("path") or ""
            if not path:
                continue
            query = urllib.parse.urlencode({"path": path, "permanently": "true"})
            delete_url = f"{self._disk_url}/resources?{query}"
            del_status, _ = self._perform_request("DELETE", delete_url)
            if del_status not in (204, 202, 404):
                self._set_status_message(f"Не удалось очистить облако ({del_status})")
                return False
        return True

    def _upload_file(self, local_path: str, remote_path: str) -> bool:
        status, body = self._perform_request("GET", self._upload_url(remote_path, True))
        if status != 200:
            self._set_status_message(f"Не удалось получить URL загрузки ({status})")
            return False
        href = json.loads(body.decode("utf-8")).get("href") or ""
        if not href:
            self._set_status_message("Пустой URL загрузки")
            return False

        with open(local_path, "rb") as handle:
            data = handle.read()
        request = urllib.request.Request(
            href,
            data=data,
            headers={"Content-Type": "application/octet-stream"},
            method="PUT",
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                put_status = response.getcode()
        except urllib.error.HTTPError as exc:
            put_status = exc.code

        if put_status not in (201, 202):
            self._set_status_message(f"Ошибка выгрузки файла ({put_status})")
            return False
        return True

    def _download_file(self, remote_path: str, local_path: str) -> bool:
        status, body = self._perform_request("GET", self._download_url(remote_path))
        if status != 200:
            self._set_status_message(f"Не удалось получить URL скачивания ({status})")
            return False
        href = json.loads(body.decode("utf-8")).get("href") or ""
        if not href:
            self._set_status_message("Пустой URL скачивания")
            return False

        request = self._authorized_request(href, method="GET")
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                data = response.read()
        except urllib.error.HTTPError as exc:
            self._set_status_message(f"Ошибка скачивания ({exc.code})")
            return False

        os.makedirs(os.path.dirname(local_path) or ".", exist_ok=True)
        with open(local_path, "wb") as handle:
            handle.write(data)
        return True

    @pyqtProperty(bool, notify=connectionChanged)
    def connected(self):
        return bool(self._token)

    @pyqtProperty(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    @pyqtProperty(str, notify=connectionChanged)
    def diskUrl(self):
        return self._disk_url

    @diskUrl.setter
    def diskUrl(self, value):
        normalized = self._normalize_disk_url(value)
        if self._disk_url == normalized:
            return
        self._disk_url = normalized
        if self.connected:
            self._persist_credentials()
        self.connectionChanged.emit()

    @pyqtProperty(str, constant=True)
    def clientId(self):
        return _YANDEX_CLIENT_ID

    @pyqtProperty(str, constant=True)
    def authUrl(self):
        query = urllib.parse.urlencode(
            {"response_type": "token", "client_id": _YANDEX_CLIENT_ID}
        )
        return f"{_AUTH_BASE_URL}?{query}"

    @pyqtProperty(str, notify=statusMessageChanged)
    def statusMessage(self):
        return self._status_message

    @pyqtProperty("QVariantList", notify=entriesChanged)
    def entries(self):
        return self._entries

    @pyqtSlot(result=bool)
    def openAuthInBrowser(self):
        if not QDesktopServices.openUrl(QUrl(self.authUrl)):
            self._set_status_message("Не удалось открыть браузер")
            return False
        self._set_status_message("Откройте ссылку в браузере, войдите и вставьте токен")
        return True

    @pyqtSlot(str, result=bool)
    def connectWithToken(self, token_or_url):
        token = self._extract_token(token_or_url)
        if not token:
            self._set_status_message("Токен пустой или не распознан")
            return False
        self._token = token
        self._disk_url = self._normalize_disk_url(self._disk_url)
        self._persist_credentials()
        self._set_entries([])
        self._set_status_message("Диск подключён")
        self.connectionChanged.emit()
        self.refreshContents()
        return True

    @pyqtSlot()
    def clearDiskData(self):
        self._token = ""
        self._set_entries([])
        with QSettingsStore() as store:
            store.remove(_KEY_TOKEN)
            store.remove(_KEY_DISK_URL)
            store.remove(_KEY_CLIENT_ID_LEGACY)
        self._set_busy(False)
        self._set_status_message("Данные диска удалены")
        self.connectionChanged.emit()

    @pyqtSlot()
    def refreshContents(self):
        if not self._token:
            self._set_status_message("Сначала подключите диск")
            return
        if self._busy:
            return

        self._set_busy(True)
        if not self._ensure_folder():
            self._set_busy(False)
            return

        self._set_status_message("Загрузка содержимого...")
        try:
            status, items = self._list_folder_items()
        except Exception as exc:
            self._set_busy(False)
            self._set_status_message(f"Ошибка сети: {exc}")
            return

        if status != 200:
            self._set_busy(False)
            self._set_status_message(f"Ошибка запроса ({status})")
            return

        entries = []
        for item in items:
            entries.append(
                {
                    "name": item.get("name", ""),
                    "type": item.get("type", ""),
                    "path": item.get("path", ""),
                }
            )
        self._set_busy(False)
        self._set_entries(entries)
        self._set_status_message(f"Найдено элементов: {len(entries)}")

    @pyqtSlot()
    def ensureWorkOrderDirectory(self):
        if not self._token:
            self._set_status_message("Сначала подключите диск")
            return
        if self._busy:
            return
        self._set_busy(True)
        ok = self._ensure_folder()
        self._set_busy(False)
        if ok:
            self._set_status_message("Каталог workOrder готов")

    @pyqtSlot()
    def syncDatabases(self):
        if not self._token:
            self._set_status_message("Сначала подключите диск")
            return
        if self._busy:
            return
        self._set_status_message("Синхронизация пока не реализована")

    @pyqtSlot()
    def forceUploadDatabases(self):
        if not self._token:
            self._set_status_message("Сначала подключите диск")
            return
        if self._busy:
            return

        self._set_busy(True)
        self._set_status_message("Выгрузка баз на диск...")
        try:
            if not self._ensure_folder():
                self._set_busy(False)
                return
            if not self._clear_cloud_folder():
                self._set_busy(False)
                return

            names = self._local_database_names()
            if not names:
                self._set_busy(False)
                self._set_status_message("Локальные файлы баз данных не найдены")
                return

            root = data_dir()
            for index, name in enumerate(names, start=1):
                self._set_status_message(f"Выгрузка {index}/{len(names)}: {name}")
                local_path = str(root / name)
                if not self._upload_file(local_path, self._remote_db_path(name)):
                    self._set_busy(False)
                    return

            self._set_busy(False)
            self._set_status_message(f"Выгрузка завершена: {len(names)} файл(ов)")
            self.refreshContents()
        except Exception as exc:
            self._set_busy(False)
            self._set_status_message(f"Ошибка выгрузки: {exc}")

    @pyqtSlot()
    def downloadDatabases(self):
        if not self._token:
            self._set_status_message("Сначала подключите диск")
            return
        if self._busy:
            return

        self._set_busy(True)
        self._set_status_message("Загрузка баз с диска...")
        try:
            if not self._ensure_folder():
                self._set_busy(False)
                return

            status, items = self._list_folder_items()
            if status != 200:
                self._set_busy(False)
                self._set_status_message(f"Не удалось прочитать облачный каталог ({status})")
                return

            files = []
            for item in items:
                if item.get("type") != "file":
                    continue
                name = item.get("name") or ""
                if not name.lower().endswith(".db"):
                    continue
                files.append(
                    {
                        "name": name,
                        "path": item.get("path") or self._remote_db_path(name),
                    }
                )

            if not files:
                self._set_busy(False)
                self._set_status_message("На диске нет файлов баз данных (*.db)")
                return

            if not self._clear_local_database_files():
                self._set_busy(False)
                self._set_status_message("Не удалось очистить локальные базы данных")
                return

            root = data_dir()
            for index, item in enumerate(files, start=1):
                name = item["name"]
                self._set_status_message(f"Загрузка {index}/{len(files)}: {name}")
                local_path = str(root / name)
                if not self._download_file(item["path"], local_path):
                    self._set_busy(False)
                    return

            self._set_busy(False)
            self._set_status_message(f"Загрузка завершена: {len(files)} файл(ов)")
            self.refreshContents()
        except Exception as exc:
            self._set_busy(False)
            self._set_status_message(f"Ошибка загрузки: {exc}")
