#ifndef WORKORDER_MODELS_SUBOBJECTS_MODEL_H
#define WORKORDER_MODELS_SUBOBJECTS_MODEL_H

#include "GenericModel.h"
#include "items/SubobjectItem.h"

namespace workorder
{

class SubobjectsModel : public GenericModel<SubobjectItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        NameRole = Qt::UserRole + 1
    };

    explicit SubobjectsModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromNames(const QStringList &names);
    Q_INVOKABLE bool addItem(const QString &name);
};

} // namespace workorder

#endif // WORKORDER_MODELS_SUBOBJECTS_MODEL_H
