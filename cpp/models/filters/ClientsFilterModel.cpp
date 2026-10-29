#include "ClientsFilterModel.h"

#include "../ClientsModel.h"

namespace workorder
{

ClientsFilterModel::ClientsFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool ClientsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if(filterText().isEmpty())
        return true;
    return TextFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

bool ClientsFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const ClientsModel *>(this->sourceModel());
    if(!sourceModel)
        return false;

    const QModelIndex index = sourceModel->index(sourceRow, 0, sourceParent);
    const QString query = filterText().toCaseFolded();
    return sourceModel->data(index, ClientsModel::NameRole).toString().toCaseFolded().contains(query)
        || sourceModel->data(index, ClientsModel::ContactRole).toString().toCaseFolded().contains(query)
        || sourceModel->data(index, ClientsModel::AddressRole).toString().toCaseFolded().contains(query);
}

} // namespace workorder
