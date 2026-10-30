#ifndef WORKORDER_MODELS_COEFFICIENTS_MODEL_H
#define WORKORDER_MODELS_COEFFICIENTS_MODEL_H

#include "GenericModel.h"
#include "items/CoefficientItem.h"

namespace workorder
{

class CoefficientsModel : public GenericModel<CoefficientItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        IdRole = Qt::UserRole + 1,
        NameRole = Qt::UserRole + 2,
        PriceRole = Qt::UserRole + 3,
        UnitRole = Qt::UserRole + 4,
        KeywordsRole = Qt::UserRole + 5,
        CreatedAtRole = Qt::UserRole + 6,
        UpdatedAtRole = Qt::UserRole + 7
    };

    explicit CoefficientsModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE void addItem(const QVariantMap &item);
    Q_INVOKABLE bool removeItem(const QString &id);
    Q_INVOKABLE QVariantMap itemData(const QString &id) const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_COEFFICIENTS_MODEL_H
