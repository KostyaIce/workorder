#include "ClientsModel.h"

#include "ModelUtils.h"

namespace workorder
{

ClientsModel::ClientsModel(QObject *parent)
    : GenericModel<ClientItem>(parent)
{
}

void ClientsModel::updateModelFromMaps(const QVariantList &items)
{
    setItems(itemsFromVariantList<ClientItem>(items, ClientItem::fromMap));
}

QVariantMap ClientsModel::itemData(const QString &id) const
{
    for(const ClientItem &item : getItems())
    {
        if(item.id == id)
            return item.toMap();
    }
    return {};
}

} // namespace workorder
