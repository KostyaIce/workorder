#ifndef WORKORDER_MODELS_SERVICE_ITEM_H
#define WORKORDER_MODELS_SERVICE_ITEM_H

#include "GenericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct ServiceItem : public GenericItem
{
    QString id;
    QString name;
    QString note;
    QString paragraph;
    int price = 0;
    QString unit;
    QString keywords;
    QString createdAt;
    QString updatedAt;

    static ServiceItem fromMap(const QVariantMap &map)
    {
        ServiceItem item;
        item.id = map.value("id").toString();
        item.name = map.value("name").toString();
        item.note = map.value("note").toString();
        item.paragraph = map.value("paragraph").toString();
        item.price = map.value("price").toInt();
        item.unit = map.value("unit").toString();
        item.keywords = map.value("keywords").toString();
        item.createdAt = map.value("created_at").toString();
        item.updatedAt = map.value("updated_at").toString();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("id", id);
        map.insert("name", name);
        map.insert("note", note);
        map.insert("paragraph", paragraph);
        map.insert("price", price);
        map.insert("unit", unit);
        map.insert("keywords", keywords);
        map.insert("created_at", createdAt);
        map.insert("updated_at", updatedAt);
        return map;
    }

    bool operator==(const ServiceItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const ServiceItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("id", &ServiceItem::id),
            std::make_pair("name", &ServiceItem::name),
            std::make_pair("note", &ServiceItem::note),
            std::make_pair("paragraph", &ServiceItem::paragraph),
            std::make_pair("price", &ServiceItem::price),
            std::make_pair("unit", &ServiceItem::unit),
            std::make_pair("keywords", &ServiceItem::keywords),
            std::make_pair("created_at", &ServiceItem::createdAt),
            std::make_pair("updated_at", &ServiceItem::updatedAt)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<ServiceItem *>(this), fieldName, value);
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

Q_DECLARE_METATYPE(workorder::ServiceItem)

#endif // WORKORDER_MODELS_SERVICE_ITEM_H
