#!/usr/bin/env python3
"""
Reports backend: customers, objects and work reports.
"""

from datetime import date

from PyQt6.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot

from utils.db_storage import (
    add_client_entry,
    create_client_table,
    default_works_db_path,
    load_clients,
    load_completed_works,
    save_clients,
    save_completed_works,
)
from utils.report_builder import save_work_report


class ReportBackend(QObject):
    """Backend for customers/objects and work reports."""

    clientsChanged = pyqtSignal()
    worksChanged = pyqtSignal()
    clientSelected = pyqtSignal(int, str, str)
    reportGenerated = pyqtSignal(str, str)
    errorOccurred = pyqtSignal(str)

    def __init__(self, settings_backend, parent=None):
        super().__init__(parent)
        self._settings_backend = settings_backend
        # self._clients_db_path = ""
        self._works_db_path = str(default_works_db_path())
        self._clients = []
        self._works = []
        self._selected_client_id = 0
        self._next_client_id = 1
        self._next_work_id = 1
        self._last_report_path = ""
        self._last_report_text = ""
        create_client_table()

    @pyqtProperty(int, notify=clientsChanged)
    def clientCount(self):
        return len(self._clients)

    @pyqtProperty(int, notify=clientSelected)
    def selectedClientId(self):
        return self._selected_client_id

    @pyqtProperty(str, notify=reportGenerated)
    def lastReportPath(self):
        return self._last_report_path

    @pyqtProperty(str, notify=reportGenerated)
    def lastReportText(self):
        return self._last_report_text

    @pyqtSlot(result=bool)
    def initializeData(self):
        """Create demo databases if they are missing."""
        try:
            self._load_clients()
            return True
        except Exception as exc:
            self.errorOccurred.emit(f"Ошибка инициализации данных: {str(exc)}")
            return False

    @pyqtSlot("QVariantMap", result=bool)
    def addClient(self, data):
        """Add customer or object."""
        if not data:
            return False
        result = add_client_entry(data)
        self._load_clients()
        return result

    @pyqtSlot(int)
    def selectClient(self, client_id):
        for client in self._clients:
            if client["id"] == client_id:
                self._selected_client_id = client_id
                self.clientSelected.emit(client_id, client["name"], client["kind"])
                return
        self._selected_client_id = 0
        self.clientSelected.emit(0, "", "")

    @pyqtSlot(int, str, float, int, str, result=bool)
    def addWorkForClient(self, client_id, service_name, unit_price, quantity, notes):
        """Add completed work entry for selected client."""
        client = self._find_client(client_id)
        if not client:
            self.errorOccurred.emit("Заказчик или объект не найден")
            return False
        if not service_name or not service_name.strip():
            self.errorOccurred.emit("Укажите название работы")
            return False
        if unit_price < 0:
            self.errorOccurred.emit("Цена не может быть отрицательной")
            return False
        if quantity < 1:
            quantity = 1

        work_id = self._next_work_id
        self._next_work_id += 1
        total_price = round(float(unit_price) * int(quantity), 2)
        work = {
            "id": work_id,
            "work_number": f"WO-{work_id:04d}",
            "service_id": 0,
            "service_name": service_name.strip(),
            "quantity": int(quantity),
            "unit_price": float(unit_price),
            "total_price": total_price,
            "client_id": client_id,
            "client_name": client["name"],
            "completed_at": date.today().isoformat(),
            "status": "completed",
            "notes": notes.strip(),
        }
        self._works.append(work)
        self._persist_works()
        self.worksChanged.emit()
        print(f"[Report] Added work for {client['name']}: {work['service_name']}")
        return True

    @pyqtSlot(int, result=bool)
    def generateReport(self, client_id):
        """Generate text report for client works."""
        client = self._find_client(client_id)
        if not client:
            self.errorOccurred.emit("Выберите заказчика или объект")
            return False

        works = self.getClientWorks(client_id)
        personal_info = self._settings_backend.personalInfo
        try:
            report_path, report_text = save_work_report(personal_info, client, works)
            self._last_report_path = report_path
            self._last_report_text = report_text
            self.reportGenerated.emit(report_path, report_text)
            print(f"[Report] Generated report: {report_path}")
            return True
        except Exception as exc:
            self.errorOccurred.emit(f"Ошибка формирования отчёта: {str(exc)}")
            return False

    @pyqtSlot(result=list)
    def getAllClients(self):
        return [client.copy() for client in self._clients]

    @pyqtSlot(int, result=list)
    def getClientWorks(self, client_id):
        if client_id <= 0:
            return []
        client = self._find_client(client_id)
        if not client:
            return []

        results = []
        for work in self._works:
            if work.get("client_id") == client_id:
                results.append(work.copy())
                continue
            if not work.get("client_id") and work.get("client_name") == client["name"]:
                results.append(work.copy())
        return results

    def _find_client(self, client_id):
        for client in self._clients:
            if client["id"] == client_id:
                return client
        return None

    def _load_clients(self):
        self._clients = load_clients()
        if not self._clients:
            create_client_table()
            self._clients = load_clients()

        self.clientsChanged.emit()

    def _reload_works(self):
        self._works = load_completed_works(self._works_db_path)
        if self._works:
            self._next_work_id = max(item["id"] for item in self._works) + 1
        else:
            self._next_work_id = 1
        self.worksChanged.emit()

    # def _persist_clients(self):
    # save_clients(self._clients_db_path, self._clients)

    def _persist_works(self):
        save_completed_works(self._works_db_path, self._works)
