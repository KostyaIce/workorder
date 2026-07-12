#include "ReportOptionsBackend.h"

#include "QSettingsStore.h"

namespace workorder
{

namespace
{

const char *kIncludeClientName = "report_options/include_client_name";
const char *kIncludeClientAddress = "report_options/include_client_address";
const char *kIncludeReportDate = "report_options/include_report_date";
const char *kIncludePersonalInfo = "report_options/include_personal_info";
const char *kIncludeReportHeader = "report_options/include_report_header";
const char *kReportHeaderText = "report_options/report_header_text";
const char *kGroupBySubobjects = "report_options/group_by_subobjects";
const char *kDefaultReportHeader = "Отчет о проделанной работе по установке сантехники";

} // namespace

ReportOptionsBackend::ReportOptionsBackend(QObject *parent)
    : QObject(parent)
    , m_reportHeaderText(QString::fromUtf8(kDefaultReportHeader))
{
    loadSettings();
}

ReportOptionsBackend::~ReportOptionsBackend() = default;

bool ReportOptionsBackend::includeClientName() const { return m_includeClientName; }
void ReportOptionsBackend::setIncludeClientName(bool value)
{
    if(m_includeClientName == value)
        return;
    m_includeClientName = value;
    emit optionsChanged();
}

bool ReportOptionsBackend::includeClientAddress() const { return m_includeClientAddress; }
void ReportOptionsBackend::setIncludeClientAddress(bool value)
{
    if(m_includeClientAddress == value)
        return;
    m_includeClientAddress = value;
    emit optionsChanged();
}

bool ReportOptionsBackend::includeReportDate() const { return m_includeReportDate; }
void ReportOptionsBackend::setIncludeReportDate(bool value)
{
    if(m_includeReportDate == value)
        return;
    m_includeReportDate = value;
    emit optionsChanged();
}

bool ReportOptionsBackend::includePersonalInfo() const { return m_includePersonalInfo; }
void ReportOptionsBackend::setIncludePersonalInfo(bool value)
{
    if(m_includePersonalInfo == value)
        return;
    m_includePersonalInfo = value;
    emit optionsChanged();
}

bool ReportOptionsBackend::includeReportHeader() const { return m_includeReportHeader; }
void ReportOptionsBackend::setIncludeReportHeader(bool value)
{
    if(m_includeReportHeader == value)
        return;
    m_includeReportHeader = value;
    emit optionsChanged();
}

QString ReportOptionsBackend::reportHeaderText() const { return m_reportHeaderText; }
void ReportOptionsBackend::setReportHeaderText(const QString &value)
{
    if(m_reportHeaderText == value)
        return;
    m_reportHeaderText = value;
    emit optionsChanged();
}

bool ReportOptionsBackend::groupBySubobjects() const { return m_groupBySubobjects; }
void ReportOptionsBackend::setGroupBySubobjects(bool value)
{
    if(m_groupBySubobjects == value)
        return;
    m_groupBySubobjects = value;
    emit optionsChanged();
}

QVariantMap ReportOptionsBackend::asDict() const
{
    QVariantMap map;
    map.insert("include_client_name", m_includeClientName);
    map.insert("include_client_address", m_includeClientAddress);
    map.insert("include_report_date", m_includeReportDate);
    map.insert("include_personal_info", m_includePersonalInfo);
    map.insert("include_report_header", m_includeReportHeader);
    map.insert("report_header_text", m_reportHeaderText);
    map.insert("group_by_subobjects", m_groupBySubobjects);
    return map;
}

bool ReportOptionsBackend::saveSettings()
{
    persistSettings();
    return true;
}

void ReportOptionsBackend::clearOrderSelection()
{
    if(m_selectedOrders.isEmpty())
        return;
    m_selectedOrders.clear();
    emit orderSelectionChanged();
}

bool ReportOptionsBackend::orderSelected(int startOrderAt) const
{
    return m_selectedOrders.contains(startOrderAt);
}

void ReportOptionsBackend::setOrderSelected(int startOrderAt, bool selected)
{
    if(selected)
    {
        if(!m_selectedOrders.contains(startOrderAt))
        {
            m_selectedOrders.insert(startOrderAt);
            emit orderSelectionChanged();
        }
        return;
    }

    if(m_selectedOrders.remove(startOrderAt))
        emit orderSelectionChanged();
}

QVariantList ReportOptionsBackend::selectedOrderTimestamps() const
{
    QVariantList result;
    for(int value : m_selectedOrders)
        result.append(value);
    return result;
}

void ReportOptionsBackend::loadSettings()
{
    QSettingsStore store;
    m_includeClientName = store.read(kIncludeClientName, true).toBool();
    m_includeClientAddress = store.read(kIncludeClientAddress, true).toBool();
    m_includeReportDate = store.read(kIncludeReportDate, true).toBool();
    m_includePersonalInfo = store.read(kIncludePersonalInfo, true).toBool();
    m_includeReportHeader = store.read(kIncludeReportHeader, true).toBool();
    m_reportHeaderText = store.read(kReportHeaderText, m_reportHeaderText).toString();
    if(m_reportHeaderText.isEmpty())
        m_reportHeaderText = QString::fromUtf8(kDefaultReportHeader);
    m_groupBySubobjects = store.read(kGroupBySubobjects, true).toBool();
}

void ReportOptionsBackend::persistSettings()
{
    QSettingsStore store;
    store.write(kIncludeClientName, m_includeClientName);
    store.write(kIncludeClientAddress, m_includeClientAddress);
    store.write(kIncludeReportDate, m_includeReportDate);
    store.write(kIncludePersonalInfo, m_includePersonalInfo);
    store.write(kIncludeReportHeader, m_includeReportHeader);
    store.write(kReportHeaderText, m_reportHeaderText);
    store.write(kGroupBySubobjects, m_groupBySubobjects);
    store.sync();
}

} // namespace workorder
