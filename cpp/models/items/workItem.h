#ifndef WORKORDER_MODELS_WORK_ITEM_H
#define WORKORDER_MODELS_WORK_ITEM_H

#include "genericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct WorkItem : public GenericItem
{
    QString id;
    QString objectId;
    QString serviceId;
    QString subobjectName;
    QString name;
    int price = 0;
    QString unit;
    double quantity = 1.0;
    qint64 createdAt = 0;
    qint64 updatedAt = 0;
    qint64 startOrderAt = 0;
    QString coefficients;
    int percentSum = 100;

    static WorkItem fromMap(const QVariantMap &map)
    {
        WorkItem item;
        item.id = map.value("id").toString();
        item.objectId = map.value("object_id").toString();
        item.serviceId = map.value("service_id").toString();
        item.subobjectName = map.value("subobject_name").toString();
        item.name = map.value("name").toString();
        item.price = map.value("price").toInt();
        item.unit = map.value("unit").toString();
        item.quantity = map.value("quantity", 1).toDouble();
        item.createdAt = map.value("created_at").toLongLong();
        item.updatedAt = map.value("updated_at").toLongLong();
        item.startOrderAt = map.value("start_order_at").toLongLong();
        item.coefficients = map.value("coefficients").toString();
        item.percentSum = map.value("percent_sum", 100).toInt();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("id", id);
        map.insert("object_id", objectId);
        map.insert("service_id", serviceId);
        map.insert("subobject_name", subobjectName);
        map.insert("name", name);
        map.insert("price", price);
        map.insert("unit", unit);
        map.insert("quantity", quantity);
        map.insert("created_at", createdAt);
        map.insert("updated_at", updatedAt);
        map.insert("start_order_at", startOrderAt);
        map.insert("coefficients", coefficients);
        map.insert("percent_sum", percentSum);
        return map;
    }

    bool operator==(const WorkItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const WorkItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("id", &WorkItem::id),
            std::make_pair("object_id", &WorkItem::objectId),
            std::make_pair("service_id", &WorkItem::serviceId),
            std::make_pair("subobject_name", &WorkItem::subobjectName),
            std::make_pair("name", &WorkItem::name),
            std::make_pair("price", &WorkItem::price),
            std::make_pair("unit", &WorkItem::unit),
            std::make_pair("quantity", &WorkItem::quantity),
            std::make_pair("created_at", &WorkItem::createdAt),
            std::make_pair("updated_at", &WorkItem::updatedAt),
            std::make_pair("start_order_at", &WorkItem::startOrderAt),
            std::make_pair("coefficients", &WorkItem::coefficients),
            std::make_pair("percent_sum", &WorkItem::percentSum)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<WorkItem *>(this), fieldName, value);
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

Q_DECLARE_METATYPE(workorder::WorkItem)

#endif // WORKORDER_MODELS_WORK_ITEM_H
