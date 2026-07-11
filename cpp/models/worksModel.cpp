#include "worksModel.h"

#include "modelUtils.h"

namespace workorder
{

WorksModel::WorksModel(QObject *parent)
    : GenericModel<WorkItem>(parent)
{
}

void WorksModel::updateModelFromMaps(const QVariantList &items)
{
    setItems(itemsFromVariantList<WorkItem>(items, WorkItem::fromMap));
}

void WorksModel::clearModel()
{
    clear();
}

bool WorksModel::addItem(const QVariantMap &item)
{
    if(item.isEmpty())
        return false;

    beginInsertRows(QModelIndex(), 0, 0);
    m_items.insert(0, WorkItem::fromMap(item));
    endInsertRows();
    emit sizeChanged();
    return true;
}

bool WorksModel::updateItem(const QVariantMap &item)
{
    const QString workId = item.value("id").toString();
    if(workId.isEmpty())
        return false;

    for(int index = 0; index < m_items.size(); ++index)
    {
        if(m_items.at(index).id != workId)
            continue;

        WorkItem updated = m_items.at(index);
        const QVariantMap merged = updated.toMap();
        for(auto it = item.constBegin(); it != item.constEnd(); ++it)
        {
            if(it.key() == "object_id")
                updated.objectId = it.value().toString();
            else if(it.key() == "service_id")
                updated.serviceId = it.value().toString();
            else if(it.key() == "subobject_name")
                updated.subobjectName = it.value().toString();
            else if(it.key() == "name")
                updated.name = it.value().toString();
            else if(it.key() == "price")
                updated.price = it.value().toInt();
            else if(it.key() == "unit")
                updated.unit = it.value().toString();
            else if(it.key() == "quantity")
                updated.quantity = it.value().toDouble();
            else if(it.key() == "created_at")
                updated.createdAt = it.value().toLongLong();
            else if(it.key() == "updated_at")
                updated.updatedAt = it.value().toLongLong();
            else if(it.key() == "start_order_at")
                updated.startOrderAt = it.value().toLongLong();
            else if(it.key() == "coefficients")
                updated.coefficients = it.value().toString();
            else if(it.key() == "percent_sum")
                updated.percentSum = it.value().toInt();
        }
        Q_UNUSED(merged);

        m_items[index] = updated;
        const QModelIndex modelIndex = this->index(index);
        emit dataChanged(modelIndex, modelIndex);
        emit sigItemChanged(index);
        return true;
    }

    return false;
}

bool WorksModel::removeItem(const QString &workId)
{
    if(workId.isEmpty())
        return false;

    for(int index = 0; index < m_items.size(); ++index)
    {
        if(m_items.at(index).id != workId)
            continue;

        beginRemoveRows(QModelIndex(), index, index);
        m_items.removeAt(index);
        endRemoveRows();
        emit sizeChanged();
        return true;
    }

    return false;
}

QVariantMap WorksModel::itemData(const QString &workId) const
{
    for(const WorkItem &item : getItems())
    {
        if(item.id == workId)
            return item.toMap();
    }
    return {};
}

QVariantList WorksModel::items() const
{
    return variantListFromItems(getItems());
}

} // namespace workorder
