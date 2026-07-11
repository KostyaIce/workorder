#include "backendController.h"

#include "databaseBackend.h"
#include "invoiceBackend.h"
#include "reportBackend.h"
#include "reportOptionsBackend.h"
#include "settingsBackend.h"

namespace workorder
{

BackendController::BackendController(QQmlApplicationEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
    , m_settingsBackend(std::make_unique<SettingsBackend>())
    , m_reportOptionsBackend(std::make_unique<ReportOptionsBackend>())
    , m_databaseBackend(std::make_unique<DatabaseBackend>())
    , m_reportBackend(std::make_unique<ReportBackend>(
          m_settingsBackend.get(),
          m_reportOptionsBackend.get(),
          engine))
    , m_invoiceBackend(std::make_unique<InvoiceBackend>(engine))
{
    m_invoiceBackend->bindReportBackend(m_reportBackend.get());
}

BackendController::~BackendController() = default;

bool BackendController::initialize()
{
    return m_reportBackend->initializeData();
}

void BackendController::exposeToQml(QQmlContext *context) const
{
    if(!context)
        return;

    context->setContextProperty("invoiceBackend", m_invoiceBackend.get());
    context->setContextProperty("databaseBackend", m_databaseBackend.get());
    context->setContextProperty("settingsBackend", m_settingsBackend.get());
    context->setContextProperty("reportOptionsBackend", m_reportOptionsBackend.get());
    context->setContextProperty("reportBackend", m_reportBackend.get());
}

// SettingsBackend *BackendController::settingsBackend() const
// {
//     return m_settingsBackend.get();
// }

// ReportOptionsBackend *BackendController::reportOptionsBackend() const
// {
//     return m_reportOptionsBackend.get();
// }

// DatabaseBackend *BackendController::databaseBackend() const
// {
//     return m_databaseBackend.get();
// }

// ReportBackend *BackendController::reportBackend() const
// {
//     return m_reportBackend.get();
// }

// InvoiceBackend *BackendController::invoiceBackend() const
// {
//     return m_invoiceBackend.get();
// }

} // namespace workorder
