#ifndef WORKORDER_MODELS_SUBOBJECTS_FILTER_MODEL_H
#define WORKORDER_MODELS_SUBOBJECTS_FILTER_MODEL_H

#include "textFilterProxyModel.h"

namespace workorder
{

class SubobjectsFilterModel : public TextFilterProxyModel
{
    Q_OBJECT

public:
    explicit SubobjectsFilterModel(QObject *parent = nullptr);

protected:
    bool acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

} // namespace workorder

#endif // WORKORDER_MODELS_SUBOBJECTS_FILTER_MODEL_H
