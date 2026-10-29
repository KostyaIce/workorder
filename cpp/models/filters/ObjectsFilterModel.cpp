#include "ObjectsFilterModel.h"

#include "../ObjectsModel.h"

namespace workorder
{

ObjectsFilterModel::ObjectsFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool ObjectsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if(filterText().isEmpty())
        return true;
    return TextFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

bool ObjectsFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const ObjectsModel *>(this->sourceModel());
    if(!sourceModel)
        return false;

    const QModelIndex index = sourceModel->index(sourceRow, 0, sourceParent);
    const QString query = filterText().toCaseFolded();
    return sourceModel->data(index, ObjectsModel::NameRole).toString().toCaseFolded().contains(query)
        || sourceModel->data(index, ObjectsModel::AddressRole).toString().toCaseFolded().contains(query);
}

} // namespace workorder
