#include "ordersModel.h"

#include "modelUtils.h"

namespace workorder
{

OrdersModel::OrdersModel(QObject *parent)
    : GenericModel<OrderItem>(parent)
{
}

void OrdersModel::updateModelFromMaps(const QVariantList &items)
{
    setItems(itemsFromVariantList<OrderItem>(items, OrderItem::fromMap));
}

QVariantMap OrdersModel::itemData(qint64 startOrderAt) const
{
    for(const OrderItem &item : getItems())
    {
        if(item.startOrderAt == startOrderAt)
            return item.toMap();
    }
    return {};
}

} // namespace workorder
