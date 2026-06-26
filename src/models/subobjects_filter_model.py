from PyQt6.QtCore import (
    Qt,
    QSortFilterProxyModel,
    pyqtProperty,
    pyqtSignal,
    pyqtSlot,
)

from models.subobjects_model import SubobjectsModel


class SubobjectsFilterModel(QSortFilterProxyModel):

    filterTextChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._filter_text = ""
        self.setFilterCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
        self.setFilterRole(SubobjectsModel.NameRole)

    @pyqtProperty(str, notify=filterTextChanged)
    def filterText(self):
        return self._filter_text

    @filterText.setter
    def filterText(self, text):
        if self._filter_text != text:
            self._filter_text = text
            self.invalidateFilter()
            self.filterTextChanged.emit()

    @pyqtSlot(str)
    def setFilterText(self, text):
        self.filterText = text

    @pyqtSlot()
    def clearFilter(self):
        self.filterText = ""

    def filterAcceptsRow(self, source_row, source_parent):
        if self._filter_text == "":
            return False

        source_model = self.sourceModel()
        if not source_model:
            return False

        name_index = source_model.index(source_row, 0, source_parent)
        name = source_model.data(name_index, SubobjectsModel.NameRole) or ""
        return self._filter_text.casefold() in name.casefold()

    @pyqtProperty(int)
    def count(self):
        return self.rowCount()
