#include "DatabaseBackend.h"

#include "DatabaseStorage.h"
#include "ServicesDatabase.h"
#include "Types.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#include <limits>

namespace workorder
{

DatabaseBackend::DatabaseBackend(QObject *parent)
    : QObject(parent)
    , m_servicesDbPath(ServicesDatabase::defaultServicesDbPath())
{
}

DatabaseBackend::~DatabaseBackend() = default;

int DatabaseBackend::workCount() const
{
    return 0;
}

bool DatabaseBackend::addService(const QString &name, double price)
{
    const QString trimmed = name.trimmed();
    if(trimmed.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Название услуги не может быть пустым"));
        return false;
    }

    if(price < 0.0)
    {
        emit errorOccurred(QStringLiteral("Цена не может быть отрицательной"));
        return false;
    }

    const QVariantMap payload{
        {"name", trimmed},
        {"price", QString::number(price, 'f', 2)},
    };

    if(!ServicesDatabase::addService(payload))
    {
        emit errorOccurred(QStringLiteral("Услуга '%1' уже существует").arg(trimmed));
        return false;
    }

    loadServicesFromDatabase();
    emit serviceAdded(0, trimmed, price);
    return true;
}

bool DatabaseBackend::updateService(int serviceId, const QString &name, double price)
{
    Q_UNUSED(serviceId);

    const QString trimmed = name.trimmed();
    if(trimmed.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Название услуги не может быть пустым"));
        return false;
    }

    if(price < 0.0)
    {
        emit errorOccurred(QStringLiteral("Цена не может быть отрицательной"));
        return false;
    }

    for(const QVariant &item : m_services)
    {
        const QVariantMap service = item.toMap();
        if(service.value("name").toString().compare(trimmed, Qt::CaseInsensitive) == 0)
        {
            QVariantMap payload = service;
            payload.insert("name", trimmed);
            payload.insert("price", QString::number(price, 'f', 2));
            if(!ServicesDatabase::updateService(payload))
            {
                emit errorOccurred(QStringLiteral("Не удалось обновить услугу"));
                return false;
            }
            loadServicesFromDatabase();
            emit serviceUpdated(0, trimmed, price);
            return true;
        }
    }

    emit errorOccurred(QStringLiteral("Услуга с ID %1 не найдена").arg(serviceId));
    return false;
}

bool DatabaseBackend::deleteService(int serviceId)
{
    for(int index = 0; index < m_services.size(); ++index)
    {
        const QVariantMap service = m_services.at(index).toMap();
        const QString id = service.value("id").toString();
        if(index + 1 != serviceId && service.value("id").toInt() != serviceId && id.toInt() != serviceId)
            continue;

        if(!ServicesDatabase::deleteService(id))
            break;

        loadServicesFromDatabase();
        emit serviceDeleted(serviceId);
        return true;
    }

    emit errorOccurred(QStringLiteral("Услуга с ID %1 не найдена").arg(serviceId));
    return false;
}

void DatabaseBackend::selectService(int serviceId)
{
    for(const QVariant &item : m_services)
    {
        const QVariantMap service = item.toMap();
        if(service.value("id").toInt() == serviceId || m_services.indexOf(item) + 1 == serviceId)
        {
            m_selectedServiceId = serviceId;
            emit serviceSelected(serviceId, service.value("name").toString(), centsToPrice(service.value("price").toInt()));
            return;
        }
    }

    m_selectedServiceId = 0;
    emit serviceSelected(0, QString(), 0.0);
}

void DatabaseBackend::clearSelection()
{
    m_selectedServiceId = 0;
    emit serviceSelected(0, QString(), 0.0);
}

QVariantList DatabaseBackend::getAllServices() const
{
    return m_services;
}

QVariantMap DatabaseBackend::getServiceById(int serviceId) const
{
    for(const QVariant &item : m_services)
    {
        const QVariantMap service = item.toMap();
        if(service.value("id").toInt() == serviceId)
            return service;
    }
    return {};
}

QVariantList DatabaseBackend::searchServices(const QString &query) const
{
    if(query.trimmed().isEmpty())
        return m_services;

    const QString pattern = query.trimmed().toCaseFolded();
    QVariantList result;
    for(const QVariant &item : m_services)
    {
        const QVariantMap service = item.toMap();
        if(service.value("name").toString().toCaseFolded().contains(pattern))
            result.append(service);
    }
    return result;
}

QVariantList DatabaseBackend::filterByPriceRange(double minPrice, double maxPrice) const
{
    QVariantList result;
    for(const QVariant &item : m_services)
    {
        const QVariantMap service = item.toMap();
        const double price = centsToPrice(service.value("price").toInt());
        if(price >= minPrice && price <= maxPrice)
            result.append(service);
    }
    return result;
}

bool DatabaseBackend::createServicesDatabase(const QString &filePath)
{
    Q_UNUSED(filePath);
    ServicesDatabase::createServicesTable();
    m_servicesDbPath = ServicesDatabase::defaultServicesDbPath();
    return true;
}

bool DatabaseBackend::createWorksDatabase(const QString &filePath)
{
    Q_UNUSED(filePath);
    DatabaseStorage::createWorksDatabase(QStringLiteral("demo"), QStringLiteral("demo"));
    emit worksChanged();
    return true;
}

bool DatabaseBackend::repairDatabase(const QString &filePath)
{
    Q_UNUSED(filePath);
    ServicesDatabase::createServicesTable();
    m_servicesDbPath = ServicesDatabase::defaultServicesDbPath();
    emit databaseRepaired(QStringLiteral("Services table checked"));
    return true;
}

bool DatabaseBackend::loadServicesFromDatabase(const QString &filePath)
{
    Q_UNUSED(filePath);
    ServicesDatabase::createServicesTable();
    const StringMapList services = ServicesDatabase::loadServices();
    if(services.isEmpty())
    {
        emit errorOccurred(QStringLiteral("БД услуг пуста или не найдена: %1").arg(ServicesDatabase::defaultServicesDbPath()));
        return false;
    }

    m_servicesDbPath = ServicesDatabase::defaultServicesDbPath();
    applyServices(services);
    return true;
}

bool DatabaseBackend::loadWorksFromDatabase(const QString &filePath)
{
    Q_UNUSED(filePath);
    return true;
}

QVariantList DatabaseBackend::getAllCompletedWorks() const
{
    return {};
}

bool DatabaseBackend::exportToJson(const QString &filePath)
{
    QFile file(filePath);
    if(!file.open(QIODevice::WriteOnly))
    {
        emit errorOccurred(QStringLiteral("Ошибка экспорта: %1").arg(filePath));
        return false;
    }

    QJsonArray array;
    for(const QVariant &item : m_services)
        array.append(QJsonObject::fromVariantMap(item.toMap()));

    file.write(QJsonDocument(array).toJson(QJsonDocument::Indented));
    return true;
}

bool DatabaseBackend::importFromJson(const QString &filePath)
{
    QFile file(filePath);
    if(!file.open(QIODevice::ReadOnly))
    {
        emit errorOccurred(QStringLiteral("Ошибка импорта: %1").arg(filePath));
        return false;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if(!doc.isArray())
        return false;

    for(const QJsonValue &value : doc.array())
    {
        const QJsonObject object = value.toObject();
        addService(object.value("name").toString(), object.value("price").toDouble());
    }
    return true;
}

bool DatabaseBackend::resetDatabase()
{
    m_services.clear();
    m_selectedServiceId = 0;
    m_nextId = 1;
    emit servicesChanged();
    emit serviceSelected(0, QString(), 0.0);
    return true;
}

QVariantMap DatabaseBackend::getStatistics() const
{
    if(m_services.isEmpty())
    {
        return {
            {"count", 0},
            {"min_price", 0},
            {"max_price", 0},
            {"avg_price", 0},
            {"total_value", 0},
        };
    }

    double minPrice = std::numeric_limits<double>::max();
    double maxPrice = 0.0;
    double total = 0.0;
    for(const QVariant &item : m_services)
    {
        const double price = centsToPrice(item.toMap().value("price").toInt());
        minPrice = qMin(minPrice, price);
        maxPrice = qMax(maxPrice, price);
        total += price;
    }

    return {
        {"count", m_services.size()},
        {"min_price", minPrice},
        {"max_price", maxPrice},
        {"avg_price", total / m_services.size()},
        {"total_value", total},
    };
}

void DatabaseBackend::applyServices(const QVariantList &services)
{
    m_services = services;
    m_nextId = services.isEmpty() ? 1 : services.size() + 1;
    m_selectedServiceId = 0;
    emit servicesChanged();
    emit serviceSelected(0, QString(), 0.0);
}

int DatabaseBackend::priceToCents(double price) const
{
    return static_cast<int>(qRound64(price * 100.0));
}

double DatabaseBackend::centsToPrice(int cents) const
{
    return cents / 100.0;
}

} // namespace workorder
