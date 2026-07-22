#!/usr/bin/env python3
"""
SettingsPage Backend
Бэкенд для окна настроек
"""

from qt_compat import QObject, pyqtProperty, pyqtSignal, pyqtSlot

from app_paths import data_dir
from app_version import get_version
from utils.db_storage import load_app_settings, save_app_settings


class SettingsBackend(QObject):
    """Backend для страницы настроек"""
    
    # Сигналы
    settingsChanged = pyqtSignal()
    themeChanged = pyqtSignal()
    languageChanged = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Приватные свойства
        self._app_version = get_version()
        self._app_name = "WorkOrder"
        self._build_date = "2024-01-15"
        self._developer = "WorkOrder Team"
        
        self._theme = "light"
        self._language = "ru"
        self._auto_save = True
        self._currency = "RUB"
        self._vat_rate = 20
        self._invoice_prefix = "INV"
        self._db_path = str(data_dir() / "services.db")
        self._personal_info = ""

        self._load_persisted_settings()
    
    def _load_persisted_settings(self):
        stored = load_app_settings()
        self._theme = stored.get("theme", self._theme)
        self._language = stored.get("language", self._language)
        self._auto_save = stored.get("auto_save", self._auto_save)
        self._currency = stored.get("currency", self._currency)
        self._vat_rate = stored.get("vat_rate", self._vat_rate)
        self._invoice_prefix = stored.get("invoice_prefix", self._invoice_prefix)
        self._db_path = stored.get("db_path", self._db_path)
        self._personal_info = stored.get("personal_info", self._personal_info)

    def _collect_settings(self):
        return {
            "theme": self._theme,
            "language": self._language,
            "auto_save": self._auto_save,
            "currency": self._currency,
            "vat_rate": self._vat_rate,
            "invoice_prefix": self._invoice_prefix,
            "db_path": self._db_path,
            "personal_info": self._personal_info,
        }
    
    # === Свойства приложения (только для чтения) ===
    
    @pyqtProperty(str, notify=settingsChanged)
    def appVersion(self):
        """Версия приложения"""
        return self._app_version
    
    @pyqtProperty(str, notify=settingsChanged)
    def appName(self):
        """Название приложения"""
        return self._app_name
    
    @pyqtProperty(str, notify=settingsChanged)
    def buildDate(self):
        """Дата сборки"""
        return self._build_date
    
    @pyqtProperty(str, notify=settingsChanged)
    def developer(self):
        """Разработчик"""
        return self._developer
    
    @pyqtProperty(str, notify=settingsChanged)
    def fullVersion(self):
        """Полная версия с названием"""
        return f"{self._app_name} v{self._app_version}"
    
    # === Настройки темы ===
    
    @pyqtProperty(str, notify=themeChanged)
    def theme(self):
        return self._theme
    
    @theme.setter
    def theme(self, value):
        if self._theme != value:
            self._theme = value
            self.themeChanged.emit()
            self.settingsChanged.emit()
    
    @pyqtSlot(str)
    def setTheme(self, theme):
        """Установить тему"""
        self.theme = theme
    
    # === Настройки языка ===
    
    @pyqtProperty(str, notify=languageChanged)
    def language(self):
        return self._language
    
    @language.setter
    def language(self, value):
        if self._language != value:
            self._language = value
            self.languageChanged.emit()
            self.settingsChanged.emit()
    
    @pyqtSlot(str)
    def setLanguage(self, language):
        """Установить язык"""
        self.language = language
    
    # === Другие настройки ===
    
    @pyqtProperty(bool, notify=settingsChanged)
    def autoSave(self):
        return self._auto_save
    
    @autoSave.setter
    def autoSave(self, value):
        if self._auto_save != value:
            self._auto_save = value
            self.settingsChanged.emit()
    
    @pyqtProperty(str, notify=settingsChanged)
    def currency(self):
        return self._currency
    
    @currency.setter
    def currency(self, value):
        if self._currency != value:
            self._currency = value
            self.settingsChanged.emit()
    
    @pyqtProperty(int, notify=settingsChanged)
    def vatRate(self):
        return self._vat_rate
    
    @vatRate.setter
    def vatRate(self, value):
        if self._vat_rate != value:
            self._vat_rate = value
            self.settingsChanged.emit()
    
    @pyqtProperty(str, notify=settingsChanged)
    def invoicePrefix(self):
        return self._invoice_prefix
    
    @invoicePrefix.setter
    def invoicePrefix(self, value):
        if self._invoice_prefix != value:
            self._invoice_prefix = value
            self.settingsChanged.emit()
    
    @pyqtProperty(str, notify=settingsChanged)
    def dbPath(self):
        return self._db_path
    
    @dbPath.setter
    def dbPath(self, value):
        if self._db_path != value:
            self._db_path = value
            self.settingsChanged.emit()

    @pyqtProperty(str, constant=True)
    def defaultImportPath(self):
        return str(data_dir() / "import.json")

    @pyqtProperty(str, notify=settingsChanged)
    def personalInfo(self):
        return self._personal_info

    @personalInfo.setter
    def personalInfo(self, value):
        if self._personal_info != value:
            self._personal_info = value
            self.settingsChanged.emit()

    @pyqtSlot(str)
    def setPersonalInfo(self, value):
        self.personalInfo = value
    
    # === Слоты для действий ===
    
    @pyqtSlot(result=bool)
    def saveSettings(self):
        """Сохранить все настройки"""
        save_app_settings(self._collect_settings())
        print("[Settings] Сохранение настроек:")
        print(f"  - Тема: {self._theme}")
        print(f"  - Язык: {self._language}")
        print(f"  - Автосохранение: {self._auto_save}")
        print(f"  - Валюта: {self._currency}")
        print(f"  - НДС: {self._vat_rate}%")
        print(f"  - Личная информация: {len(self._personal_info)} симв.")
        return True
    
    @pyqtSlot(result=bool)
    def resetSettings(self):
        """Сбросить настройки к значениям по умолчанию"""
        self._theme = "light"
        self._language = "ru"
        self._auto_save = True
        self._currency = "RUB"
        self._vat_rate = 20
        self._invoice_prefix = "INV"
        self._db_path = str(data_dir() / "services.db")
        self._personal_info = ""
        self.settingsChanged.emit()
        self.themeChanged.emit()
        self.languageChanged.emit()
        save_app_settings(self._collect_settings())
        print("[Settings] Настройки сброшены к значениям по умолчанию")
        return True
    
    @pyqtSlot(result=bool)
    def exportData(self):
        """Экспорт данных"""
        print(f"[Settings] Экспорт данных из {self._db_path}")
        return True
    
    @pyqtSlot(str, result=bool)
    def importData(self, filePath):
        """Импорт данных"""
        print(f"[Settings] Импорт данных из {filePath}")
        return True
    
    @pyqtSlot(result=bool)
    def resetDatabase(self):
        """Сбросить базу данных"""
        print("[Settings] Сброс базы данных!")
        return True
    
    @pyqtSlot(result=list)
    def getAvailableThemes(self):
        """Получить список доступных тем"""
        return ["light", "dark", "auto"]
    
    @pyqtSlot(result=list)
    def getAvailableLanguages(self):
        """Получить список доступных языков"""
        return [
            {"code": "ru", "name": "Русский"},
            {"code": "en", "name": "English"},
            {"code": "de", "name": "Deutsch"}
        ]
    
    @pyqtSlot(result=list)
    def getAvailableCurrencies(self):
        """Получить список доступных валют"""
        return [
            {"code": "RUB", "symbol": "₽", "name": "Российский рубль"},
            {"code": "USD", "symbol": "$", "name": "Доллар США"},
            {"code": "EUR", "symbol": "€", "name": "Евро"}
        ]
