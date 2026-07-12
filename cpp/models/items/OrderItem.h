#ifndef WORKORDER_MODELS_ORDER_ITEM_H
#define WORKORDER_MODELS_ORDER_ITEM_H

#include "GenericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct OrderItem : public GenericItem
{
    qint64 startOrderAt = 0;
    double totalPrice = 0.0;

    static OrderItem fromMap(const QVariantMap &map)
    {
        OrderItem item;
        item.startOrderAt = map.value("start_order_at").toLongLong();
        item.totalPrice = map.value("total_price").toDouble();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("start_order_at", startOrderAt);
        map.insert("total_price", totalPrice);
        return map;
    }

    bool operator==(const OrderItem &other) const
    {
        return startOrderAt == other.startOrderAt;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const OrderItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("start_order_at", &OrderItem::startOrderAt),
            std::make_pair("total_price", &OrderItem::totalPrice)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<OrderItem *>(this), fieldName, value);
    }

    size_t getFieldCount() const override
    {
        return std::tuple_size_v<decltype(fields())>;
    }

    size_t hashCode() const override
    {
        return ::qHash(static_cast<quint64>(startOrderAt));
    }
};

} // namespace workorder

Q_DECLARE_METATYPE(workorder::OrderItem)

#endif // WORKORDER_MODELS_ORDER_ITEM_H
