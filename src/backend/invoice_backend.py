#!/usr/bin/env python3
"""
InvoicePage Backend
Бэкенд для окна создания счета с автодополнением
"""

from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty


def _keywords_from_name(name):
    words = [word.lower() for word in name.split() if len(word) > 2]
    return words or [name.lower()]


class InvoiceBackend(QObject):
    """Backend для страницы создания счета"""
    
    # Сигналы
    serviceSelected = pyqtSignal(int, str, float)  # id, name, price
    quantityChanged = pyqtSignal(int)
    totalCalculated = pyqtSignal(float)
    linesChanged = pyqtSignal()
    currentClientChanged = pyqtSignal()
    suggestionsUpdated = pyqtSignal(list)  # Список подсказок
    suggestionsCleared = pyqtSignal()
    invoiceCreated = pyqtSignal(int, str)  # invoice_id, invoice_number
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Текущие значения для добавления позиции
        self._current_service_id = 0
        self._current_service_name = ""
        self._current_price = 0.0
        self._quantity = 1
        self._invoice_total = 0.0
        
        self._lines = []
        self._next_line_id = 1
        self._invoice_counter = 0

        self._current_client_id = 0
        self._current_client_name = ""
        self._current_client_kind = ""
        
        self._services_db = []
        self._load_default_services()
    
    def _load_default_services(self):
        self._services_db = [
            {"id": 1, "name": "Диагностика оборудования", "price": 500.0, "keywords": ["диагностика", "проверка"]},
            {"id": 2, "name": "Ремонт компьютера", "price": 1500.0, "keywords": ["ремонт", "компьютер", "пк"]},
            {"id": 3, "name": "Ремонт ноутбука", "price": 2000.0, "keywords": ["ремонт", "ноутбук", "лаптоп"]},
            {"id": 4, "name": "Замена экрана", "price": 3500.0, "keywords": ["экран", "дисплей", "замена"]},
            {"id": 5, "name": "Замена батареи", "price": 1200.0, "keywords": ["батарея", "аккумулятор", "замена"]},
            {"id": 6, "name": "Установка Windows", "price": 2500.0, "keywords": ["windows", "установка", "ос"]},
            {"id": 7, "name": "Установка программ", "price": 800.0, "keywords": ["программа", "установка", "софт"]},
            {"id": 8, "name": "Чистка от пыли", "price": 1000.0, "keywords": ["чистка", "пыль", "обслуживание"]},
            {"id": 9, "name": "Замена термопасты", "price": 600.0, "keywords": ["термопаста", "охлаждение", "замена"]},
            {"id": 10, "name": "Восстановление данных", "price": 3000.0, "keywords": ["данные", "восстановление", "файл"]},
            {"id": 11, "name": "Настройка сети", "price": 1200.0, "keywords": ["сеть", "wifi", "интернет", "настройка"]},
            {"id": 12, "name": "Консультация", "price": 500.0, "keywords": ["консультация", "совет", "вопрос"]},
            {"id": 13, "name": "Ремонт материнской платы", "price": 4500.0, "keywords": ["материнская плата", "ремонт", "майн"]},
            {"id": 14, "name": "Замена клавиатуры", "price": 1800.0, "keywords": ["клавиатура", "замена", "кнопки"]},
            {"id": 15, "name": "Ремонт блока питания", "price": 2200.0, "keywords": ["блок питания", "бп", "ремонт"]},
        ]
    
    # === Свойства ===
    
    @pyqtProperty(float, notify=totalCalculated)
    def currentTotal(self):
        """Итоговая сумма по всем позициям счета"""
        return self._invoice_total
    
    @pyqtProperty(str, notify=serviceSelected)
    def currentServiceName(self):
        """Название выбранной услуги"""
        return self._current_service_name
    
    @pyqtProperty(float, notify=serviceSelected)
    def currentPrice(self):
        """Цена выбранной услуги"""
        return self._current_price
    
    @pyqtProperty(int, notify=quantityChanged)
    def currentQuantity(self):
        """Количество для новой позиции"""
        return self._quantity

    @pyqtProperty(int, notify=linesChanged)
    def lineCount(self):
        """Количество позиций в счете"""
        return len(self._lines)

    @pyqtProperty(int, notify=currentClientChanged)
    def currentClientId(self):
        """ID текущего заказчика или объекта"""
        return self._current_client_id

    @pyqtProperty(str, notify=currentClientChanged)
    def currentClientName(self):
        """Название текущего заказчика или объекта"""
        return self._current_client_name

    @pyqtProperty(str, notify=currentClientChanged)
    def currentClientKind(self):
        """Тип текущего получателя: customer или object"""
        return self._current_client_kind

    @pyqtProperty(str, notify=currentClientChanged)
    def currentClientLabel(self):
        """Отображаемая подпись получателя счета"""
        if not self._current_client_name:
            return ""
        kind_label = "Объект" if self._current_client_kind == "object" else "Заказчик"
        return f"{kind_label}: {self._current_client_name}"

    @pyqtProperty(bool, notify=currentClientChanged)
    def hasCurrentClient(self):
        """Выбран ли заказчик или объект"""
        return self._current_client_id > 0
    
    # === Каталог услуг ===

    @pyqtSlot(list)
    def setServicesCatalog(self, services):
        """Sync services catalog from database backend."""
        self._services_db = []
        for service in services:
            name = service.get("name", "")
            self._services_db.append({
                "id": service.get("id", 0),
                "name": name,
                "price": float(service.get("price", 0.0)),
                "keywords": _keywords_from_name(name),
            })
    
    # === Текущий заказчик / объект ===

    @pyqtSlot(int, str, str)
    def setCurrentClient(self, client_id, name, kind):
        """Set invoice recipient customer or object."""
        if client_id <= 0:
            self.clearCurrentClient()
            return

        self._current_client_id = client_id
        self._current_client_name = name.strip()
        self._current_client_kind = kind if kind in ("customer", "object") else "customer"
        self.currentClientChanged.emit()
        print(f"[Invoice] Получатель счета: {self.currentClientLabel}")

    @pyqtSlot(int, result=bool)
    def setCurrentClientById(self, client_id):
        """Set current client by id using report backend catalog."""
        if client_id <= 0:
            self.clearCurrentClient()
            return True

        report_backend = getattr(self, "_report_backend", None)
        if report_backend is None:
            return False

        for client in report_backend.getAllClients():
            if client["id"] == client_id:
                self.setCurrentClient(client["id"], client["name"], client["kind"])
                return True
        return False

    def bind_report_backend(self, report_backend):
        """Link report backend as client catalog source."""
        self._report_backend = report_backend

    @pyqtSlot()
    def clearCurrentClient(self):
        """Clear invoice recipient."""
        self._current_client_id = 0
        self._current_client_name = ""
        self._current_client_kind = ""
        self.currentClientChanged.emit()
    
    # === Автодополнение / Подсказки ===
    
    @pyqtSlot(str)
    def searchServices(self, query):
        """Поиск услуг по запросу."""
        if not query or len(query.strip()) == 0:
            self.suggestionsCleared.emit()
            return
        
        query = query.lower().strip()
        suggestions = []
        
        for service in self._services_db:
            if query in service["name"].lower():
                suggestions.append({
                    "id": service["id"],
                    "name": service["name"],
                    "price": service["price"],
                    "match_type": "name",
                })
                continue
            
            for keyword in service["keywords"]:
                if query in keyword.lower():
                    suggestions.append({
                        "id": service["id"],
                        "name": service["name"],
                        "price": service["price"],
                        "match_type": "keyword",
                    })
                    break
        
        suggestions.sort(key=lambda item: (item["match_type"] != "name", item["name"]))
        suggestions = suggestions[:5]
        
        self.suggestionsUpdated.emit(suggestions)
        print(f"[Invoice] Поиск '{query}': найдено {len(suggestions)} подсказок")
    
    @pyqtSlot()
    def clearSuggestions(self):
        """Очистить подсказки"""
        self.suggestionsCleared.emit()
    
    # === Выбор услуги ===
    
    @pyqtSlot(int, result=bool)
    def selectServiceById(self, service_id):
        """Выбрать услугу по ID"""
        for service in self._services_db:
            if service["id"] == service_id:
                self._current_service_id = service_id
                self._current_service_name = service["name"]
                self._current_price = service["price"]
                self.serviceSelected.emit(service_id, service["name"], service["price"])
                self.suggestionsCleared.emit()
                print(f"[Invoice] Выбрана услуга: {service['name']} ({service['price']} руб.)")
                return True
        return False
    
    @pyqtSlot(str, result=bool)
    def selectServiceByName(self, name):
        """Выбрать услугу по названию (точное совпадение)"""
        for service in self._services_db:
            if service["name"].lower() == name.lower():
                return self.selectServiceById(service["id"])
        return False
    
    # === Количество для новой позиции ===
    
    @pyqtSlot(int)
    def setQuantity(self, quantity):
        """Установить количество для добавляемой позиции"""
        if quantity < 1:
            quantity = 1
        if quantity > 999:
            quantity = 999
        
        self._quantity = quantity
        self.quantityChanged.emit(quantity)
    
    @pyqtSlot()
    def incrementQuantity(self):
        """Увеличить количество на 1"""
        self.setQuantity(self._quantity + 1)
    
    @pyqtSlot()
    def decrementQuantity(self):
        """Уменьшить количество на 1"""
        self.setQuantity(self._quantity - 1)

    # === Позиции счета ===

    @pyqtSlot(result=bool)
    def addLineFromSelection(self):
        """Add currently selected service as invoice line."""
        if self._current_service_id == 0:
            print("[Invoice] Ошибка: услуга не выбрана")
            return False

        line_id = self._next_line_id
        self._next_line_id += 1
        quantity = self._quantity
        line_total = self._current_price * quantity
        self._lines.append({
            "line_id": line_id,
            "service_id": self._current_service_id,
            "name": self._current_service_name,
            "unit_price": self._current_price,
            "quantity": quantity,
            "line_total": line_total,
        })
        self._recalculate_invoice_total()
        self.linesChanged.emit()
        print(f"[Invoice] Добавлена позиция: {self._current_service_name} x{quantity}")
        return True

    @pyqtSlot(int, int, result=bool)
    def setLineQuantity(self, line_id, quantity):
        """Update quantity for invoice line."""
        if quantity < 1:
            quantity = 1
        if quantity > 999:
            quantity = 999

        for line in self._lines:
            if line["line_id"] == line_id:
                line["quantity"] = quantity
                line["line_total"] = line["unit_price"] * quantity
                self._recalculate_invoice_total()
                self.linesChanged.emit()
                return True
        return False

    @pyqtSlot(int, str, float, result=bool)
    def updateLine(self, line_id, name, unit_price):
        """Update service name and unit price for invoice line."""
        if not name or len(name.strip()) == 0:
            return False
        if unit_price < 0:
            return False

        for line in self._lines:
            if line["line_id"] == line_id:
                line["name"] = name.strip()
                line["unit_price"] = float(unit_price)
                line["line_total"] = line["unit_price"] * line["quantity"]
                self._recalculate_invoice_total()
                self.linesChanged.emit()
                return True
        return False

    @pyqtSlot(int, result=bool)
    def removeLine(self, line_id):
        """Remove invoice line."""
        for index, line in enumerate(self._lines):
            if line["line_id"] == line_id:
                del self._lines[index]
                self._recalculate_invoice_total()
                self.linesChanged.emit()
                return True
        return False

    @pyqtSlot(result=list)
    def getInvoiceLines(self):
        """Get current invoice lines."""
        return [line.copy() for line in self._lines]

    def _recalculate_invoice_total(self):
        self._invoice_total = sum(line["line_total"] for line in self._lines)
        self.totalCalculated.emit(self._invoice_total)
    
    # === Создание счета ===
    
    @pyqtSlot(result=bool)
    def createInvoice(self):
        """Создать счет по текущему списку позиций"""
        if not self._lines:
            print("[Invoice] Ошибка: нет позиций в счете")
            return False
        
        self._invoice_counter += 1
        invoice_number = f"INV-{self._invoice_counter:04d}"
        
        print(f"[Invoice] Создан счет #{invoice_number}")
        if self._current_client_name:
            print(f"  - Получатель: {self.currentClientLabel}")
        for line in self._lines:
            print(
                f"  - {line['name']}: {line['quantity']} x {line['unit_price']} = {line['line_total']}"
            )
        print(f"  - Итого: {self._invoice_total}")
        
        self.invoiceCreated.emit(self._invoice_counter, invoice_number)
        self.clearForm()
        return True
    
    @pyqtSlot()
    def clearForm(self):
        """Очистить форму и список позиций"""
        self._current_service_id = 0
        self._current_service_name = ""
        self._current_price = 0.0
        self._quantity = 1
        self._lines = []
        self._invoice_total = 0.0
        self.suggestionsCleared.emit()
        self.serviceSelected.emit(0, "", 0.0)
        self.quantityChanged.emit(1)
        self.linesChanged.emit()
        self.totalCalculated.emit(0.0)
        print("[Invoice] Форма очищена")
    
    # === Получение данных ===
    
    @pyqtSlot(result=list)
    def getAllServices(self):
        """Получить список всех услуг"""
        return [
            {"id": service["id"], "name": service["name"], "price": service["price"]}
            for service in self._services_db
        ]
    
    @pyqtSlot(int, result=dict)
    def getServiceById(self, service_id):
        """Получить услугу по ID"""
        for service in self._services_db:
            if service["id"] == service_id:
                return {
                    "id": service["id"],
                    "name": service["name"],
                    "price": service["price"],
                }
        return {}
    
    @pyqtSlot(result=str)
    def getCurrentInvoiceNumber(self):
        """Получить следующий номер счета"""
        return f"INV-{self._invoice_counter + 1:04d}"
