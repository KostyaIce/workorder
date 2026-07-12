#ifndef WORKORDER_MODELS_MODEL_UTILS_H
#define WORKORDER_MODELS_MODEL_UTILS_H

#include <QVariantList>
#include <QVariantMap>

namespace workorder
{

template<typename Item, typename FromMapFn>
QList<Item> itemsFromVariantList(const QVariantList &source, FromMapFn fromMap)
{
    QList<Item> items;
    items.reserve(source.size());
    for(const QVariant &value : source)
        items.append(fromMap(value.toMap()));
    return items;
}

template<typename Item>
QVariantList variantListFromItems(const QList<Item> &items)
{
    QVariantList result;
    result.reserve(items.size());
    for(const Item &item : items)
        result.append(item.toMap());
    return result;
}

} // namespace workorder

#endif // WORKORDER_MODELS_MODEL_UTILS_H
