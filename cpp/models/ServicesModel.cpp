#include "ServicesModel.h"

#include "ModelUtils.h"

#include <algorithm>

namespace workorder
{

ServicesModel::ServicesModel(QObject *parent)
    : GenericModel<ServiceItem>(parent)
{
}

void ServicesModel::updateModelFromMaps(const QVariantList &items)
{
    beginResetModel();
    m_items = itemsFromVariantList<ServiceItem>(items, ServiceItem::fromMap);
    std::sort(m_items.begin(), m_items.end(),
              [](const ServiceItem &left, const ServiceItem &right)
              {
                  const QString leftType = left.paragraph.trimmed();
                  const QString rightType = right.paragraph.trimmed();
                  if(leftType.isEmpty() != rightType.isEmpty())
                      return leftType.isEmpty();

                  const int typeComparison = leftType.compare(rightType, Qt::CaseInsensitive);
                  if(typeComparison != 0)
                      return typeComparison < 0;

                  return left.name.compare(right.name, Qt::CaseInsensitive) < 0;
              });
    endResetModel();
    emit sizeChanged();
    emit sigSizeChanged(m_items.size());
}

void ServicesModel::addItem(const QVariantMap &item)
{
    add(ServiceItem::fromMap(item));
}

QVariantMap ServicesModel::itemData(const QString &id) const
{
    for(const ServiceItem &item : getItems())
    {
        if(item.id == id)
            return item.toMap();
    }
    return {};
}

} // namespace workorder
