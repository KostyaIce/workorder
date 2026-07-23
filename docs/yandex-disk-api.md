# Яндекс.Диск REST API

Сводка по официальному [API Яндекс.Диска](https://yandex.ru/dev/disk-api/doc/ru/) для интеграции в WorkOrder.
Интеграция в приложении: [cloud-disk.md](cloud-disk.md).

Официальный быстрый старт: [Доступ к API](https://yandex.ru/dev/disk-api/doc/ru/concepts/quickstart).

---

## Базовые правила

| Параметр | Значение |
|----------|----------|
| Host API | `https://cloud-api.yandex.net` |
| Версия | `/v1/` |
| База Диска | `https://cloud-api.yandex.net/v1/disk` |
| Формат | только `application/json` (`Accept` / `Content-Type`) |
| Авторизация | заголовок `Authorization: OAuth <token>` |

Пути к ресурсам:

- `disk:/foo` и `/foo` — один и тот же путь;
- значение `path` в query нужно **URL-кодировать**;
- макс. длина имени — 255 символов, пути — 32760.

Загрузка и скачивание файлов идут **двухфазно**: сначала ссылка с API, затем PUT/GET на uploader/downloader (отдельные хосты).

---

## OAuth и права

Регистрация приложения: [oauth.yandex.ru](https://oauth.yandex.ru/), инструкция — [Справка OAuth](https://yandex.ru/dev/id/doc/ru/register-client).

Права API Диска (группа `cloud_api`):

| Право | Scope | Назначение |
|-------|-------|------------|
| Запись в любом месте | `cloud_api:disk.write` | создание папок, загрузка, удаление, перезапись |
| Чтение всего Диска | `cloud_api:disk.read` | метаданные, списки, скачивание |
| Папка приложения | `cloud_api:disk.app_folder` | доступ только к `app:/` |
| Информация о Диске | `cloud_api:disk.info` | объём, занятое место и т.п. |

Для WorkOrder при scope **`cloud_api:disk.app_folder`** (текущий режим):

- рабочие пути только под `app:/` (каталог `app:/workOrder`);
- запросы к `disk:/` или `/` дают **403 Forbidden**.

Права `disk.read` / `disk.write` нужны только если позже понадобится весь Диск.

Получение токена (implicit, ручная вставка — текущий сценарий приложения):

```text
https://oauth.yandex.ru/authorize?response_type=token&client_id=<ClientID>
```

Redirect URI приложения: `https://oauth.yandex.ru/verification_code`.

Пример заголовка:

```http
Authorization: OAuth 0c4181a7c2cf4521964a72ff57a34a07
```

Токены в кабинете OAuth **не хранятся** публично — если не сохранили, нужно получить заново.

---

## Метаданные файла или папки

Документация: [Метаинформация](https://yandex.ru/dev/disk-api/doc/ru/reference/meta).

```http
GET https://cloud-api.yandex.net/v1/disk/resources?path=<path>&limit=<n>&offset=<n>&sort=<attr>
Authorization: OAuth <token>
```

Полезные query:

| Параметр | Описание |
|----------|----------|
| `path` | путь к ресурсу (обязательный) |
| `limit` | сколько вложенных элементов вернуть (по умолчанию 20) |
| `offset` | смещение для постраничного вывода |
| `sort` | атрибут сортировки |
| `fields` | сократить JSON-ответ (через запятую) |

Успех: `200 OK`.  
Для папки содержимое — в `_embedded.items`.

Ключевые поля ресурса (`Resource`):

| Поле | Смысл |
|------|--------|
| `name` | имя |
| `path` | полный путь (`disk:/...`) |
| `type` | `dir` или `file` |
| `size` | размер файла |
| `mime_type` | MIME файла |
| `md5` | MD5 файла |
| `created` / `modified` | ISO 8601 |
| `_embedded` | список вложенных ресурсов (только для папки) |

Пример (корень Диска):

```bash
curl -H "Authorization: OAuth $TOKEN" \
  "https://cloud-api.yandex.net/v1/disk/resources?path=%2F&limit=100"
```

В WorkOrder: `refreshContents()` → `GET .../resources?path=app:/workOrder&limit=1000`.

---

## Создание папки

Документация: [Создание папки](https://yandex.ru/dev/disk-api/doc/ru/reference/create-folder).

```http
PUT https://cloud-api.yandex.net/v1/disk/resources?path=<path>
Authorization: OAuth <token>
```

| Код | Значение |
|-----|----------|
| `201 Created` | папка создана; в теле — `Link` на метаданные |
| `409 Conflict` | ресурс по пути уже существует |
| `404` | не найден родительский путь |

Пример ответа `201`:

```json
{
  "href": "https://cloud-api.yandex.net/v1/disk/resources?path=disk%3A%2FMusic",
  "method": "GET",
  "templated": false
}
```

В WorkOrder: `ensureWorkOrderDirectory()`:

1. `GET .../resources?path=app:/workOrder`
2. если `200` и `type=dir` — готово;
3. если `404` — `PUT` того же URL;
4. успех при `201` или `409`.

---

## Плоский список всех файлов

Документация: [Плоский список](https://yandex.ru/dev/disk-api/doc/ru/reference/all-files).

```http
GET https://cloud-api.yandex.net/v1/disk/resources/files?limit=20&offset=0&media_type=document
Authorization: OAuth <token>
```

Не учитывает дерево папок — удобно искать файлы по `media_type` (`document`, `image`, `spreadsheet`, …).

---

## Загрузка файла

Документация: [Загрузка файла](https://yandex.ru/dev/disk-api/doc/ru/reference/upload).

### 1. Получить URL загрузки

```http
GET https://cloud-api.yandex.net/v1/disk/resources/upload?path=<path>&overwrite=false
Authorization: OAuth <token>
```

| Параметр | Описание |
|----------|----------|
| `path` | куда положить файл, напр. `app:/workOrder/report.pdf` |
| `overwrite` | `false` (по умолчанию) / `true` |

Ответ `200`:

```json
{
  "href": "https://uploader....yandex.net/upload-target/...",
  "method": "PUT",
  "operation_id": "...",
  "templated": false
}
```

Ссылка живёт **~30 минут**.

Частые ошибки: `409` (уже есть), `413` (слишком большой), `507` (нет места), `423` (лимит/техработы).

### 2. Отправить файл

```http
PUT <href из ответа>
Content-Type: application/octet-stream

<бинарное тело файла>
```

OAuth на этом шаге **не нужен**.

| Код | Значение |
|-----|----------|
| `201 Created` | загружено |
| `202 Accepted` | принято, ещё переносится на Диск |

Пример:

```bash
# 1) URL
UPLOAD=$(curl -s -H "Authorization: OAuth $TOKEN" \
  "https://cloud-api.yandex.net/v1/disk/resources/upload?path=disk%3A%2FworkOrder%2Ffile.pdf&overwrite=true")
HREF=$(echo "$UPLOAD" | jq -r .href)

# 2) файл
curl -X PUT --data-binary @file.pdf "$HREF"
```

---

## Скачивание файла

Документация: [Скачивание](https://yandex.ru/dev/disk-api/doc/ru/reference/content).

### 1. Получить URL скачивания

```http
GET https://cloud-api.yandex.net/v1/disk/resources/download?path=<path>
Authorization: OAuth <token>
```

Ответ `200`:

```json
{
  "href": "https://downloader....yandex.ru/disk/...",
  "method": "GET",
  "templated": false
}
```

### 2. Скачать по `href`

```http
GET <href>
Authorization: OAuth <token>
```

Ответ: `200` с телом файла или `302` на `*.storage.yandex.net` — HTTP-клиент должен **следовать редиректам**.

---

## Удаление

Документация: [Удаление](https://yandex.ru/dev/disk-api/doc/ru/reference/delete).

```http
DELETE https://cloud-api.yandex.net/v1/disk/resources?path=<path>&permanently=false
Authorization: OAuth <token>
```

| Параметр | Описание |
|----------|----------|
| `permanently=false` | в Корзину (по умолчанию; место на Диске не освобождается) |
| `permanently=true` | безвозвратно |
| `md5` | доп. проверка для файла |

| Код | Значение |
|-----|----------|
| `204` | файл / пустая папка удалены |
| `202` | начато удаление непустой папки (асинхронно; в теле — ссылка на операцию) |

---

## Типичные коды ошибок

| HTTP | Смысл |
|------|--------|
| `400` | некорректные данные |
| `401` | нет / неверный токен |
| `403` | нет прав / переполнение Диска |
| `404` | ресурс не найден |
| `406` | неверный формат (не JSON) |
| `409` | конфликт (уже существует) |
| `413` | файл слишком большой |
| `423` | только просмотр/скачивание (лимит или техработы) |
| `429` | слишком много запросов |
| `503` | сервис недоступен |
| `507` | недостаточно места |

---

## Карта эндпоинтов (кратко)

| Действие | Метод | Путь |
|----------|-------|------|
| Инфо о Диске | `GET` | `/v1/disk` |
| Мета / список папки | `GET` | `/v1/disk/resources` |
| Создать папку | `PUT` | `/v1/disk/resources` |
| Удалить | `DELETE` | `/v1/disk/resources` |
| URL загрузки | `GET` | `/v1/disk/resources/upload` |
| URL скачивания | `GET` | `/v1/disk/resources/download` |
| Плоский список файлов | `GET` | `/v1/disk/resources/files` |
| Корзина (мета) | `GET` | `/v1/disk/trash/resources` |
| Статус операции | `GET` | `/v1/disk/operations?id=...` |

Полный справочник: [yandex.ru/dev/disk-api](https://yandex.ru/dev/disk-api/doc/ru/).

---

## Связь с WorkOrder

| Функция приложения | API |
|--------------------|-----|
| Подключение (токен) | OAuth `response_type=token` |
| Список каталога приложения | `GET /v1/disk/resources?path=app:/workOrder&limit=1000` |
| Каталог приложения | `app:/workOrder` через GET + PUT |
| Force upload баз | очистка папки (`DELETE`) + upload каждого `*.db` |
| Download баз | download каждого `*.db` из `app:/workOrder` на устройство |
| Синхронизация | заглушка `syncDatabases()` |
| Код | `CloudDiskBackend` (C++ / Python), см. [cloud-disk.md](cloud-disk.md) |

Планируемые операции (ещё не в UI): upload/download отчётов в `app:/workOrder/` по схемам выше.
