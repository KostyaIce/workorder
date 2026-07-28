#ifndef WORKORDER_BACKEND_REPORT_OPTIONS_BACKEND_H
#define WORKORDER_BACKEND_REPORT_OPTIONS_BACKEND_H

#include <QObject>
#include <QSet>
#include <QString>
#include <QVariantMap>

namespace workorder
{

class ReportOptionsBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool includeClientName READ includeClientName WRITE setIncludeClientName NOTIFY optionsChanged)
    Q_PROPERTY(bool includeClientAddress READ includeClientAddress WRITE setIncludeClientAddress NOTIFY optionsChanged)
    Q_PROPERTY(bool includeReportDate READ includeReportDate WRITE setIncludeReportDate NOTIFY optionsChanged)
    Q_PROPERTY(bool includePersonalInfo READ includePersonalInfo WRITE setIncludePersonalInfo NOTIFY optionsChanged)
    Q_PROPERTY(bool includeReportHeader READ includeReportHeader WRITE setIncludeReportHeader NOTIFY optionsChanged)
    Q_PROPERTY(QString reportHeaderText READ reportHeaderText WRITE setReportHeaderText NOTIFY optionsChanged)
    Q_PROPERTY(bool groupBySubobjects READ groupBySubobjects WRITE setGroupBySubobjects NOTIFY optionsChanged)
    Q_PROPERTY(bool includeCoefficients READ includeCoefficients WRITE setIncludeCoefficients NOTIFY optionsChanged)

public:
    explicit ReportOptionsBackend(QObject *parent = nullptr);
    ~ReportOptionsBackend() override;

    bool includeClientName() const;
    void setIncludeClientName(bool value);

    bool includeClientAddress() const;
    void setIncludeClientAddress(bool value);

    bool includeReportDate() const;
    void setIncludeReportDate(bool value);

    bool includePersonalInfo() const;
    void setIncludePersonalInfo(bool value);

    bool includeReportHeader() const;
    void setIncludeReportHeader(bool value);

    QString reportHeaderText() const;
    void setReportHeaderText(const QString &value);

    bool groupBySubobjects() const;
    void setGroupBySubobjects(bool value);

    bool includeCoefficients() const;
    void setIncludeCoefficients(bool value);

    QVariantMap asDict() const;

    Q_INVOKABLE bool saveSettings();
    Q_INVOKABLE void clearOrderSelection();
    Q_INVOKABLE bool orderSelected(int startOrderAt) const;
    Q_INVOKABLE void setOrderSelected(int startOrderAt, bool selected);
    Q_INVOKABLE QVariantList selectedOrderTimestamps() const;

signals:
    void optionsChanged();
    void orderSelectionChanged();

private:
    void loadSettings();
    void persistSettings();

    bool m_includeClientName = true;
    bool m_includeClientAddress = true;
    bool m_includeReportDate = true;
    bool m_includePersonalInfo = true;
    bool m_includeReportHeader = true;
    QString m_reportHeaderText;
    bool m_groupBySubobjects = true;
    bool m_includeCoefficients = true;
    QSet<int> m_selectedOrders;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_REPORT_OPTIONS_BACKEND_H
