#ifndef WORKORDER_MODELS_OBJECT_ITEM_H
#define WORKORDER_MODELS_OBJECT_ITEM_H

#include "genericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct ObjectItem : public GenericItem
{
    QString id;
    QString name;
    QString address;
    qint64 updatedAt = 0;
    qint64 lastOrderAt = 0;

    static ObjectItem fromMap(const QVariantMap &map)
    {
        ObjectItem item;
        item.id = map.value("id").toString();
        item.name = map.value("name").toString();
        item.address = map.value("address").toString();
        item.updatedAt = map.value("updated_at").toLongLong();
        item.lastOrderAt = map.value("last_order_at").toLongLong();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("id", id);
        map.insert("name", name);
        map.insert("address", address);
        map.insert("updated_at", updatedAt);
        map.insert("last_order_at", lastOrderAt);
        return map;
    }

    bool operator==(const ObjectItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const ObjectItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("id", &ObjectItem::id),
            std::make_pair("name", &ObjectItem::name),
            std::make_pair("address", &ObjectItem::address),
            std::make_pair("updated_at", &ObjectItem::updatedAt),
            std::make_pair("last_order_at", &ObjectItem::lastOrderAt)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<ObjectItem *>(this), fieldName, value);
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

Q_DECLARE_METATYPE(workorder::ObjectItem)

#endif // WORKORDER_MODELS_OBJECT_ITEM_H
