#include "CoefficientsModel.h"

#include "ModelUtils.h"

#include <algorithm>

namespace workorder
{

CoefficientsModel::CoefficientsModel(QObject *parent)
    : GenericModel<CoefficientItem>(parent)
{
}

void CoefficientsModel::updateModelFromMaps(const QVariantList &items)
{
    beginResetModel();
    m_items = itemsFromVariantList<CoefficientItem>(items, CoefficientItem::fromMap);
    std::sort(m_items.begin(), m_items.end(),
              [](const CoefficientItem &left, const CoefficientItem &right)
              {
                  return left.name.compare(right.name, Qt::CaseInsensitive) < 0;
              });
    endResetModel();
    emit sizeChanged();
    emit sigSizeChanged(m_items.size());
}

void CoefficientsModel::addItem(const QVariantMap &item)
{
    add(CoefficientItem::fromMap(item));
}

bool CoefficientsModel::removeItem(const QString &id)
{
    if(id.isEmpty())
        return false;

    for(int index = 0; index < m_items.size(); ++index)
    {
        if(m_items.at(index).id != id)
            continue;

        beginRemoveRows(QModelIndex(), index, index);
        m_items.removeAt(index);
        endRemoveRows();
        emit sizeChanged();
        emit sigSizeChanged(m_items.size());
        return true;
    }

    return false;
}

QVariantMap CoefficientsModel::itemData(const QString &id) const
{
    for(const CoefficientItem &item : getItems())
    {
        if(item.id == id)
            return item.toMap();
    }
    return {};
}

} // namespace workorder
