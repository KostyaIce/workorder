#include "CoefficientsFilterModel.h"

#include "../CoefficientsModel.h"

namespace workorder
{

CoefficientsFilterModel::CoefficientsFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool CoefficientsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    // The picker shows all coefficients until the user starts typing.
    if(filterText().isEmpty())
        return acceptSourceRow(sourceRow, sourceParent);
    return TextFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

bool CoefficientsFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const CoefficientsModel *>(this->sourceModel());
    if(!sourceModel)
        return false;

    const QModelIndex index = sourceModel->index(sourceRow, 0, sourceParent);
    const QString query = filterText().toCaseFolded();
    return sourceModel->data(index, CoefficientsModel::NameRole).toString().toCaseFolded().contains(query)
        || sourceModel->data(index, CoefficientsModel::KeywordsRole).toString().toCaseFolded().contains(query);
}

} // namespace workorder
