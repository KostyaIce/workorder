# Notifications

Toast queue for user-facing messages (errors, warnings, info), similar to
`NotificationManager` in dapchainvpn-client.

## Pieces

| File | Role |
|------|------|
| `cpp/backend/NotificationManager.h/.cpp` | FIFO queue, TTL timer, logging |
| `resources/qml/WorkOrder/Common/NotificationToast.qml` | Popup UI |
| `BackendController` | Owns manager, exposes `notificationManager` to QML |

## Flow

1. Backend (or QML) calls `NotificationManager::notifyError` / `pushError` (also info/warning).
2. Message is enqueued and written to the app log via `qWarning` / `qInfo`.
3. If nothing is shown, the next item is dequeued, `showNotification` is emitted, TTL starts (default 5 s).
4. Auto-dismiss on TTL or manual `dismiss()` from the toast close button → `hideNotification` → next in queue.

## Backend usage

```cpp
#include "NotificationManager.h"

NotificationManager::notifyError(QStringLiteral("Выберите заказчика"));
NotificationManager::notifyWarning(QStringLiteral("..."));
NotificationManager::notifyInfo(QStringLiteral("..."));
```

Do **not** reintroduce disconnected `errorOccurred` signals for UI feedback.

## QML usage

```qml
notificationManager.pushError("Текст")
notificationManager.pushWarning("Текст", "Заголовок")
notificationManager.dismiss()
```

`NotificationToast` is mounted once in `desktop/main.qml` and `mobile/main.qml`.
