#include "ServicesFilterModel.h"

#include "../ServicesModel.h"

namespace workorder
{

ServicesFilterModel::ServicesFilterModel(QObject *parent)
    : TextFilterProxyModel(parent)
{
}

bool ServicesFilterModel::acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const auto *sourceModel = qobject_cast<const ServicesModel *>(this->sourceModel());
    if(!sourceModel)
        return true;

    const QModelIndex nameIndex = sourceModel->index(sourceRow, 0, sourceParent);
    const QString name = sourceModel->data(nameIndex, ServicesModel::NameRole).toString();
    const QString keywords = sourceModel->data(nameIndex, ServicesModel::KeywordsRole).toString();

    const QString filterLower = filterText().toLower();
    return name.toLower().contains(filterLower) || keywords.toLower().contains(filterLower);
}

} // namespace workorder
