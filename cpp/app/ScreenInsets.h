#ifndef WORKORDER_APP_SCREEN_INSETS_H
#define WORKORDER_APP_SCREEN_INSETS_H

#include <QObject>

class QScreen;
class QWindow;

namespace workorder
{

// Safe-area insets of the top-level window, in device-independent pixels.
class ScreenInsets : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int top READ top NOTIFY insetsChanged)
    Q_PROPERTY(int bottom READ bottom NOTIFY insetsChanged)
    Q_PROPERTY(int left READ left NOTIFY insetsChanged)
    Q_PROPERTY(int right READ right NOTIFY insetsChanged)

public:
    explicit ScreenInsets(QObject *parent = nullptr);

    int top() const;
    int bottom() const;
    int left() const;
    int right() const;

    Q_INVOKABLE void attachWindow(QObject *windowObject);

signals:
    void insetsChanged();

private:
    void watchScreen(QScreen *screen);
    void update();

    QWindow *m_window = nullptr;
    QScreen *m_screen = nullptr;
    int m_top = 0;
    int m_bottom = 0;
    int m_left = 0;
    int m_right = 0;
};

} // namespace workorder

#endif // WORKORDER_APP_SCREEN_INSETS_H
