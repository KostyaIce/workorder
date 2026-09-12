#ifndef WORKORDER_MODELS_EXPENSES_MODEL_H
#define WORKORDER_MODELS_EXPENSES_MODEL_H

#include "GenericModel.h"
#include "items/ExpenseItem.h"

namespace workorder
{

class ExpensesModel : public GenericModel<ExpenseItem>
{
    Q_OBJECT

public:
    explicit ExpensesModel(QObject *parent = nullptr);

    Q_INVOKABLE void updateModelFromMaps(const QVariantList &items);
    Q_INVOKABLE void clearModel();
    Q_INVOKABLE bool addItem(const QVariantMap &item);
    Q_INVOKABLE bool updateItem(const QVariantMap &item);
    Q_INVOKABLE bool removeItem(const QString &expenseId);
    Q_INVOKABLE QVariantMap itemData(const QString &expenseId) const;
    Q_INVOKABLE QVariantList items() const;
};

} // namespace workorder

#endif // WORKORDER_MODELS_EXPENSES_MODEL_H
