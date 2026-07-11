#include "subobjectsFilterModel.h"

#include "../subobjectsModel.h"

namespace workorder
{

SubobjectsFilterModel::SubobjectsFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool SubobjectsFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const SubobjectsModel *>(this->sourceModel());
    if(!sourceModel)
        return false;

    const QModelIndex nameIndex = sourceModel->index(sourceRow, 0, sourceParent);
    const QString name = sourceModel->data(nameIndex, SubobjectsModel::NameRole).toString();
    return name.toCaseFolded().contains(filterText().toCaseFolded());
}

} // namespace workorder
