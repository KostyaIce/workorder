#ifndef WORKORDER_MODELS_SUBOBJECT_ITEM_H
#define WORKORDER_MODELS_SUBOBJECT_ITEM_H

#include "GenericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct SubobjectItem : public GenericItem
{
    QString name;

    static SubobjectItem fromMap(const QVariantMap &map)
    {
        SubobjectItem item;
        item.name = map.value("name").toString();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("name", name);
        return map;
    }

    bool operator==(const SubobjectItem &other) const
    {
        return name.compare(other.name, Qt::CaseInsensitive) == 0;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const SubobjectItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("name", &SubobjectItem::name)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<SubobjectItem *>(this), fieldName, value);
    }

    size_t getFieldCount() const override
    {
        return std::tuple_size_v<decltype(fields())>;
    }

    size_t hashCode() const override
    {
        return qHash(name.toCaseFolded());
    }
};

} // namespace workorder

Q_DECLARE_METATYPE(workorder::SubobjectItem)

#endif // WORKORDER_MODELS_SUBOBJECT_ITEM_H
