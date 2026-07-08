from qt_compat import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty
)

class ObjectModel(QAbstractListModel):

    IdRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    AddressRole = Qt.ItemDataRole.UserRole + 3
    UpdatedAtRole = Qt.ItemDataRole.UserRole + 4
    LastOrderAtRole = Qt.ItemDataRole.UserRole + 5

    def __init__(self):
        super().__init__()
        self._items = []

    def updateModel(self, items):
        self.beginResetModel()
        self._items = items
        self.endResetModel()

    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    def data(self, index, role):
        if not index.isValid():
            return None

        item = self._items[index.row()]

        if role == self.IdRole:
            return item["id"]

        if role == self.NameRole:
            return item["name"]

        if role == self.AddressRole:
            return item["address"]

        if role == self.UpdatedAtRole:
            return item["updated_at"]

        if role == self.LastOrderAtRole:
            return item["last_order_at"]

        return None

    def roleNames(self):
        return {
            self.IdRole: b"id",
            self.NameRole: b"name",
            self.AddressRole: b"address",
            self.UpdatedAtRole: b"updated_at",
            self.LastOrderAtRole: b"last_order_at"
        }

    def itemData(self, id):
        for item in self._items:
            if item["id"] == id:
                return item
        return None

    @pyqtProperty(int)
    def count(self):
        return len(self._items)
