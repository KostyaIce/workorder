from PyQt6.QtCore import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty,
)


class OrdersModel(QAbstractListModel):

    StartOrderAtRole = Qt.ItemDataRole.UserRole + 1
    TotalPriceRole = Qt.ItemDataRole.UserRole + 2

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

        if role == self.StartOrderAtRole:
            return item["start_order_at"]

        if role == self.TotalPriceRole:
            return item["total_price"]

        return None

    def roleNames(self):
        return {
            self.StartOrderAtRole: b"start_order_at",
            self.TotalPriceRole: b"total_price",
        }

    def itemData(self, start_order_at):
        for item in self._items:
            if item["start_order_at"] == start_order_at:
                return item
        return None

    @pyqtProperty(int)
    def count(self):
        return len(self._items)
