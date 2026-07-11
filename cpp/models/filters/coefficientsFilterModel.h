#ifndef WORKORDER_MODELS_COEFFICIENTS_FILTER_MODEL_H
#define WORKORDER_MODELS_COEFFICIENTS_FILTER_MODEL_H

#include "textFilterProxyModel.h"

namespace workorder
{

class CoefficientsFilterModel : public TextFilterProxyModel
{
    Q_OBJECT

public:
    explicit CoefficientsFilterModel(QObject *parent = nullptr);

protected:
    bool acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

} // namespace workorder

#endif // WORKORDER_MODELS_COEFFICIENTS_FILTER_MODEL_H
