#include "ExpensesModel.h"

#include "ModelUtils.h"

namespace workorder
{

ExpensesModel::ExpensesModel(QObject *parent)
    : GenericModel<ExpenseItem>(parent)
{
}

void ExpensesModel::updateModelFromMaps(const QVariantList &items)
{
    setItems(itemsFromVariantList<ExpenseItem>(items, ExpenseItem::fromMap));
}

void ExpensesModel::clearModel()
{
    clear();
}

bool ExpensesModel::addItem(const QVariantMap &item)
{
    if(item.isEmpty())
        return false;

    beginInsertRows(QModelIndex(), 0, 0);
    m_items.insert(0, ExpenseItem::fromMap(item));
    endInsertRows();
    emit sizeChanged();
    return true;
}

bool ExpensesModel::updateItem(const QVariantMap &item)
{
    const QString expenseId = item.value("id").toString();
    if(expenseId.isEmpty())
        return false;

    for(int index = 0; index < m_items.size(); ++index)
    {
        if(m_items.at(index).id != expenseId)
            continue;

        ExpenseItem updated = m_items.at(index);
        if(item.contains("description"))
            updated.description = item.value("description").toString();
        if(item.contains("amount"))
            updated.amount = item.value("amount").toInt();
        if(item.contains("updated_at"))
            updated.updatedAt = item.value("updated_at").toLongLong();

        m_items[index] = updated;
        const QModelIndex modelIndex = this->index(index);
        emit dataChanged(modelIndex, modelIndex);
        emit sigItemChanged(index);
        return true;
    }
    return false;
}

bool ExpensesModel::removeItem(const QString &expenseId)
{
    if(expenseId.isEmpty())
        return false;

    for(int index = 0; index < m_items.size(); ++index)
    {
        if(m_items.at(index).id != expenseId)
            continue;

        beginRemoveRows(QModelIndex(), index, index);
        m_items.removeAt(index);
        endRemoveRows();
        emit sizeChanged();
        return true;
    }
    return false;
}

QVariantMap ExpensesModel::itemData(const QString &expenseId) const
{
    for(const ExpenseItem &item : getItems())
    {
        if(item.id == expenseId)
            return item.toMap();
    }
    return {};
}

QVariantList ExpensesModel::items() const
{
    return variantListFromItems(getItems());
}

} // namespace workorder
