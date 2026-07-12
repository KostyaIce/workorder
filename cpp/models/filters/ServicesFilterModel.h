#ifndef WORKORDER_MODELS_SERVICES_FILTER_MODEL_H
#define WORKORDER_MODELS_SERVICES_FILTER_MODEL_H

#include "TextFilterProxyModel.h"

namespace workorder
{

class ServicesFilterModel : public TextFilterProxyModel
{
    Q_OBJECT

public:
    explicit ServicesFilterModel(QObject *parent = nullptr);

protected:
    bool acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

} // namespace workorder

#endif // WORKORDER_MODELS_SERVICES_FILTER_MODEL_H
