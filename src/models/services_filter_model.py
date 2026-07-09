from qt_compat import (
    Qt,
    QSortFilterProxyModel,
    pyqtProperty,
    pyqtSignal,
    pyqtSlot,
)

from utils.service_units import is_percent_unit

import logging

logger = logging.getLogger("workorder")

class ServicesFilterModel(QSortFilterProxyModel):
    
    filterTextChanged = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._filter_text = ""
        self.setFilterCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
        self.setFilterRole(0)  # Will be set dynamically
        
    @pyqtProperty(str, notify=filterTextChanged)
    def filterText(self):
        return self._filter_text
    
    @filterText.setter
    def filterText(self, text):
        if self._filter_text != text:
            self._filter_text = text
            self.setFilterFixedString(text)
            self.filterTextChanged.emit()
    
    @pyqtSlot(str)
    def setFilterText(self, text):
        self._filter_text = text
        self.invalidateFilter()
        self.filterTextChanged.emit()
        self._log_filter_result()

    @pyqtSlot()
    def clearFilter(self):
        self._filter_text = ""
        self.invalidateFilter()
        self.filterTextChanged.emit()
        logger.debug("ServicesFilter: cleared, count=%s", self.rowCount())

    def _log_filter_result(self):
        count = self.rowCount()
        preview = []
        source_model = self.sourceModel()
        if source_model and count > 0:
            for row in range(min(count, 3)):
                idx = self.index(row, 0)
                name = self.data(idx, source_model.NameRole) or ""
                preview.append(name)
        logger.debug(
            "ServicesFilter: query=%r count=%s preview=%s",
            self._filter_text,
            count,
            preview,
        )
    
    def filterAcceptsRow(self, source_row, source_parent):
        if self._filter_text == "":
            return False
            
        source_model = self.sourceModel()
        if not source_model:
            return True
            
        # Get name and keywords from source model
        name_index = source_model.index(source_row, 0, source_parent)
        name = source_model.data(name_index, source_model.NameRole) or ""
        keywords = source_model.data(name_index, source_model.KeywordsRole) or ""
        unit = source_model.data(name_index, source_model.UnitRole) or ""

        if is_percent_unit(unit):
            return False

        filter_lower = self._filter_text.lower()
        return filter_lower in name.lower() or filter_lower in keywords.lower()
    
    @pyqtProperty(int)
    def count(self):
        return self.rowCount()
