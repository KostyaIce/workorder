#!/usr/bin/env python3
"""
Reports backend: customers, objects and work reports.
"""


from PyQt6.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot
from models.clients_model import ClientModel
from models.objects_model import ObjectModel
from models.orders_model import OrdersModel
from models.works_model import WorksModel
from models.subobjects_model import SubobjectsModel
from models.subobjects_filter_model import SubobjectsFilterModel

from utils.works_db import (
    load_works,
    load_works_by_object,
    add_work,
    delete_work,
    update_work,
    create_works_table,
    get_orders,
    load_subobject_names,
    load_works_by_select_at,
    load_works_by_start_order
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
from utils.report_builder import build_work_report, save_work_report
from utils.qsettings_store import QSettingsStore

from dataclasses import dataclass

_SETTINGS_KEY_CLIENT_ID = "report/current_client_id"
_SETTINGS_KEY_OBJECT_ID = "report/current_object_id"

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
    orderSelected = pyqtSignal()
    serviceSelected = pyqtSignal()
    subObjectChanged = pyqtSignal(str)
    reportGenerated = pyqtSignal(str, str)
    errorOccurred = pyqtSignal(str)

    def __init__(self, settings_backend, report_options_backend, engine, parent=None):
        super().__init__(parent)
        self._settings_backend = settings_backend
        self._report_options_backend = report_options_backend
        self._next_client_id = 1
        self._next_work_id = 1
        self._last_report_path = ""
        self._last_report_text = ""
        self._current_client_data = ClientItem()
        self._current_object_data = ObjectItem()
        self._current_service_data = ServiceItem()
        self._selected_start_order_at = 0
        self._selected_order_total_price = 0
        # self._quantity = 1.0
        self._clients = ClientModel()
        self._objects = ObjectModel()
        self._orders = OrdersModel()
        self._works = WorksModel()
        self._work_report = WorksModel()
        self._subobjects = SubobjectsModel()
        self._subobjects_filter = SubobjectsFilterModel()
        self._subobjects_filter.setSourceModel(self._subobjects)
        
        engine.rootContext().setContextProperty(
            "clientsModel",
            self._clients
        )
        engine.rootContext().setContextProperty(
            "objectsModel",
            self._objects
        )
        engine.rootContext().setContextProperty(
            "ordersModel",
            self._orders
        )
        engine.rootContext().setContextProperty(
            "worksModel",
            self._works
        )

        engine.rootContext().setContextProperty(
            "workReportModel",
            self._work_report
        )
        engine.rootContext().setContextProperty(
            "subobjectsModel",
            self._subobjects
        )
        engine.rootContext().setContextProperty(
            "subobjectsFilterModel",
            self._subobjects_filter
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

    @pyqtProperty(int, notify=orderSelected)
    def selectedStartOrderAt(self):
        return self._selected_start_order_at

    @pyqtProperty(int, notify=orderSelected)
    def selectedOrderTotalPrice(self):
        return self._selected_order_total_price

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
            self._restore_selection()
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
        if not self._set_current_client(client_id):
            return

        self._save_selected_client_id(client_id)
        self._save_selected_object_id("")
        self.clientSelected.emit()
        self.objectSelected.emit()
        self.objectUpdated.emit()

    @pyqtSlot()
    def updateLastTimeObject(self):
        if self._current_object_data.name == "":
            return
        update_object_last_order_at(self._current_client_data.name, self._current_client_data.id, self._current_object_data.id)
        self._load_objects()
        self._update_current_object_data()

    @pyqtSlot(str)
    def selectObject(self, object_id):
        if not self._set_current_object(object_id):
            return

        self._save_selected_object_id(object_id)
        self.refreshSubobject(self._current_object_data.id)
        self.objectSelected.emit()
        self.objectUpdated.emit()

    @pyqtSlot(int)
    def selectOrder(self, start_order_at):
        """Select invoice period by start_order_at timestamp."""
        value = int(start_order_at)
        if self._selected_start_order_at == value:
            return
        self._selected_start_order_at = value
        order = self._orders.itemData(value)
        self._selected_order_total_price = int(order.get("total_price", 0)) if order else 0
        self.orderSelected.emit()
        items = load_works_by_select_at(self._current_client_data.name, self._current_client_data.id, self._current_object_data.id ,self._selected_start_order_at)
        self._work_report.updateModel(items)


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

    @pyqtSlot(str)
    def searchSubObjects(self, query):
        """Filter subobject suggestions by entered text."""
        self._subobjects_filter.setFilterText(query.strip() if query else "")

    @pyqtSlot()
    def clearSubObjectSuggestions(self):
        """Hide subobject suggestions."""
        self._subobjects_filter.clearFilter()

    @pyqtSlot()
    def clearCurrentService(self):
        """Reset selected service, sub-object and quantity."""
        self._current_service_data = ServiceItem()
        self._subobjects_filter.clearFilter()
        self.serviceSelected.emit()
        self.subObjectChanged.emit("")


    @pyqtSlot(float, result=bool)
    def addWork(self, quantity):
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
            "quantity": quantity,
            "start_order_at": self._current_object_data.last_order_at
        }

        result = add_work(self._current_client_data.name, self._current_client_data.id, data)
        if not result:
            self.errorOccurred.emit("Не удалось добавить работу")
            return False

        self._works.addItem(result)
        self._subobjects.addItem(self._current_service_data.sub_object)
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

        subobject_name = data.get("subobject_name", "")
        if subobject_name:
            self._subobjects.addItem(subobject_name)

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


    @pyqtSlot(str, result=bool)
    def generateReport(self, client_id):
        """Generate text report for selected orders and save to file."""
        return self._generate_report(client_id, save_to_file=True)

    @pyqtSlot(str, result=bool)
    def previewReport(self, client_id):
        """Build report preview without saving to file."""
        return self._generate_report(client_id, save_to_file=False)

    def _generate_report(self, client_id, save_to_file):
        client = self._clients.itemData(client_id)
        if not client:
            self.errorOccurred.emit("Выберите заказчика или объект")
            return False

        if self._current_object_data.id == "":
            self.errorOccurred.emit("Выберите объект заказчика")
            return False

        selected_orders = self._report_options_backend.selectedOrderTimestamps()
        if not selected_orders:
            self.errorOccurred.emit("Выберите хотя бы один счёт")
            return False

        works = []
        for start_order_at in selected_orders:
            items = load_works_by_select_at(
                self._current_client_data.name,
                self._current_client_data.id,
                self._current_object_data.id,
                start_order_at,
            )
            works.extend(items)

        if not works:
            self.errorOccurred.emit("Нет работ для выбранных счетов")
            return False

        personal_info = self._settings_backend.personalInfo
        object_data = {
            "name": self._current_object_data.name,
            "address": self._current_object_data.address,
        }
        options = self._report_options_backend.as_dict()

        try:
            if save_to_file:
                report_path, report_text = save_work_report(
                    personal_info,
                    client,
                    object_data,
                    works,
                    options,
                )
            else:
                report_path = ""
                report_text = build_work_report(
                    personal_info,
                    client,
                    object_data,
                    works,
                    options,
                )

            self._last_report_path = report_path
            self._last_report_text = report_text
            self.reportGenerated.emit(report_path, report_text)
            if save_to_file:
                print(f"[Report] Generated report: {report_path}")
            return True
        except Exception as exc:
            self.errorOccurred.emit(f"Ошибка формирования отчёта: {str(exc)}")
            return False

    @pyqtSlot(result=list)
    def getOrderStartTimes(self):
        """Return start_order_at values for current object orders."""
        return [
            item["start_order_at"]
            for item in self._orders_items()
            if item.get("start_order_at")
        ]

    def _orders_items(self):
        items = []
        for row in range(self._orders.rowCount()):
            index = self._orders.index(row, 0)
            start_order_at = self._orders.data(index, self._orders.StartOrderAtRole)
            total_price = self._orders.data(index, self._orders.TotalPriceRole)
            items.append(
                {
                    "start_order_at": start_order_at,
                    "total_price": total_price,
                }
            )
        return items

    @pyqtSlot(result=list)
    def getClientWorks(self):
        if self._current_client_data.id == "":
            return []
        return self._works.items()

    @pyqtSlot()
    def refreshOrders(self):
        """Reload orders list for current client object."""
        self._load_orders()

    @pyqtSlot(str)
    def refreshSubobject(self, object_id):
        self._load_subobjects(object_id)

    def _load_subobjects(self, object_id):
        if self._current_client_data.id == "" or self._current_object_data.id == "":
            self._subobjects.updateModel([])
            self._subobjects_filter.clearFilter()
            return

        names = load_subobject_names(
            self._current_client_data.name,
            self._current_client_data.id,
            object_id,
        )
        self._subobjects.updateModel(names)

    def _load_clients(self):
        clients_data = load_clients()
        if not clients_data:
            create_client_table()
            clients_data = load_clients()
        self._clients.updateModel(clients_data)
        self.clientsChanged.emit()

    def _set_current_client(self, client_id):
        if not client_id:
            return False

        item = self._clients.itemData(client_id)
        if not item:
            return False

        self._current_client_data = ClientItem(item["id"], item["name"])
        create_works_table(self._current_client_data.name, self._current_client_data.id)
        create_object_database(self._current_client_data.name, self._current_client_data.id)
        self._load_objects()
        self._works.clearModel()
        self._current_object_data = ObjectItem()
        # self._load_orders()
        return True

    def _set_current_object(self, object_id):
        if not object_id:
            return False

        item = self._objects.itemData(object_id)
        if not item:
            return False

        self._current_object_data = ObjectItem(
            item["id"],
            item["name"],
            item["address"],
            item["last_order_at"],
        )
        self._reload_works()
        # self._load_orders()
        return True

    def _save_selected_client_id(self, client_id):
        with QSettingsStore() as store:
            store.write(_SETTINGS_KEY_CLIENT_ID, client_id or "")

    def _save_selected_object_id(self, object_id):
        with QSettingsStore() as store:
            store.write(_SETTINGS_KEY_OBJECT_ID, object_id or "")

    def _clear_persisted_selection(self):
        with QSettingsStore() as store:
            store.write(_SETTINGS_KEY_CLIENT_ID, "")
            store.write(_SETTINGS_KEY_OBJECT_ID, "")

    def _restore_selection(self):
        with QSettingsStore() as store:
            client_id = store.read(_SETTINGS_KEY_CLIENT_ID, "", value_type=str) or ""
            object_id = store.read(_SETTINGS_KEY_OBJECT_ID, "", value_type=str) or ""

        if not client_id:
            return

        if not self._set_current_client(client_id):
            self._clear_persisted_selection()
            return

        self.clientSelected.emit()

        if not object_id:
            return

        if not self._set_current_object(object_id):
            self._save_selected_object_id("")
            return

        self.refreshSubobject(object_id)
        self.objectSelected.emit()
        self.objectUpdated.emit()

    def _load_objects(self):
        objects_data = load_objects(self._current_client_data.name, self._current_client_data.id)
        if not objects_data:
            create_object_database(self._current_client_data.name, self._current_client_data.id)
            objects_data = load_objects(self._current_client_data.name, self._current_client_data.id)
        self._objects.updateModel(objects_data)

    def _load_orders(self):
        self._clear_selected_order()

        if self._current_client_data.id == "" or self._current_object_data.id == "":
            self._orders.updateModel([])
            return

        orders_data = get_orders(
            self._current_client_data.name,
            self._current_client_data.id,
            self._current_object_data.id,
        )
        self._orders.updateModel(orders_data)

    def _clear_selected_order(self):
        if self._selected_start_order_at == 0:
            return
        self._selected_start_order_at = 0
        self._selected_order_total_price = 0
        self.orderSelected.emit()

    def _reload_works(self):
        works_data = load_works_by_start_order(self._current_client_data.name, self._current_client_data.id,
                                               self._current_object_data.id, self._current_object_data.last_order_at)
        self._works.updateModel(works_data)
        self.worksChanged.emit()

    def _persist_work(self, data):
        if self._current_client_data.id == "":
            return False
        return add_work(self._current_client_data.name, self._current_client_data.id, data)
