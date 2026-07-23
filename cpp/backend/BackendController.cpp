#include "BackendController.h"

#include "CloudDiskBackend.h"
#include "DatabaseBackend.h"
#include "InvoiceBackend.h"
#include "ReportBackend.h"
#include "ReportOptionsBackend.h"
#include "SettingsBackend.h"

namespace workorder
{

BackendController::BackendController(QQmlApplicationEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
    , m_settingsBackend(std::make_unique<SettingsBackend>())
    , m_reportOptionsBackend(std::make_unique<ReportOptionsBackend>())
    , m_cloudDiskBackend(std::make_unique<CloudDiskBackend>())
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
    context->setContextProperty("cloudDiskBackend", m_cloudDiskBackend.get());
    context->setContextProperty("reportBackend", m_reportBackend.get());
}

} // namespace workorder
