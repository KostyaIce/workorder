#ifndef WORKORDER_MODELS_CLIENTS_FILTER_MODEL_H
#define WORKORDER_MODELS_CLIENTS_FILTER_MODEL_H

#include "TextFilterProxyModel.h"

namespace workorder
{

class ClientsFilterModel : public TextFilterProxyModel
{
    Q_OBJECT

public:
    explicit ClientsFilterModel(QObject *parent = nullptr);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

} // namespace workorder

#endif // WORKORDER_MODELS_CLIENTS_FILTER_MODEL_H
