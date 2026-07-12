#ifndef WORKORDER_MODELS_TEXT_FILTER_PROXY_MODEL_H
#define WORKORDER_MODELS_TEXT_FILTER_PROXY_MODEL_H

#include <QSortFilterProxyModel>

namespace workorder
{

class TextFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(int count READ count NOTIFY filterTextChanged)

public:
    explicit TextFilterProxyModel(QObject *parent = nullptr);

    QString filterText() const;
    void setFilterText(const QString &text);

    Q_INVOKABLE void clearFilter();
    int count() const;

signals:
    void filterTextChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    virtual bool acceptSourceRow(int sourceRow, const QModelIndex &sourceParent) const = 0;

protected:
    QString m_filterText;
};

} // namespace workorder

#endif // WORKORDER_MODELS_TEXT_FILTER_PROXY_MODEL_H
