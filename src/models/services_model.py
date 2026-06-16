from PyQt6.QtCore import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty
)

class ServiceModel(QAbstractListModel):

    IdRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    PriceRole = Qt.ItemDataRole.UserRole + 3
    UnitRole = Qt.ItemDataRole.UserRole + 4
    KeywordsRole = Qt.ItemDataRole.UserRole + 5
    CreatedAtRole = Qt.ItemDataRole.UserRole + 6
    UpdatedAtRole = Qt.ItemDataRole.UserRole + 7

    def __init__(self):
        super().__init__()
        self._items = []

    def updateModel(self, items):
        self.beginResetModel()
        self._items = items
        self._items.sort(
            key=lambda x: x["name"].lower()
        )
        self.endResetModel()

    def addItem(self, item):
        row = len(self._items)

        self.beginInsertRows(
            QModelIndex(),
            row,
            row
        )

        self._items.append(item)

        self.endInsertRows()

        # self.beginResetModel()
        # self._items.append(item)
        # self._items.sort(
        #     key=lambda x: x["name"].lower()
        # )
        # self.endResetModel()

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

        if role == self.PriceRole:
            return item["price"]

        if role == self.UnitRole:
            return item["unit"]

        if role == self.KeywordsRole:
            return item["keywords"]

        if role == self.CreatedAtRole:
            return item["created_at"]

        if role == self.UpdatedAtRole:
            return item["updated_at"]

        return None

    def roleNames(self):
        return {
            self.IdRole: b"id",
            self.NameRole: b"name",
            self.PriceRole: b"price",
            self.UnitRole: b"unit",
            self.KeywordsRole: b"keywords",
            self.CreatedAtRole: b"created_at",
            self.UpdatedAtRole: b"updated_at"
        }

    def itemData(self, id):
        for item in self._items:
            if item["id"] == id:
                return item
        return None

    @pyqtProperty(int)
    def count(self):
        return len(self._items)
