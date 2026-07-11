#include "subobjectsModel.h"

#include <QSet>

#include <algorithm>

namespace workorder
{

SubobjectsModel::SubobjectsModel(QObject *parent)
    : GenericModel<SubobjectItem>(parent)
{
}

void SubobjectsModel::updateModelFromNames(const QStringList &names)
{
    QStringList uniqueNames;
    QSet<QString> seen;
    for(const QString &name : names)
    {
        const QString value = name.trimmed();
        if(value.isEmpty())
            continue;

        const QString key = value.toCaseFolded();
        if(seen.contains(key))
            continue;

        seen.insert(key);
        uniqueNames.append(value);
    }

    std::sort(uniqueNames.begin(), uniqueNames.end(),
              [](const QString &left, const QString &right)
              {
                  return left.compare(right, Qt::CaseInsensitive) < 0;
              });

    QList<SubobjectItem> items;
    items.reserve(uniqueNames.size());
    for(const QString &name : uniqueNames)
    {
        SubobjectItem item;
        item.name = name;
        items.append(item);
    }

    setItems(items);
}

bool SubobjectsModel::addItem(const QString &name)
{
    const QString value = name.trimmed();
    if(value.isEmpty())
        return false;

    for(const SubobjectItem &item : getItems())
    {
        if(item.name.compare(value, Qt::CaseInsensitive) == 0)
            return false;
    }

    SubobjectItem item;
    item.name = value;
    add(item);
    return true;
}

} // namespace workorder
