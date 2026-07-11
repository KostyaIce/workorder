#ifndef WORKORDER_MODELS_ORDERS_MODEL_H
#define WORKORDER_MODELS_ORDERS_MODEL_H

#include "genericModel.h"
#include "items/orderItem.h"

namespace workorder
{

class OrdersModel : public GenericModel<OrderItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        StartOrderAtRole = Qt::UserRole + 1,
        TotalPriceRole = Qt::UserRole + 2
    };

    explicit OrdersModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE QVariantMap itemData(qint64 startOrderAt) const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_ORDERS_MODEL_H
