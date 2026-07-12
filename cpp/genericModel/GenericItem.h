#ifndef WORKORDER_GENERIC_ITEM_H
#define WORKORDER_GENERIC_ITEM_H

#include <QHashFunctions>
#include <QMetaType>
#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>

#include <tuple>

namespace workorder
{

class GenericItem
{
public:
    virtual ~GenericItem() = default;

    virtual QVariant getFieldValue(const QString &fieldName) const = 0;
    virtual bool setFieldValue(const QString &fieldName, const QVariant &value) = 0;
    virtual size_t getFieldCount() const = 0;
    virtual bool operator==(const GenericItem &other) const = 0;
    virtual size_t hashCode() const
    {
        return 0;
    }
};

inline size_t qHash(const GenericItem &item, size_t seed = 0)
{
    return item.hashCode() ^ seed;
}

inline void setValue(QString &field, const QVariant &value)
{
    field = value.toString();
}

inline void setValue(qint64 &field, const QVariant &value)
{
    field = value.toLongLong();
}

inline void setValue(int &field, const QVariant &value)
{
    field = value.toInt();
}

inline void setValue(bool &field, const QVariant &value)
{
    field = value.toBool();
}

inline void setValue(double &field, const QVariant &value)
{
    field = value.toDouble();
}

inline void setValue(QVariantList &field, const QVariant &value)
{
    field = value.toList();
}

inline void setValue(QVariantMap &field, const QVariant &value)
{
    field = value.toMap();
}

template<typename T>
struct FieldExtractor
{
    static constexpr auto getFields()
    {
        return T::fields();
    }

    static constexpr size_t getFieldCount()
    {
        return std::tuple_size_v<std::decay_t<decltype(T::fields())>>;
    }
};

template<typename T, size_t... I>
QVariant getFieldValueImpl(const T &item, const QString &fieldName,
                           const auto &fieldTuple, std::index_sequence<I...>)
{
    QVariant result;
    ((QLatin1String(std::get<I>(fieldTuple).first) == fieldName
        ? (result = QVariant::fromValue(item.*(std::get<I>(fieldTuple).second)), true)
        : false)
     || ...);
    return result;
}

template<typename T, size_t... I>
bool setFieldValueImpl(T &item, const QString &fieldName, const QVariant &value,
                       const auto &fieldTuple, std::index_sequence<I...>)
{
    bool found = false;
    ((QLatin1String(std::get<I>(fieldTuple).first) == fieldName
        ? (setValue(item.*(std::get<I>(fieldTuple).second), value), found = true)
        : false)
     || ...);
    return found;
}

template<typename T>
QVariant getFieldValue(const T &item, const QString &fieldName)
{
    constexpr auto fieldTuple = T::fields();
    return getFieldValueImpl(item, fieldName, fieldTuple,
                             std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fieldTuple)>>>{});
}

template<typename T>
bool setFieldValue(T &item, const QString &fieldName, const QVariant &value)
{
    constexpr auto fieldTuple = T::fields();
    return setFieldValueImpl(item, fieldName, value, fieldTuple,
                             std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fieldTuple)>>>{});
}

} // namespace workorder

Q_DECLARE_METATYPE(workorder::GenericItem)

#endif // WORKORDER_GENERIC_ITEM_H
