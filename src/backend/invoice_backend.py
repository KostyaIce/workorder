#!/usr/bin/env python3
"""
InvoicePage Backend
Бэкенд для окна создания счета с автодополнением
"""

import logging

from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot

from models.services_model import ServiceModel
from models.services_filter_model import ServicesFilterModel
from models.coefficients_filter_model import CoefficientsFilterModel
from utils.services_db import create_services_table, add_service, update_service, load_services, delete_service
from utils.services_excel_builder import export_services_excel, import_services_from_excel
from utils.services_pdf_builder import export_services_pdf

logger = logging.getLogger("workorder")

def _keywords_from_name(name):
    words = [word.lower() for word in name.split() if len(word) > 2]
    return words or [name.lower()]


class InvoiceBackend(QObject):
    """Backend для страницы создания счета"""
    
    # Сигналы
    countFound = pyqtSignal(int)
    coefficientsCountFound = pyqtSignal(int)
    suggestionsUpdated = pyqtSignal(list)  # Список подсказок
    suggestionsCleared = pyqtSignal()
    invoiceCreated = pyqtSignal(int, str)  # invoice_id, invoice_number
    
    def __init__(self, engine, parent=None):
        super().__init__(parent)
        
        # Текущие значения для добавления позиции
        self._report_backend = None
        self._invoice_counter = 0

        # Models for services
        self._services = ServiceModel()
        self._services_filter = ServicesFilterModel()
        self._services_filter.setSourceModel(self._services)
        self._coefficients_filter = CoefficientsFilterModel()
        self._coefficients_filter.setSourceModel(self._services)

        create_services_table()
        self._load_services()

        engine.rootContext().setContextProperty(
            "servicesModel",
            self._services
        )
        engine.rootContext().setContextProperty(
            "servicesFilterModel",
            self._services_filter
        )
        engine.rootContext().setContextProperty(
            "coefficientsFilterModel",
            self._coefficients_filter
        )
    
    def _load_services(self):

        model = load_services()
        self._services.updateModel(model)

    # === Каталог услуг ===
    
    @pyqtSlot("QVariantMap", result=bool)
    def addService(self, data):
        if not data:
            return False
        try:
            if not add_service(data):
                logger.warning("Failed to add service: %s", data.get("name"))
                return False
            self._load_services()
            return True
        except Exception:
            logger.exception("Failed to add service: %s", data.get("name"))
            return False

    @pyqtSlot("QVariantMap", result=bool)
    def updateService(self, data):
        if not data:
            return False
        try:
            if not update_service(data):
                logger.warning("Failed to update service: %s", data.get("id"))
                return False
            self._load_services()
            return True
        except Exception:
            logger.exception("Failed to update service: %s", data.get("id"))
            return False

    @pyqtSlot(str, result=bool)
    def deleteService(self, service_id):
        if not service_id:
            return False
        try:
            if not delete_service(service_id):
                logger.warning("Failed to delete service: %s", service_id)
                return False
            self._load_services()
            return True
        except Exception:
            logger.exception("Failed to delete service: %s", service_id)
            return False

    @pyqtSlot(str, result=bool)
    def importServicesFromFile(self, file_url):
        """Import services from Excel file into services database."""
        # try:
        if True:
            services = import_services_from_excel(file_url)
            if not services:
                logger.warning("Services import: no services found in %s", file_url)
                return False

            saved_count = 0
            for item in services:
                if add_service(item):
                    saved_count += 1
                else:
                    logger.warning("Services import skipped: %s", item.get("name"))

            self._load_services()
            logger.info(
                "Services import finished: saved %s of %s from %s",
                saved_count,
                len(services),
                file_url,
            )
            return saved_count > 0
        # except Exception:
        #     logger.exception("Failed to import services from %s", file_url)
        #     return False

    @pyqtSlot(str, result=bool)
    def exportServicesToFile(self, file_url):
        """Export services catalog from database to Excel."""
        try:
            path = export_services_excel(file_url, load_services())
            logger.info("Services exported to %s", path)
            return True
        except Exception:
            logger.exception("Failed to export services to %s", file_url)
            return False

    @pyqtSlot(str, result=bool)
    def exportServicesPresentationToFile(self, file_url):
        """Export services catalog presentation to PDF."""
        try:
            path = export_services_pdf(file_url, load_services())
            logger.info("Services presentation exported to %s", path)
            return True
        except Exception:
            logger.exception("Failed to export services presentation to %s", file_url)
            return False

    def bind_report_backend(self, report_backend):
        """Link report backend as client catalog source."""
        self._report_backend = report_backend

    
    # === Автодополнение / Подсказки ===
    
    @pyqtSlot(str)
    def searchServices(self, query):
        """Поиск услуг по запросу."""
        self._services_filter.setFilterText(query)
        count = self._services_filter.rowCount()
        self.countFound.emit(count)
    
    @pyqtSlot()
    def clearSuggestions(self):
        """Clear service suggestions."""
        self._services_filter.clearFilter()
        self.suggestionsCleared.emit()

    @pyqtSlot(str)
    def searchCoefficients(self, query):
        """Search coefficient services by query."""
        self._coefficients_filter.setFilterText(query)
        count = self._coefficients_filter.rowCount()
        self.coefficientsCountFound.emit(count)

    @pyqtSlot()
    def clearCoefficientSuggestions(self):
        """Clear coefficient suggestions."""
        self._coefficients_filter.clearFilter()
    
    @pyqtSlot(float, str, str, str, int)
    def addServiceToOrder(self, amount, client_id, client_name, object_id, price):
        """Add service to order with given parameters."""
        # TODO: Implement order addition logic
        pass

    # === Позиции счета ===

    @pyqtSlot(result=bool)
    def addLineFromSelection(self):
        """Deprecated: use reportBackend.addWork()."""
        return False

    @pyqtSlot(result=bool)
    def createInvoice(self):
        """Create invoice from works added via report backend."""
        if not self._report_backend or self._report_backend.workCount == 0:
            print("[Invoice] Ошибка: нет позиций в счете")
            return False

        self._invoice_counter += 1
        invoice_number = f"INV-{self._invoice_counter:04d}"

        print(f"[Invoice] Создан счет #{invoice_number}")
        for work in self._report_backend.getClientWorks():
            print(
                f"  - {work['name']}: {work['quantity']} x {work['price']} = "
                f"{float(work['price']) * float(work['quantity']):.2f}"
            )
        print(f"  - Итого: {self._report_backend.worksTotal:.2f}")

        self.invoiceCreated.emit(self._invoice_counter, invoice_number)
        self.clearForm()
        return True
    
    @pyqtSlot()
    def clearForm(self):
        """Clear invoice form state."""
        if self._report_backend:
            self._report_backend.clearCurrentService()
            self._report_backend.clearWorks()
        self.clearSuggestions()
        self.clearCoefficientSuggestions()
        self.suggestionsCleared.emit()
        print("[Invoice] Форма очищена")
    
    # === Получение данных ===
    
    @pyqtSlot(result=list)
    def getAllServices(self):
        """Получить список всех услуг"""
        return [
            # {"id": service["id"], "name": service["name"], "price": service["price"]}
            # for service in self._services_db
        ]
    
    @pyqtSlot(int, result=dict)
    def getServiceById(self, service_id):
        """Получить услугу по ID"""
        # for service in self._services_db:
        #     if service["id"] == service_id:
        #         return {
        #             "id": service["id"],
        #             "name": service["name"],
        #             "price": service["price"],
        #         }
        return {}
    
    @pyqtSlot(result=str)
    def getCurrentInvoiceNumber(self):
        """Получить следующий номер счета"""
        return f"INV-{self._invoice_counter + 1:04d}"
