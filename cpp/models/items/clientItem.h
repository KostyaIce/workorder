#ifndef WORKORDER_MODELS_CLIENT_ITEM_H
#define WORKORDER_MODELS_CLIENT_ITEM_H

#include "genericItem.h"

#include <QMetaType>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

struct ClientItem : public GenericItem
{
    QString name;
    QString kind;
    QString id;
    QString contactInfo;
    QString address;
    QString notes;
    QString createdAt;

    static ClientItem fromMap(const QVariantMap &map)
    {
        ClientItem item;
        item.name = map.value("name").toString();
        item.kind = map.value("kind").toString();
        item.id = map.value("id").toString();
        item.contactInfo = map.value("contact_info").toString();
        item.address = map.value("address").toString();
        item.notes = map.value("notes").toString();
        item.createdAt = map.value("created_at").toString();
        return item;
    }

    QVariantMap toMap() const
    {
        QVariantMap map;
        map.insert("name", name);
        map.insert("kind", kind);
        map.insert("id", id);
        map.insert("contact_info", contactInfo);
        map.insert("address", address);
        map.insert("notes", notes);
        map.insert("created_at", createdAt);
        return map;
    }

    bool operator==(const ClientItem &other) const
    {
        return id == other.id;
    }

    bool operator==(const GenericItem &other) const override
    {
        const auto *otherItem = dynamic_cast<const ClientItem *>(&other);
        if(!otherItem)
            return false;
        return *this == *otherItem;
    }

    static constexpr auto fields()
    {
        return std::make_tuple(
            std::make_pair("name", &ClientItem::name),
            std::make_pair("kind", &ClientItem::kind),
            std::make_pair("id", &ClientItem::id),
            std::make_pair("contact_info", &ClientItem::contactInfo),
            std::make_pair("address", &ClientItem::address),
            std::make_pair("notes", &ClientItem::notes),
            std::make_pair("created_at", &ClientItem::createdAt)
        );
    }

    QVariant getFieldValue(const QString &fieldName) const override
    {
        return workorder::getFieldValue(*this, fieldName);
    }

    bool setFieldValue(const QString &fieldName, const QVariant &value) override
    {
        return workorder::setFieldValue(*const_cast<ClientItem *>(this), fieldName, value);
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

Q_DECLARE_METATYPE(workorder::ClientItem)

#endif // WORKORDER_MODELS_CLIENT_ITEM_H
