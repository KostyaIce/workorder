#include "objectsModel.h"

#include "modelUtils.h"

namespace workorder
{

ObjectsModel::ObjectsModel(QObject *parent)
    : GenericModel<ObjectItem>(parent)
{
}

void ObjectsModel::updateModelFromMaps(const QVariantList &items)
{
    setItems(itemsFromVariantList<ObjectItem>(items, ObjectItem::fromMap));
}

QVariantMap ObjectsModel::itemData(const QString &id) const
{
    for(const ObjectItem &item : getItems())
    {
        if(item.id == id)
            return item.toMap();
    }
    return {};
}

} // namespace workorder
