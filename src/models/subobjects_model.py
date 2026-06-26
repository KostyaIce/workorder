from PyQt6.QtCore import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty,
)


class SubobjectsModel(QAbstractListModel):

    NameRole = Qt.ItemDataRole.UserRole + 1

    def __init__(self):
        super().__init__()
        self._items = []

    def updateModel(self, names):
        self.beginResetModel()
        unique_names = []
        seen = set()
        for name in names or []:
            value = name.strip() if isinstance(name, str) else ""
            if not value:
                continue
            key = value.casefold()
            if key in seen:
                continue
            seen.add(key)
            unique_names.append(value)
        unique_names.sort(key=str.casefold)
        self._items = [{"name": name} for name in unique_names]
        self.endResetModel()

    def addItem(self, name):
        value = name.strip() if isinstance(name, str) else ""
        if not value:
            return False

        for item in self._items:
            if item["name"].casefold() == value.casefold():
                return False

        row = len(self._items)
        self.beginInsertRows(QModelIndex(), row, row)
        self._items.append({"name": value})
        self.endInsertRows()
        return True

    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    def data(self, index, role):
        if not index.isValid():
            return None

        item = self._items[index.row()]

        if role == self.NameRole:
            return item["name"]

        return None

    def roleNames(self):
        return {
            self.NameRole: b"name",
        }

    @pyqtProperty(int)
    def count(self):
        return len(self._items)
