#ifndef WORKORDER_UTILS_REPORT_SHARE_H
#define WORKORDER_UTILS_REPORT_SHARE_H

#include <QString>

namespace workorder
{

class ReportShare
{
public:
    // On iOS and Android, makes the saved file reachable from Mail and messengers
    // and returns a short place name. On desktop, returns an empty string.
    static QString publish(const QString &savedPath);
};

} // namespace workorder

#endif // WORKORDER_UTILS_REPORT_SHARE_H
