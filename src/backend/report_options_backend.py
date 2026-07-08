#!/usr/bin/env python3
"""
Report options backend: report layout settings and order selection.
"""

from qt_compat import QObject, pyqtProperty, pyqtSignal, pyqtSlot

from utils.qsettings_store import QSettingsStore


_SETTINGS_KEY_INCLUDE_CLIENT_NAME = "report_options/include_client_name"
_SETTINGS_KEY_INCLUDE_CLIENT_ADDRESS = "report_options/include_client_address"
_SETTINGS_KEY_INCLUDE_REPORT_DATE = "report_options/include_report_date"
_SETTINGS_KEY_INCLUDE_PERSONAL_INFO = "report_options/include_personal_info"
_SETTINGS_KEY_INCLUDE_REPORT_HEADER = "report_options/include_report_header"
_SETTINGS_KEY_REPORT_HEADER_TEXT = "report_options/report_header_text"
_SETTINGS_KEY_GROUP_BY_SUBOBJECTS = "report_options/group_by_subobjects"

_DEFAULT_REPORT_HEADER = "Отчет о проделанной работе по установке сантехники"


class ReportOptionsBackend(QObject):
    """Backend for report generation options and selected orders."""

    optionsChanged = pyqtSignal()
    orderSelectionChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._include_client_name = True
        self._include_client_address = True
        self._include_report_date = True
        self._include_personal_info = True
        self._include_report_header = True
        self._report_header_text = _DEFAULT_REPORT_HEADER
        self._group_by_subobjects = True
        self._selected_orders = set()
        self._load_settings()

    def _load_settings(self):
        with QSettingsStore() as store:
            self._include_client_name = store.read(
                _SETTINGS_KEY_INCLUDE_CLIENT_NAME, True, value_type=bool
            )
            self._include_client_address = store.read(
                _SETTINGS_KEY_INCLUDE_CLIENT_ADDRESS, True, value_type=bool
            )
            self._include_report_date = store.read(
                _SETTINGS_KEY_INCLUDE_REPORT_DATE, True, value_type=bool
            )
            self._include_personal_info = store.read(
                _SETTINGS_KEY_INCLUDE_PERSONAL_INFO, True, value_type=bool
            )
            self._include_report_header = store.read(
                _SETTINGS_KEY_INCLUDE_REPORT_HEADER, True, value_type=bool
            )
            self._report_header_text = store.read(
                _SETTINGS_KEY_REPORT_HEADER_TEXT,
                _DEFAULT_REPORT_HEADER,
                value_type=str,
            ) or _DEFAULT_REPORT_HEADER
            self._group_by_subobjects = store.read(
                _SETTINGS_KEY_GROUP_BY_SUBOBJECTS, True, value_type=bool
            )

    def _persist_settings(self):
        with QSettingsStore() as store:
            store.write(_SETTINGS_KEY_INCLUDE_CLIENT_NAME, self._include_client_name)
            store.write(_SETTINGS_KEY_INCLUDE_CLIENT_ADDRESS, self._include_client_address)
            store.write(_SETTINGS_KEY_INCLUDE_REPORT_DATE, self._include_report_date)
            store.write(_SETTINGS_KEY_INCLUDE_PERSONAL_INFO, self._include_personal_info)
            store.write(_SETTINGS_KEY_INCLUDE_REPORT_HEADER, self._include_report_header)
            store.write(_SETTINGS_KEY_REPORT_HEADER_TEXT, self._report_header_text)
            store.write(_SETTINGS_KEY_GROUP_BY_SUBOBJECTS, self._group_by_subobjects)

    def as_dict(self):
        """Return current options as plain dict for report builder."""
        return {
            "include_client_name": self._include_client_name,
            "include_client_address": self._include_client_address,
            "include_report_date": self._include_report_date,
            "include_personal_info": self._include_personal_info,
            "include_report_header": self._include_report_header,
            "report_header_text": self._report_header_text,
            "group_by_subobjects": self._group_by_subobjects,
        }

    @pyqtProperty(bool, notify=optionsChanged)
    def includeClientName(self):
        return self._include_client_name

    @includeClientName.setter
    def includeClientName(self, value):
        if self._include_client_name != value:
            self._include_client_name = value
            self.optionsChanged.emit()

    @pyqtProperty(bool, notify=optionsChanged)
    def includeClientAddress(self):
        return self._include_client_address

    @includeClientAddress.setter
    def includeClientAddress(self, value):
        if self._include_client_address != value:
            self._include_client_address = value
            self.optionsChanged.emit()

    @pyqtProperty(bool, notify=optionsChanged)
    def includeReportDate(self):
        return self._include_report_date

    @includeReportDate.setter
    def includeReportDate(self, value):
        if self._include_report_date != value:
            self._include_report_date = value
            self.optionsChanged.emit()

    @pyqtProperty(bool, notify=optionsChanged)
    def includePersonalInfo(self):
        return self._include_personal_info

    @includePersonalInfo.setter
    def includePersonalInfo(self, value):
        if self._include_personal_info != value:
            self._include_personal_info = value
            self.optionsChanged.emit()

    @pyqtProperty(bool, notify=optionsChanged)
    def includeReportHeader(self):
        return self._include_report_header

    @includeReportHeader.setter
    def includeReportHeader(self, value):
        if self._include_report_header != value:
            self._include_report_header = value
            self.optionsChanged.emit()

    @pyqtProperty(str, notify=optionsChanged)
    def reportHeaderText(self):
        return self._report_header_text

    @reportHeaderText.setter
    def reportHeaderText(self, value):
        text = value or ""
        if self._report_header_text != text:
            self._report_header_text = text
            self.optionsChanged.emit()

    @pyqtProperty(bool, notify=optionsChanged)
    def groupBySubobjects(self):
        return self._group_by_subobjects

    @groupBySubobjects.setter
    def groupBySubobjects(self, value):
        if self._group_by_subobjects != value:
            self._group_by_subobjects = value
            self.optionsChanged.emit()

    @pyqtSlot(result=bool)
    def saveSettings(self):
        """Persist static report options to application settings."""
        self._persist_settings()
        return True

    @pyqtSlot()
    def clearOrderSelection(self):
        """Drop all selected orders (before report options dialog opens)."""
        if not self._selected_orders:
            return
        self._selected_orders.clear()
        self.orderSelectionChanged.emit()

    @pyqtSlot(int, result=bool)
    def orderSelected(self, start_order_at):
        return int(start_order_at) in self._selected_orders

    @pyqtSlot(int, bool)
    def setOrderSelected(self, start_order_at, selected):
        value = int(start_order_at)
        if selected:
            if value not in self._selected_orders:
                self._selected_orders.add(value)
                self.orderSelectionChanged.emit()
            return

        if value in self._selected_orders:
            self._selected_orders.remove(value)
            self.orderSelectionChanged.emit()

    @pyqtSlot(result=list)
    def selectedOrderTimestamps(self):
        return self._selected_orders
