#ifndef WORKORDER_GENERIC_MODEL_H
#define WORKORDER_GENERIC_MODEL_H

#include "genericItem.h"
#include "genericModelBase.h"

#include <QByteArray>
#include <QHash>
#include <QMetaType>
#include <QVariant>

#include <functional>
#include <algorithm>
#include <tuple>
#include <type_traits>
#include <type_traits>

namespace workorder
{

template<size_t... I>
int getFieldIdHelper(const auto &fields, const QString &fieldName, std::index_sequence<I...>)
{
    int result = -1;
    ((QLatin1String(std::get<I>(fields).first) == fieldName ? (result = static_cast<int>(I), true) : false) || ...);
    return result;
}

template<typename ItemStruct>
class GenericBridge : public GenericBridgeBase
{
    template<typename T>
    friend class GenericModel;

protected:
    struct Data
    {
        ItemStruct item;
        GenericBridge *bridge = nullptr;
    };

protected:
    Data *d = nullptr;

protected:
    explicit GenericBridge(Data *data)
        : d(data)
    {
        if(d)
            d->bridge = this;
    }

public:
    explicit GenericBridge(QObject *parent = nullptr)
        : GenericBridgeBase(parent)
        , d(new Data())
    {
        d->bridge = this;
    }

    GenericBridge(const GenericBridge &src)
        : GenericBridgeBase(src.parent())
        , d(new Data(*src.d))
    {
        d->bridge = this;
    }

    GenericBridge(GenericBridge &&src)
        : GenericBridgeBase(src.parent())
        , d(src.d)
    {
        src.d = nullptr;
        if(d)
            d->bridge = this;
    }

    ~GenericBridge() override
    {
        delete d;
    }

    Q_INVOKABLE QVariant getValue(const QString &fieldName) const
    {
        if(!d)
            return {};
        return getFieldValue(d->item, fieldName);
    }

    Q_INVOKABLE void setValue(const QString &fieldName, const QVariant &value)
    {
        if(!d)
            return;
        if(setFieldValue(d->item, fieldName, value))
            emit valueChanged(fieldName);
    }

    QVariant operator[](const QString &fieldName) const
    {
        return getValue(fieldName);
    }

    GenericBridge &operator=(const GenericBridge &src)
    {
        if(this != &src)
        {
            delete d;
            d = new Data(*src.d);
            d->bridge = this;
        }
        return *this;
    }

    GenericBridge &operator=(GenericBridge &&src)
    {
        if(this != &src)
        {
            delete d;
            d = src.d;
            src.d = nullptr;
            if(d)
                d->bridge = this;
        }
        return *this;
    }

private:
    static QVariant getFieldValue(const ItemStruct &item, const QString &fieldName)
    {
        return item.getFieldValue(fieldName);
    }

    static bool setFieldValue(ItemStruct &item, const QString &fieldName, const QVariant &value)
    {
        return item.setFieldValue(fieldName, value);
    }
};

template<typename ItemStruct>
class GenericModel : public GenericModelBase
{
public:
    using Item = ItemStruct;
    using Bridge = GenericBridge<ItemStruct>;

    explicit GenericModel(QObject *parent = nullptr)
        : GenericModelBase(parent)
    {
        setupRoleNames();
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override
    {
        if(parent.isValid())
            return 0;
        return m_items.size();
    }

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override
    {
        if(!index.isValid() || index.row() >= m_items.size())
            return {};

        return getFieldValueByRole(m_items.at(index.row()), role);
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return m_roleNames;
    }

    void clear() override
    {
        beginResetModel();
        m_items.clear();
        endResetModel();
        emit sizeChanged();
    }

    bool isEmpty() const override
    {
        return m_items.isEmpty();
    }

    int size() const override
    {
        return m_items.size();
    }

    int count() const override
    {
        return m_items.size();
    }

    bool updateModel(const QList<Item> &newItems)
    {
        if(newItems.isEmpty())
        {
            if(!m_items.isEmpty())
                clear();
            return true;
        }

        if(m_items.isEmpty())
        {
            beginInsertRows(QModelIndex(), 0, newItems.size() - 1);
            m_items = newItems;
            endInsertRows();
            emit sizeChanged();
            emit sigSizeChanged(m_items.size());
            return true;
        }

        for(int i = m_items.size() - 1; i >= 0; --i)
        {
            if(!newItems.contains(m_items.at(i)))
                remove(i);
        }

        for(int targetIdx = 0; targetIdx < newItems.size(); ++targetIdx)
        {
            const Item &newItem = newItems.at(targetIdx);
            const int currentIdx = m_items.indexOf(newItem);
            if(currentIdx < 0)
            {
                insert(targetIdx, newItem);
            }
            else
            {
                set(currentIdx, newItem);
                if(currentIdx != targetIdx)
                {
                    const Item moving = m_items.at(currentIdx);
                    remove(currentIdx);
                    insert(targetIdx, moving);
                }
            }
        }

        emit sizeChanged();
        emit sigSizeChanged(m_items.size());
        return true;
    }

    bool softUpdate(const QList<Item> &newItems)
    {
        if(m_items.size() == newItems.size() && !m_items.isEmpty())
        {
            emit layoutAboutToBeChanged();
            m_items = newItems;
            emit layoutChanged();
            return true;
        }

        beginResetModel();
        m_items = newItems;
        endResetModel();
        emit sizeChanged();
        emit sigSizeChanged(m_items.size());
        return true;
    }

    int add(const Item &item)
    {
        const int index = m_items.size();
        beginInsertRows(QModelIndex(), index, index);
        m_items.append(item);
        endInsertRows();
        emit sizeChanged();
        return index;
    }

    void insert(int index, const Item &item)
    {
        if(index < 0 || index > m_items.size())
            return;

        beginInsertRows(QModelIndex(), index, index);
        m_items.insert(index, item);
        endInsertRows();
        emit sizeChanged();
    }

    void remove(int index)
    {
        if(index < 0 || index >= m_items.size())
            return;

        beginRemoveRows(QModelIndex(), index, index);
        m_items.removeAt(index);
        endRemoveRows();
        emit sizeChanged();
    }

    void setItems(const QList<Item> &items)
    {
        beginResetModel();
        m_items = items;
        endResetModel();
        emit sizeChanged();
        emit sigSizeChanged(m_items.size());
    }

    const Item &at(int index) const
    {
        return m_items.at(index);
    }

    Item value(int index) const
    {
        if(index < 0 || index >= m_items.size())
            return Item{};
        return m_items.at(index);
    }

    QVariant get(int index) override
    {
        if(index < 0 || index >= m_items.size())
            return {};
        return QVariant::fromValue(m_items.at(index));
    }

    QVariant get(int index) const override
    {
        if(index < 0 || index >= m_items.size())
            return {};
        return QVariant::fromValue(m_items.at(index));
    }

    QVariantMap getObject(int index) const override
    {
        if(index < 0 || index >= m_items.size())
            return {};

        QVariantMap result;
        extractFieldsToMap(m_items.at(index), ItemStruct::fields(), result);
        return result;
    }

    void set(int index, const Item &item)
    {
        if(index < 0 || index >= m_items.size())
            return;

        m_items[index] = item;
        const QModelIndex modelIndex = this->index(index);
        emit dataChanged(modelIndex, modelIndex);
        emit sigItemChanged(index);
    }

    int indexOf(const Item &item) const
    {
        return m_items.indexOf(item);
    }

    int fieldId(const QString &fieldName) const
    {
        const auto fields = FieldExtractor<ItemStruct>::getFields();
        return getFieldIdHelper(fields, fieldName,
                                std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fields)>>>{});
    }

    static int roleForField(const QString &fieldName)
    {
        const auto fields = FieldExtractor<ItemStruct>::getFields();
        const int id = getFieldIdHelper(fields, fieldName,
                                        std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fields)>>>{});
        return id < 0 ? -1 : Qt::UserRole + 1 + id;
    }

    const QList<Item> &getItems() const
    {
        return m_items;
    }

    QList<Item> getItemsCopy() const
    {
        return m_items;
    }

    void sortByField(const QString &fieldName, bool ascending = true)
    {
        if(m_items.isEmpty())
            return;

        beginResetModel();
        std::sort(m_items.begin(), m_items.end(),
                  [fieldName, ascending](const Item &a, const Item &b)
                  {
                      const QVariant valueA = a.getFieldValue(fieldName);
                      const QVariant valueB = b.getFieldValue(fieldName);
                      if(valueA.typeId() == QMetaType::QString && valueB.typeId() == QMetaType::QString)
                      {
                          const QString strA = valueA.toString().toLower();
                          const QString strB = valueB.toString().toLower();
                          return ascending ? (strA < strB) : (strB < strA);
                      }
                      if(valueA.canConvert<double>() && valueB.canConvert<double>())
                          return ascending ? (valueA.toDouble() < valueB.toDouble())
                                           : (valueB.toDouble() < valueA.toDouble());
                      const QString strA = valueA.toString().toLower();
                      const QString strB = valueB.toString().toLower();
                      return ascending ? (strA < strB) : (strB < strA);
                  });
        endResetModel();
        emit dataChanged(index(0), index(m_items.size() - 1));
    }

protected:
    QList<Item> m_items;
    QHash<int, QByteArray> m_roleNames;

private:
    void setupRoleNames()
    {
        const auto fields = FieldExtractor<ItemStruct>::getFields();
        setupRoleNamesHelper(fields,
                             std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fields)>>>{});
    }

    template<size_t... I>
    void setupRoleNamesHelper(const auto &fields, std::index_sequence<I...>)
    {
        m_roleNames.clear();
        m_roleNames[Qt::DisplayRole] = "display";
        ((m_roleNames[Qt::UserRole + 1 + I] = std::get<I>(fields).first), ...);
    }

    QVariant getFieldValueByRole(const Item &item, int role) const
    {
        if(role == Qt::DisplayRole)
        {
            const auto fields = FieldExtractor<ItemStruct>::getFields();
            if constexpr(std::tuple_size_v<std::decay_t<decltype(fields)>> > 0)
                return item.getFieldValue(QLatin1String(std::get<0>(fields).first));
            return {};
        }

        if(role >= Qt::UserRole + 1)
        {
            const int fieldIndex = role - (Qt::UserRole + 1);
            const auto fields = FieldExtractor<ItemStruct>::getFields();
            if(fieldIndex >= 0
                && fieldIndex < static_cast<int>(std::tuple_size_v<std::decay_t<decltype(fields)>>))
            {
                return item.getFieldValue(getFieldNameByIndex(fields, fieldIndex));
            }
        }

        return {};
    }

    QString getFieldNameByIndex(const auto &fields, int index) const
    {
        return getFieldNameByIndexHelper(fields, index,
                                         std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fields)>>>{});
    }

    template<size_t... I>
    QString getFieldNameByIndexHelper(const auto &fields, int index, std::index_sequence<I...>) const
    {
        QString result;
        ((static_cast<int>(I) == index ? (result = QLatin1String(std::get<I>(fields).first), true) : false) || ...);
        return result;
    }

    template<size_t... I>
    void extractFieldsToMap(const Item &item, const auto &fields, QVariantMap &result,
                            std::index_sequence<I...>) const
    {
        ((result[QLatin1String(std::get<I>(fields).first)] = item.getFieldValue(QLatin1String(std::get<I>(fields).first))), ...);
    }

    void extractFieldsToMap(const Item &item, const auto &fields, QVariantMap &result) const
    {
        extractFieldsToMap(item, fields, result,
                           std::make_index_sequence<std::tuple_size_v<std::decay_t<decltype(fields)>>>{});
    }
};

} // namespace workorder

#endif // WORKORDER_GENERIC_MODEL_H
