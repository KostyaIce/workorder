#!/usr/bin/env python3
"""
DatabasePage Backend
Бэкенд для окна управления базой услуг
"""

from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty

from utils.db_storage import create_works_database
from utils.services_db import (
    create_services_table,
    default_services_db_path,
    load_services,
)


class DatabaseBackend(QObject):
    """Backend для страницы базы данных услуг"""
    
    # Сигналы
    servicesChanged = pyqtSignal()  # Изменился список услуг
    serviceAdded = pyqtSignal(int, str, float)  # id, name, price
    serviceUpdated = pyqtSignal(int, str, float)  # id, name, price
    serviceDeleted = pyqtSignal(int)  # id
    serviceSelected = pyqtSignal(int, str, float)  # id, name, price
    worksChanged = pyqtSignal()
    databaseRepaired = pyqtSignal(str)
    errorOccurred = pyqtSignal(str)  # error message
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        self._services_db_path = str(default_services_db_path())
        # self._works_db_path = str(default_works_db_path())
        # self._works = []
        
        # Счетчик ID
        self._next_id = 16
        
        # База услуг
        self._services = [
            {"id": 1, "name": "Диагностика оборудования", "price": 500.0},
            {"id": 2, "name": "Ремонт компьютера", "price": 1500.0},
            {"id": 3, "name": "Ремонт ноутбука", "price": 2000.0},
            {"id": 4, "name": "Замена экрана", "price": 3500.0},
            {"id": 5, "name": "Замена батареи", "price": 1200.0},
            {"id": 6, "name": "Установка Windows", "price": 2500.0},
            {"id": 7, "name": "Установка программ", "price": 800.0},
            {"id": 8, "name": "Чистка от пыли", "price": 1000.0},
            {"id": 9, "name": "Замена термопасты", "price": 600.0},
            {"id": 10, "name": "Восстановление данных", "price": 3000.0},
            {"id": 11, "name": "Настройка сети", "price": 1200.0},
            {"id": 12, "name": "Консультация", "price": 500.0},
            {"id": 13, "name": "Ремонт материнской платы", "price": 4500.0},
            {"id": 14, "name": "Замена клавиатуры", "price": 1800.0},
            {"id": 15, "name": "Ремонт блока питания", "price": 2200.0},
        ]
        
        # Выбранная услуга
        self._selected_service_id = 0
    
    # === Свойства ===
    
    @pyqtProperty(int, notify=servicesChanged)
    def serviceCount(self):
        """Количество услуг в базе"""
        return len(self._services)
    
    @pyqtProperty(int, notify=serviceSelected)
    def selectedServiceId(self):
        """ID выбранной услуги"""
        return self._selected_service_id

    @pyqtProperty(str, notify=servicesChanged)
    def servicesDbPath(self):
        """Path to services SQLite database"""
        return self._services_db_path

    # @pyqtProperty(str, notify=worksChanged)
    # def worksDbPath(self):
    #     """Path to completed works SQLite database"""
    #     return self._works_db_path

    @pyqtProperty(int, notify=worksChanged)
    def workCount(self):
        """Number of loaded completed works"""
        return 0 # return len(self._works)
    
    # === CRUD операции ===
    
    @pyqtSlot(str, float, result=bool)
    def addService(self, name, price):
        """
        Добавить новую услугу
        
        Args:
            name: Название услуги
            price: Цена за единицу
        
        Returns:
            bool: True если успешно
        """
        # Валидация
        if not name or len(name.strip()) == 0:
            self.errorOccurred.emit("Название услуги не может быть пустым")
            return False
        
        if price < 0:
            self.errorOccurred.emit("Цена не может быть отрицательной")
            return False
        
        # Проверка на дубликат
        name_lower = name.strip().lower()
        for service in self._services:
            if service["name"].lower() == name_lower:
                self.errorOccurred.emit(f"Услуга '{name}' уже существует")
                return False
        
        # Создаем услугу
        new_id = self._next_id
        self._next_id += 1
        
        new_service = {
            "id": new_id,
            "name": name.strip(),
            "price": float(price)
        }
        
        self._services.append(new_service)
        self.servicesChanged.emit()
        self.serviceAdded.emit(new_id, name.strip(), float(price))
        self._persist_services()
        
        print(f"[Database] Добавлена услуга: {name} (ID: {new_id}, Цена: {price})")
        return True
    
    @pyqtSlot(int, str, float, result=bool)
    def updateService(self, service_id, name, price):
        """
        Обновить существующую услугу
        
        Args:
            service_id: ID услуги
            name: Новое название
            price: Новая цена
        
        Returns:
            bool: True если успешно
        """
        # Валидация
        if not name or len(name.strip()) == 0:
            self.errorOccurred.emit("Название услуги не может быть пустым")
            return False
        
        if price < 0:
            self.errorOccurred.emit("Цена не может быть отрицательной")
            return False
        
        # Ищем услугу
        for service in self._services:
            if service["id"] == service_id:
                old_name = service["name"]
                service["name"] = name.strip()
                service["price"] = float(price)
                
                self.servicesChanged.emit()
                self.serviceUpdated.emit(service_id, name.strip(), float(price))
                self._persist_services()
                
                print(f"[Database] Обновлена услуга ID {service_id}: '{old_name}' -> '{name}' ({price})")
                return True
        
        self.errorOccurred.emit(f"Услуга с ID {service_id} не найдена")
        return False
    
    @pyqtSlot(int, result=bool)
    def deleteService(self, service_id):
        """
        Удалить услугу
        
        Args:
            service_id: ID услуги
        
        Returns:
            bool: True если успешно
        """
        for i, service in enumerate(self._services):
            if service["id"] == service_id:
                name = service["name"]
                del self._services[i]
                
                if self._selected_service_id == service_id:
                    self._selected_service_id = 0
                    self.serviceSelected.emit(0, "", 0.0)
                
                self.servicesChanged.emit()
                self.serviceDeleted.emit(service_id)
                self._persist_services()
                
                print(f"[Database] Удалена услуга: {name} (ID: {service_id})")
                return True
        
        self.errorOccurred.emit(f"Услуга с ID {service_id} не найдена")
        return False
    
    @pyqtSlot(int)
    def selectService(self, service_id):
        """Выбрать услугу (для редактирования)"""
        for service in self._services:
            if service["id"] == service_id:
                self._selected_service_id = service_id
                self.serviceSelected.emit(service_id, service["name"], service["price"])
                return
        
        self._selected_service_id = 0
        self.serviceSelected.emit(0, "", 0.0)
    
    @pyqtSlot()
    def clearSelection(self):
        """Снять выделение"""
        self._selected_service_id = 0
        self.serviceSelected.emit(0, "", 0.0)
    
    # === Поиск и фильтрация ===
    
    @pyqtSlot(result=list)
    def getAllServices(self):
        """Получить список всех услуг"""
        return self._services.copy()
    
    @pyqtSlot(int, result=dict)
    def getServiceById(self, service_id):
        """Получить услугу по ID"""
        for service in self._services:
            if service["id"] == service_id:
                return service.copy()
        return {}
    
    @pyqtSlot(str, result=list)
    def searchServices(self, query):
        """Поиск услуг по названию"""
        if not query:
            return self._services.copy()
        
        query = query.lower().strip()
        results = []
        
        for service in self._services:
            if query in service["name"].lower():
                results.append(service.copy())
        
        return results
    
    @pyqtSlot(float, float, result=list)
    def filterByPriceRange(self, min_price, max_price):
        """Фильтровать услуги по диапазону цен"""
        results = []
        for service in self._services:
            if min_price <= service["price"] <= max_price:
                results.append(service.copy())
        return results
    
    # === SQLite databases ===

    @pyqtSlot(str, result=bool)
    def createServicesDatabase(self, file_path=""):
        """Create services SQLite table."""
        try:
            create_services_table()
            self._services_db_path = str(default_services_db_path())
            print(f"[Database] Created services DB: {self._services_db_path}")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка создания БД услуг: {str(e)}")
            return False

    @pyqtSlot(str, result=bool)
    def createWorksDatabase(self, file_path=""):
        """
        Create SQLite database with sample completed works.

        Args:
            file_path: Optional path. Empty string uses ./data/works.db
        """
        try:
            db_path, count = create_works_database(file_path)
            # self._works_db_path = db_path
            # self._works = load_completed_works(db_path)
            self.worksChanged.emit()
            print(f"[Database] Created works DB: {db_path} ({count} rows)")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка создания БД работ: {str(e)}")
            return False

    @pyqtSlot(str, result=bool)
    def repairDatabase(self, file_path=""):
        """Ensure services table exists."""
        try:
            create_services_table()
            self._services_db_path = str(default_services_db_path())
            self.databaseRepaired.emit("Services table checked")
            print("[Database] Repair completed: services table checked")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка исправления БД: {str(e)}")
            return False

    def _persist_services(self):
        pass

    @pyqtSlot(str, result=bool)
    def loadServicesFromDatabase(self, file_path=""):
        """Load services list from SQLite into memory."""
        try:
            create_services_table()
            services = load_services()
            if not services:
                self.errorOccurred.emit(
                    f"БД услуг пуста или не найдена: {default_services_db_path()}"
                )
                return False

            self._services_db_path = str(default_services_db_path())
            self._apply_services(services)
            print(f"[Database] Loaded {len(services)} services from {self._services_db_path}")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка загрузки БД услуг: {str(e)}")
            return False

    @pyqtSlot(str, result=bool)
    def loadWorksFromDatabase(self, file_path=""):
        """Load completed works from SQLite into memory."""
        try:
            # db_path = file_path or self._works_db_path
            # works = load_completed_works(db_path)
            # if not works:
            #     self.errorOccurred.emit(f"БД работ пуста или не найдена: {db_path}")
            #     return False
            #
            # # self._works_db_path = db_path
            # self._works = works
            # self.worksChanged.emit()
            # print(f"[Database] Loaded {len(works)} works from {db_path}")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка загрузки БД работ: {str(e)}")
            return False

    @pyqtSlot(result=list)
    def getAllCompletedWorks(self):
        """Get loaded completed works list."""
        return [work.copy() for work in self._works]

    # @pyqtSlot(str, result=dict)
    # def getWorksStatistics(self, file_path=""):
    #     """Get statistics for completed works database."""
    #     return storage_works_statistics(file_path or self._works_db_path)

    def _apply_services(self, services):
        self._services = services
        if services:
            self._next_id = max(service["id"] for service in services) + 1
        else:
            self._next_id = 1
        self._selected_service_id = 0
        self.servicesChanged.emit()
        self.serviceSelected.emit(0, "", 0.0)

    # === Импорт/Экспорт ===
    
    @pyqtSlot(str, result=bool)
    def exportToJson(self, file_path):
        """Экспортировать услуги в JSON"""
        import json
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(self._services, f, ensure_ascii=False, indent=2)
            print(f"[Database] Экспортировано {len(self._services)} услуг в {file_path}")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка экспорта: {str(e)}")
            return False
    
    @pyqtSlot(str, result=bool)
    def importFromJson(self, file_path):
        """Импортировать услуги из JSON"""
        import json
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            count = 0
            for item in data:
                if "name" in item and "price" in item:
                    if self.addService(item["name"], item["price"]):
                        count += 1
            
            print(f"[Database] Импортировано {count} услуг из {file_path}")
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Ошибка импорта: {str(e)}")
            return False
    
    @pyqtSlot(result=bool)
    def resetDatabase(self):
        """Сбросить базу данных (удалить все услуги)"""
        self._services = []
        self._selected_service_id = 0
        self._next_id = 1
        self.servicesChanged.emit()
        self.serviceSelected.emit(0, "", 0.0)
        self._persist_services()
        print("[Database] База данных сброшена")
        return True
    
    # === Статистика ===
    
    @pyqtSlot(result=dict)
    def getStatistics(self):
        """Получить статистику по услугам"""
        if not self._services:
            return {
                "count": 0,
                "min_price": 0,
                "max_price": 0,
                "avg_price": 0,
                "total_value": 0,
            }

        prices = [s["price"] for s in self._services]
        return {
            "count": len(self._services),
            "min_price": min(prices),
            "max_price": max(prices),
            "avg_price": sum(prices) / len(prices),
            "total_value": sum(prices),
        }
