#ifndef WORKORDER_MODELS_SERVICES_MODEL_H
#define WORKORDER_MODELS_SERVICES_MODEL_H

#include "GenericModel.h"
#include "items/ServiceItem.h"

namespace workorder
{

class ServicesModel : public GenericModel<ServiceItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        IdRole = Qt::UserRole + 1,
        NameRole = Qt::UserRole + 2,
        NoteRole = Qt::UserRole + 3,
        ParagraphRole = Qt::UserRole + 4,
        PriceRole = Qt::UserRole + 5,
        UnitRole = Qt::UserRole + 6,
        KeywordsRole = Qt::UserRole + 7,
        CreatedAtRole = Qt::UserRole + 8,
        UpdatedAtRole = Qt::UserRole + 9
    };

    explicit ServicesModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE void addItem(const QVariantMap &item);
    Q_INVOKABLE QVariantMap itemData(const QString &id) const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_SERVICES_MODEL_H
