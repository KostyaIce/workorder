#ifndef WORKORDER_MODELS_OBJECTS_MODEL_H
#define WORKORDER_MODELS_OBJECTS_MODEL_H

#include "genericModel.h"
#include "items/objectItem.h"

namespace workorder
{

class ObjectsModel : public GenericModel<ObjectItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        IdRole = Qt::UserRole + 1,
        NameRole = Qt::UserRole + 2,
        AddressRole = Qt::UserRole + 3,
        UpdatedAtRole = Qt::UserRole + 4,
        LastOrderAtRole = Qt::UserRole + 5
    };

    explicit ObjectsModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE QVariantMap itemData(const QString &id) const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_OBJECTS_MODEL_H
