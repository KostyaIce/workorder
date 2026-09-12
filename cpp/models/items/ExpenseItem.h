#ifndef WORKORDER_MODELS_EXPENSE_ITEM_H
#define WORKORDER_MODELS_EXPENSE_ITEM_H

#include "GenericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct ExpenseItem : public GenericItem
{
    QString id;
    QString objectId;
    qint64 startOrderAt = 0;
    QString description;
    int amount = 0;
    qint64 createdAt = 0;
    qint64 updatedAt = 0;

    static ExpenseItem fromMap(const QVariantMap &map)
    {
        ExpenseItem item;
        item.id = map.value("id").toString();
        item.objectId = map.value("object_id").toString();
        item.startOrderAt = map.value("start_order_at").toLongLong();
        item.description = map.value("description").toString();
        item.amount = map.value("amount").toInt();
        item.createdAt = map.value("created_at").toLongLong();
        item.updatedAt = map.value("updated_at").toLongLong();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("id", id);
        map.insert("object_id", objectId);
        map.insert("start_order_at", startOrderAt);
        map.insert("description", description);
        map.insert("amount", amount);
        map.insert("created_at", createdAt);
        map.insert("updated_at", updatedAt);
        return map;
    }

    bool operator==(const ExpenseItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const ExpenseItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("id", &ExpenseItem::id),
            std::make_pair("object_id", &ExpenseItem::objectId),
            std::make_pair("start_order_at", &ExpenseItem::startOrderAt),
            std::make_pair("description", &ExpenseItem::description),
            std::make_pair("amount", &ExpenseItem::amount),
            std::make_pair("created_at", &ExpenseItem::createdAt),
            std::make_pair("updated_at", &ExpenseItem::updatedAt)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<ExpenseItem *>(this), fieldName, value);
    }

    size_t getFieldCount() const override
    {
        return std::tuple_size_v<decltype(fields())>;
    }

    size_t hashCode() const override
    {
        return qHash(id);
    }
};

} // namespace workorder

Q_DECLARE_METATYPE(workorder::ExpenseItem)

#endif // WORKORDER_MODELS_EXPENSE_ITEM_H
