#ifndef WORKORDER_MODELS_WORKS_MODEL_H
#define WORKORDER_MODELS_WORKS_MODEL_H

#include "GenericModel.h"
#include "items/WorkItem.h"

namespace workorder
{

class WorksModel : public GenericModel<WorkItem>
{
    Q_OBJECT

public:
    enum Roles
    {
        IdRole = Qt::UserRole + 1,
        ObjectIdRole = Qt::UserRole + 2,
        ServiceIdRole = Qt::UserRole + 3,
        SubobjectNameRole = Qt::UserRole + 4,
        NameRole = Qt::UserRole + 5,
        PriceRole = Qt::UserRole + 6,
        UnitRole = Qt::UserRole + 7,
        QuantityRole = Qt::UserRole + 8,
        CreatedAtRole = Qt::UserRole + 9,
        UpdatedAtRole = Qt::UserRole + 10,
        StartOrderAtRole = Qt::UserRole + 11,
        CoefficientsRole = Qt::UserRole + 12,
        PercentSumRole = Qt::UserRole + 13
    };

    explicit WorksModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE void clearModel();
    Q_INVOKABLE bool addItem(const QVariantMap &item);
    Q_INVOKABLE bool updateItem(const QVariantMap &item);
    Q_INVOKABLE bool removeItem(const QString &workId);
    Q_INVOKABLE QVariantMap itemData(const QString &workId) const;
    Q_INVOKABLE QVariantList items() const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_WORKS_MODEL_H
