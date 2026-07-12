#ifndef WORKORDER_BACKEND_BACKEND_CONTROLLER_H
#define WORKORDER_BACKEND_BACKEND_CONTROLLER_H

#include <QObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <memory>

namespace workorder
{

class DatabaseBackend;
class InvoiceBackend;
class ReportBackend;
class ReportOptionsBackend;
class SettingsBackend;

class BackendController : public QObject
{
    Q_OBJECT

public:
    explicit BackendController(QQmlApplicationEngine *engine, QObject *parent = nullptr);
    ~BackendController() override;

    bool initialize();
    void exposeToQml(QQmlContext *context) const;

    // SettingsBackend *settingsBackend() const;
    // ReportOptionsBackend *reportOptionsBackend() const;
    // DatabaseBackend *databaseBackend() const;
    // ReportBackend *reportBackend() const;
    // InvoiceBackend *invoiceBackend() const;

private:
    QQmlApplicationEngine *m_engine = nullptr;
    std::unique_ptr<SettingsBackend> m_settingsBackend;
    std::unique_ptr<ReportOptionsBackend> m_reportOptionsBackend;
    std::unique_ptr<DatabaseBackend> m_databaseBackend;
    std::unique_ptr<ReportBackend> m_reportBackend;
    std::unique_ptr<InvoiceBackend> m_invoiceBackend;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_BACKEND_CONTROLLER_H
