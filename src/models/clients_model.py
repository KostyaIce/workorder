from PyQt6.QtCore import (
    Qt,
    QAbstractListModel,
    QModelIndex,
    pyqtProperty
)

class ClientModel(QAbstractListModel):

    NameRole = Qt.ItemDataRole.UserRole + 1
    KindRole = Qt.ItemDataRole.UserRole + 2
    IdRole = Qt.ItemDataRole.UserRole + 3
    ContactRole = Qt.ItemDataRole.UserRole + 4
    AddressRole = Qt.ItemDataRole.UserRole + 5
    NotesRole = Qt.ItemDataRole.UserRole + 6
    CreatedRole = Qt.ItemDataRole.UserRole + 7

    def __init__(self):
        super().__init__()
        self._items = []

    def updateModel(self, items):
        self.beginResetModel()
        self._items = items
        self.endResetModel()


    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    @pyqtProperty(int)
    def count(self):
        return len(self._items)

    def data(self, index, role):

        if not index.isValid():
            return None

        item = self._items[index.row()]

        if role == self.NameRole:
            return item["name"]

        if role == self.KindRole:
            return item["kind"]

        if role == self.IdRole:
            return item["id"]

        if role == self.ContactRole:
            return item["contact_info"]

        if role == self.AddressRole:
            return item["address"]

        if role == self.NotesRole:
            return item["notes"]

        if role == self.CreatedRole:
            return item["created_at"]

        return None

    def roleNames(self):
        return {
            self.NameRole: b"name",
            self.KindRole: b"kind",
            self.IdRole: b"id",
            self.ContactRole: b"contact_info",
            self.AddressRole: b"address",
            self.NotesRole: b"notes",
            self.CreatedRole: b"created_at"
        }

    def itemData(self, id):
        for item in self._items:
            if item["id"] == id:
                return item
        return None