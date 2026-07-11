#include "textFilterProxyModel.h"

namespace workorder
{

TextFilterProxyModel::TextFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

QString TextFilterProxyModel::filterText() const
{
    return m_filterText;
}

void TextFilterProxyModel::setFilterText(const QString &text)
{
    if(m_filterText == text)
        return;

    m_filterText = text;
    invalidateFilter();
    emit filterTextChanged();
}

void TextFilterProxyModel::clearFilter()
{
    setFilterText(QString());
}

int TextFilterProxyModel::count() const
{
    return rowCount();
}

bool TextFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if(m_filterText.isEmpty())
        return false;

    return acceptSourceRow(sourceRow, sourceParent);
}

} // namespace workorder
