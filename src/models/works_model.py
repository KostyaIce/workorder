from PyQt6.QtCore import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty
)


class WorksModel(QAbstractListModel):

    IdRole = Qt.ItemDataRole.UserRole + 1
    ObjectIdRole = Qt.ItemDataRole.UserRole + 2
    ServiceIdRole = Qt.ItemDataRole.UserRole + 3
    SubobjectNameRole = Qt.ItemDataRole.UserRole + 4
    NameRole = Qt.ItemDataRole.UserRole + 5
    PriceRole = Qt.ItemDataRole.UserRole + 6
    UnitRole = Qt.ItemDataRole.UserRole + 7
    QuantityRole = Qt.ItemDataRole.UserRole + 8
    CreatedAtRole = Qt.ItemDataRole.UserRole + 9
    UpdatedAtRole = Qt.ItemDataRole.UserRole + 10
    StartOrderAtRole = Qt.ItemDataRole.UserRole + 11

    def __init__(self):
        super().__init__()
        self._items = []

    def updateModel(self, items):
        self.beginResetModel()
        self._items = items
        self.endResetModel()

    def clearModel(self):
        self.beginResetModel()
        self._items = []
        self.endResetModel()

    def addItem(self, item):
        if not item:
            return False

        self.beginInsertRows(QModelIndex(), 0, 0)
        self._items.insert(0, item)
        self.endInsertRows()
        return True

    def updateItem(self, item):
        work_id = item.get("id")
        if not work_id:
            return False

        for index, existing in enumerate(self._items):
            if existing["id"] != work_id:
                continue

            updated = existing.copy()
            updated.update(item)
            self._items[index] = updated
            model_index = self.index(index)
            self.dataChanged.emit(model_index, model_index)
            return True

        return False

    def removeItem(self, work_id):
        if not work_id:
            return False

        for index, item in enumerate(self._items):
            if item["id"] != work_id:
                continue

            self.beginRemoveRows(QModelIndex(), index, index)
            del self._items[index]
            self.endRemoveRows()
            return True

        return False

    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    def data(self, index, role):
        if not index.isValid():
            return None

        item = self._items[index.row()]

        if role == self.IdRole:
            return item["id"]

        if role == self.ObjectIdRole:
            return item["object_id"]

        if role == self.ServiceIdRole:
            return item["service_id"]

        if role == self.SubobjectNameRole:
            return item["subobject_name"]

        if role == self.NameRole:
            return item["name"]

        if role == self.PriceRole:
            return item["price"]

        if role == self.UnitRole:
            return item["unit"]

        if role == self.QuantityRole:
            return item["quantity"]

        if role == self.CreatedAtRole:
            return item["created_at"]

        if role == self.UpdatedAtRole:
            return item["updated_at"]

        if role == self.StartOrderAtRole:
            return item["start_order_at"]

        return None

    def roleNames(self):
        return {
            self.IdRole: b"id",
            self.ObjectIdRole: b"object_id",
            self.ServiceIdRole: b"service_id",
            self.SubobjectNameRole: b"subobject_name",
            self.NameRole: b"name",
            self.PriceRole: b"price",
            self.UnitRole: b"unit",
            self.QuantityRole: b"quantity",
            self.CreatedAtRole: b"created_at",
            self.UpdatedAtRole: b"updated_at",
            self.StartOrderAtRole: b"start_order_at",
        }

    def itemData(self, work_id):
        for item in self._items:
            if item["id"] == work_id:
                return item
        return None

    def items(self):
        return [item.copy() for item in self._items]

    @pyqtProperty(int)
    def count(self):
        return len(self._items)
