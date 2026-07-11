#ifndef WORKORDER_MODELS_CLIENTS_MODEL_H
#define WORKORDER_MODELS_CLIENTS_MODEL_H

#include "genericModel.h"
#include "items/clientItem.h"

namespace workorder
{

class ClientsModel : public GenericModel<ClientItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        KindRole = Qt::UserRole + 2,
        IdRole = Qt::UserRole + 3,
        ContactRole = Qt::UserRole + 4,
        AddressRole = Qt::UserRole + 5,
        NotesRole = Qt::UserRole + 6,
        CreatedRole = Qt::UserRole + 7
    };

    explicit ClientsModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE QVariantMap itemData(const QString &id) const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_CLIENTS_MODEL_H
