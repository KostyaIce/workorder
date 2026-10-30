#ifndef WORKORDER_MODELS_COEFFICIENT_ITEM_H
#define WORKORDER_MODELS_COEFFICIENT_ITEM_H

#include "GenericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

// A catalog coefficient. `price` keeps the legacy encoding used by services:
// percent * 100, so 150% is stored as 15000.
struct CoefficientItem : public GenericItem
{
    QString id;
    QString name;
    int price = 0;
    QString unit = QStringLiteral("%");
    QString keywords;
    QString createdAt;
    QString updatedAt;

    static CoefficientItem fromMap(const QVariantMap &map)
    {
        CoefficientItem item;
        item.id = map.value("id").toString();
        item.name = map.value("name").toString();
        item.price = map.value("price").toInt();
        item.unit = map.value("unit").toString();
        if(item.unit.isEmpty())
            item.unit = QStringLiteral("%");
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
        map.insert("price", price);
        map.insert("unit", unit);
        map.insert("keywords", keywords);
        map.insert("created_at", createdAt);
        map.insert("updated_at", updatedAt);
        return map;
    }

    bool operator==(const CoefficientItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const CoefficientItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("id", &CoefficientItem::id),
            std::make_pair("name", &CoefficientItem::name),
            std::make_pair("price", &CoefficientItem::price),
            std::make_pair("unit", &CoefficientItem::unit),
            std::make_pair("keywords", &CoefficientItem::keywords),
            std::make_pair("created_at", &CoefficientItem::createdAt),
            std::make_pair("updated_at", &CoefficientItem::updatedAt)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<CoefficientItem *>(this), fieldName, value);
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

Q_DECLARE_METATYPE(workorder::CoefficientItem)

#endif // WORKORDER_MODELS_COEFFICIENT_ITEM_H
