#include "CoefficientsFilterModel.h"

#include "../ServicesModel.h"
#include "ServiceUnits.h"

namespace workorder
{

CoefficientsFilterModel::CoefficientsFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool CoefficientsFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const ServicesModel *>(this->sourceModel());
    if(!sourceModel)
        return true;

    const QModelIndex nameIndex = sourceModel->index(sourceRow, 0, sourceParent);
    const QString name = sourceModel->data(nameIndex, ServicesModel::NameRole).toString();
    const QString keywords = sourceModel->data(nameIndex, ServicesModel::KeywordsRole).toString();
    const QString unit = sourceModel->data(nameIndex, ServicesModel::UnitRole).toString();

    if(!ServiceUnits::isPercentUnit(unit))
        return false;

    const QString filterLower = filterText().toLower();
    return name.toLower().contains(filterLower) || keywords.toLower().contains(filterLower);
}

} // namespace workorder
