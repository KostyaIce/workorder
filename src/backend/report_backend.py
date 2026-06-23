#!/usr/bin/env python3
"""
Reports backend: customers, objects and work reports.
"""


from PyQt6.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot
from models.clients_model import ClientModel
from models.objects_model import ObjectModel
from models.works_model import WorksModel

from utils.works_db import (
    load_works,
    load_works_by_object,
    add_work,
    delete_work,
    update_work,
    create_works_table
)
from utils.clients_db import (
    create_client_table,
    add_client_entry,
    load_clients,
)
from utils.objects_db import (
    create_object_database,
    add_object_entry,
    load_objects,
    update_object_last_order_at
)
from utils.report_builder import save_work_report

from dataclasses import dataclass

@dataclass
class ClientItem:
    id: str = ""
    name: str = ""

@dataclass
class ObjectItem:
    id: str = ""
    name: str = ""
    address: str = ""
    last_order_at: int = 0

@dataclass
class ServiceItem:
    id: str = ""
    name: str = ""
    unit: str = ""
    price: int = 0
    sub_object: str = ""

class ReportBackend(QObject):
    """Backend for customers/objects and work reports."""

    clientsChanged = pyqtSignal()
    worksChanged = pyqtSignal()
    clientSelected = pyqtSignal()
    objectSelected = pyqtSignal()
    objectUpdated = pyqtSignal()
    serviceSelected = pyqtSignal()
    subObjectChanged = pyqtSignal(str)
    quantityChanged = pyqtSignal(float)
    reportGenerated = pyqtSignal(str, str)
    errorOccurred = pyqtSignal(str)

    def __init__(self, settings_backend, engine,  parent=None):
        super().__init__(parent)
        self._settings_backend = settings_backend
        self._next_client_id = 1
        self._next_work_id = 1
        self._last_report_path = ""
        self._last_report_text = ""
        self._current_client_data = ClientItem()
        self._current_object_data = ObjectItem()
        self._current_service_data = ServiceItem()
        self._quantity = 1.0
        self._clients = ClientModel()
        self._objects = ObjectModel()
        self._works = WorksModel()
        
        engine.rootContext().setContextProperty(
            "clientsModel",
            self._clients
        )
        engine.rootContext().setContextProperty(
            "objectsModel",
            self._objects
        )
        engine.rootContext().setContextProperty(
            "worksModel",
            self._works
        )
        create_client_table()

    @pyqtProperty(int, notify=clientsChanged)
    def clientCount(self):
        return self._clients.rowCount()

    @pyqtProperty(int, notify=worksChanged)
    def workCount(self):
        return self._works.count

    @pyqtProperty(float, notify=worksChanged)
    def worksTotal(self):
        total = 0.0
        for item in self._works.items():
            total += float(item.get("price", 0)) * float(item.get("quantity", 0))
        return total

    @pyqtProperty(str, notify=clientSelected)
    def selectedClientId(self):
        return self._current_client_data.id

    @pyqtProperty(str, notify=clientSelected)
    def selectedClientName(self):
        if self._current_client_data.name:
            return self._current_client_data.name
        return ""

    @pyqtProperty(str, notify=objectSelected)
    def selectedObjectName(self):
        if self._current_object_data.name:
            return self._current_object_data.name
        return ""

    @pyqtProperty(int, notify=objectUpdated)
    def selectedObjectLastOrder(self):
        if self._current_object_data.last_order_at:
            return self._current_object_data.last_order_at
        return 0

    @pyqtProperty(str, notify=serviceSelected)
    def currentServiceName(self):
        """Selected service name for invoice line."""
        return self._current_service_data.name

    @pyqtProperty(int, notify=serviceSelected)
    def currentPrice(self):
        """Selected service price for invoice line."""
        return self._current_service_data.price

    @pyqtProperty(str, notify=subObjectChanged)
    def currentSubObject(self):
        """Sub-object name for current invoice line."""
        return self._current_service_data.sub_object

    @pyqtProperty(float, notify=quantityChanged)
    def currentQuantity(self):
        """Quantity for new work line."""
        return self._quantity

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

    @pyqtSlot(str)
    def selectClient(self, client_id):
        item = self._clients.itemData(client_id)
        if item:
            self._current_client_data = ClientItem(item["id"], item["name"])
        create_works_table(self._current_client_data.name, self._current_client_data.id)
        create_object_database(self._current_client_data.name, self._current_client_data.id)
        self._load_objects()
        self._works.clearModel()
        # self._reload_works(self._current_client_data.name, self._current_client_data.id)
        self.clientSelected.emit()

    @pyqtSlot()
    def updateLastTimeObject(self):
        if self._current_object_data.name == "":
            return
        update_object_last_order_at(self._current_client_data.name, self._current_client_data.id, self._current_object_data.id)
        self._load_objects()
        self._update_current_object_data()

    @pyqtSlot(str)
    def selectObject(self, object_id):
        item = self._objects.itemData(object_id)
        if item:
            self._current_object_data = ObjectItem(item["id"], item["name"], item["address"], item["last_order_at"])
        self._reload_works(
            self._current_client_data.name,
            self._current_client_data.id,
            self._current_object_data.id
        )
        self.objectSelected.emit()
        self.objectUpdated.emit()

    @pyqtSlot()
    def clearWorks(self):
        self._works.clearModel()
        self.worksChanged.emit()

    @pyqtSlot(str, str, str, int)
    def selectService(self, service_id, name, unit, price):
        """Select service for invoice line."""
        if service_id == "" or name == "" or price == "":
            return

        self._current_service_data = ServiceItem(service_id, name, unit, price)
        self.serviceSelected.emit()
        self.subObjectChanged.emit("")

    @pyqtSlot(int)
    def setCurrentServicePrice(self, price):
        self._current_service_data.price = price
        self.serviceSelected.emit()

    @pyqtSlot(str)
    def setCurrentSubObject(self, sub_object):
        """Set sub-object name for current line (e.g. room or area)."""
        value = sub_object.strip() if sub_object else ""
        if self._current_service_data.sub_object == value:
            return
        self._current_service_data.sub_object = value
        self.subObjectChanged.emit(value)

    @pyqtSlot()
    def clearCurrentService(self):
        """Reset selected service, sub-object and quantity."""
        self._current_service_data = ServiceItem()
        self._quantity = 1.0
        self.serviceSelected.emit()
        self.subObjectChanged.emit("")
        self.quantityChanged.emit(self._quantity)

    @pyqtSlot(float)
    def setQuantity(self, quantity):
        """Set quantity for work line being added."""
        if quantity < 0.1:
            quantity = 0.1
        if quantity > 999:
            quantity = 999

        self._quantity = float(quantity)
        self.quantityChanged.emit(self._quantity)

    @pyqtSlot()
    def incrementQuantity(self):
        self.setQuantity(self._quantity + 1)

    @pyqtSlot()
    def decrementQuantity(self):
        self.setQuantity(self._quantity - 1)

    @pyqtSlot(result=bool)
    def addWork(self):
        if not self._current_service_data.id:
            return False
        if self._current_client_data.id == "":
            self.errorOccurred.emit("Выберите заказчика")
            return False
        if self._current_object_data.id == "":
            self.errorOccurred.emit("Выберите объект")
            return False

        data = {
            "object_id": self._current_object_data.id,
            "service_id": self._current_service_data.id,
            "subobject_name": self._current_service_data.sub_object,
            "name": self._current_service_data.name,
            "price": self._current_service_data.price,
            "unit": self._current_service_data.unit,
            "quantity": self._quantity,
            "start_order_at": self._current_object_data.last_order_at
        }

        result = add_work(self._current_client_data.name, self._current_client_data.id, data)
        if not result:
            self.errorOccurred.emit("Не удалось добавить работу")
            return False

        self._works.addItem(result)
        self.worksChanged.emit()
        self.clearCurrentService()
        return True

    @pyqtSlot("QVariantMap", result=bool)
    def updateWork(self, data):
        if not data or self._current_client_data.id == "":
            return False

        work_id = data.get("id")
        if not work_id:
            return False

        if not update_work(self._current_client_data.name, self._current_client_data.id, data):
            self.errorOccurred.emit("Не удалось обновить работу")
            return False

        self._works.updateItem(data)
        self.worksChanged.emit()
        return True

    @pyqtSlot(str, result=bool)
    def deleteWork(self, work_id):
        if not work_id or self._current_client_data.id == "":
            return False

        if not delete_work(self._current_client_data.name, self._current_client_data.id, work_id):
            self.errorOccurred.emit("Не удалось удалить работу")
            return False

        self._works.removeItem(work_id)
        self.worksChanged.emit()
        return True

    def _update_current_object_data(self):
        if self._current_object_data.name == "":
            return
        item = self._objects.itemData(self._current_object_data.id)
        if item:
            self._current_object_data = ObjectItem(item["id"], item["name"], item["address"], item["last_order_at"])
        self.objectUpdated.emit()

    @pyqtSlot("QVariantMap", result=bool)
    def addObject(self, data):
        """Add customer or object."""
        if not data:
            return False
        if self._current_client_data.id == "":
            return False
        result = False
        create_object_database(self._current_client_data.name, self._current_client_data.id)
        result = add_object_entry(self._current_client_data.name, self._current_client_data.id, data["name"], data["address"])
        self._load_objects()
        return result

    # @pyqtSlot(int, str, float, int, str, result=bool)
    # def addWorkForClient(self, client_id, service_name, unit_price, quantity, notes):
    #     """Add completed work entry for selected client."""
    #     client = self._find_client(client_id)
    #     if not client:
    #         self.errorOccurred.emit("Заказчик или объект не найден")
    #         return False
    #     if not service_name or not service_name.strip():
    #         self.errorOccurred.emit("Укажите название работы")
    #         return False
    #     if unit_price < 0:
    #         self.errorOccurred.emit("Цена не может быть отрицательной")
    #         return False
    #     if quantity < 1:
    #         quantity = 1
    #
    #     work_id = self._next_work_id
    #     self._next_work_id += 1
    #     total_price = round(float(unit_price) * int(quantity), 2)
    #     work = {
    #         "id": work_id,
    #         "work_number": f"WO-{work_id:04d}",
    #         "service_id": 0,
    #         "service_name": service_name.strip(),
    #         "quantity": int(quantity),
    #         "unit_price": float(unit_price),
    #         "total_price": total_price,
    #         "client_id": client_id,
    #         "client_name": client["name"],
    #         "completed_at": date.today().isoformat(),
    #         "status": "completed",
    #         "notes": notes.strip(),
    #     }
    #     self._works.append(work)
    #     if self._current_client_data.id:
    #         self._persist_work({
    #             "object_id": self._current_object_data.id,
    #             "service_id": "",
    #             "subobject_name": notes.strip(),
    #             "name": service_name.strip(),
    #             "price": int(unit_price),
    #             "unit": "",
    #         })
    #         self._reload_works(self._current_client_data.name, self._current_client_data.id)
    #     self.worksChanged.emit()
    #     print(f"[Report] Added work for {client['name']}: {work['service_name']}")
    #     return True

    @pyqtSlot(str, result=bool)
    def generateReport(self, client_id):
        """Generate text report for client works."""
        works = self.getClientWorks()
        client = self._clients.itemData(client_id)
        if not client:
            self.errorOccurred.emit("Выберите заказчика или объект")
            return False

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
    def getClientWorks(self):
        if self._current_client_data.id == "":
            return []
        return self._works.items()

    def _load_clients(self):
        clients_data = load_clients()
        if not clients_data:
            create_client_table()
            clients_data = load_clients()
        self._clients.updateModel(clients_data)

    def _load_objects(self):
        objects_data = load_objects(self._current_client_data.name, self._current_client_data.id)
        if not objects_data:
            create_object_database(self._current_client_data.name, self._current_client_data.id)
            objects_data = load_objects(self._current_client_data.name, self._current_client_data.id)
        self._objects.updateModel(objects_data)

    def _reload_works(self, client_name, client_id, object_id=""):
        if object_id:
            works_data = load_works_by_object(client_name, client_id, object_id)
        else:
            works_data = load_works(client_name, client_id)
        self._works.updateModel(works_data)
        self.worksChanged.emit()

    def _persist_work(self, data):
        if self._current_client_data.id == "":
            return False
        return add_work(self._current_client_data.name, self._current_client_data.id, data)
