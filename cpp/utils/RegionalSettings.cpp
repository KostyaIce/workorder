#include "RegionalSettings.h"

#include <QVariantMap>

namespace workorder
{

namespace
{

struct Currency
{
    const char *code;
    const char *symbol;
    const char *name;
};

// Currencies of the CIS countries.
const Currency kCurrencies[] = {
    {"RUB", "\u20BD", "Российский рубль"},
    {"BYN", "Br", "Белорусский рубль"},
    {"KZT", "\u20B8", "Казахстанский тенге"},
    {"KGS", "сом", "Киргизский сом"},
    {"AMD", "\u058F", "Армянский драм"},
    {"AZN", "\u20BC", "Азербайджанский манат"},
    {"MDL", "L", "Молдавский лей"},
    {"TJS", "SM", "Таджикский сомони"},
    {"TMT", "m", "Туркменский манат"},
    {"UZS", "so\u02BBm", "Узбекский сум"},
    // Countries with a large Russian-speaking population.
    {"UAH", "\u20B4", "Украинская гривна"},
    {"GEL", "\u20BE", "Грузинский лари"},
    {"EUR", "\u20AC", "Евро (Латвия, Литва, Эстония, Германия, Кипр)"},
    {"USD", "$", "Доллар США"},
    {"CAD", "C$", "Канадский доллар"},
    {"ILS", "\u20AA", "Израильский шекель"},
    {"AUD", "A$", "Австралийский доллар"},
    {"AED", "AED", "Дирхам ОАЭ"},
};

const Currency *findCurrency(const QString &code)
{
    for(const Currency &currency : kCurrencies)
    {
        if(code.compare(QLatin1String(currency.code), Qt::CaseInsensitive) == 0)
            return &currency;
    }
    return nullptr;
}

QString g_currencyCode = QStringLiteral("RUB");

} // namespace

QString RegionalSettings::currencyCode()
{
    return g_currencyCode;
}

QString RegionalSettings::currencySymbol()
{
    if(const Currency *currency = findCurrency(g_currencyCode))
        return QString::fromUtf8(currency->symbol);
    return QStringLiteral("\u20BD");
}

void RegionalSettings::setCurrency(const QString &code)
{
    if(const Currency *currency = findCurrency(code))
        g_currencyCode = QString::fromLatin1(currency->code);
    else
        g_currencyCode = QStringLiteral("RUB");
}

QVariantList RegionalSettings::availableCurrencies()
{
    QVariantList result;
    for(const Currency &currency : kCurrencies)
    {
        result.append(QVariantMap{
            {"code", QString::fromLatin1(currency.code)},
            {"symbol", QString::fromUtf8(currency.symbol)},
            {"name", QString::fromUtf8(currency.name)},
        });
    }
    return result;
}

} // namespace workorder
