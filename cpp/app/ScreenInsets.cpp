#include "ScreenInsets.h"

#include <QGuiApplication>
#include <QScreen>
#include <QTimer>
#include <QWindow>
#include <qpa/qplatformwindow.h>

namespace workorder
{

ScreenInsets::ScreenInsets(QObject *parent)
    : QObject(parent)
{
}

int ScreenInsets::top() const
{
    return m_top;
}

int ScreenInsets::bottom() const
{
    return m_bottom;
}

int ScreenInsets::left() const
{
    return m_left;
}

int ScreenInsets::right() const
{
    return m_right;
}

void ScreenInsets::attachWindow(QObject *windowObject)
{
    auto *window = qobject_cast<QWindow *>(windowObject);
    if(!window || window == m_window)
        return;

    if(m_window)
        m_window->disconnect(this);

    m_window = window;
    connect(m_window, &QWindow::widthChanged, this, &ScreenInsets::update);
    connect(m_window, &QWindow::heightChanged, this, &ScreenInsets::update);
    connect(m_window, &QWindow::screenChanged, this, [this](QScreen *screen)
    {
        watchScreen(screen);
        update();
    });
    connect(qApp, &QGuiApplication::applicationStateChanged, this, &ScreenInsets::update);
    watchScreen(m_window->screen());
    update();
    // Insets are reported after the first native layout pass.
    QTimer::singleShot(0, this, &ScreenInsets::update);
    QTimer::singleShot(100, this, &ScreenInsets::update);
    QTimer::singleShot(400, this, &ScreenInsets::update);
}

void ScreenInsets::watchScreen(QScreen *screen)
{
    if(m_screen == screen)
        return;
    if(m_screen)
        m_screen->disconnect(this);
    m_screen = screen;
    if(!m_screen)
        return;
    connect(m_screen, &QScreen::availableGeometryChanged, this, &ScreenInsets::update);
    connect(m_screen, &QScreen::geometryChanged, this, &ScreenInsets::update);
}

void ScreenInsets::update()
{
#if !defined(Q_OS_IOS) && !defined(Q_OS_ANDROID)
    if(m_left == 0 && m_top == 0 && m_right == 0 && m_bottom == 0)
        return;
    m_left = 0;
    m_top = 0;
    m_right = 0;
    m_bottom = 0;
    emit insetsChanged();
    return;
#endif

    int left = 0;
    int top = 0;
    int right = 0;
    int bottom = 0;

    if(m_window && m_window->handle())
    {
        const QMargins margins = m_window->handle()->safeAreaMargins();
        left = margins.left();
        top = margins.top();
        right = margins.right();
        bottom = margins.bottom();
        if(m_window->width() > 0 && m_window->height() > 0)
        {
            // Android can report the available rectangle instead of inset widths.
            const int limit = qMax(1, qMin(m_window->width(), m_window->height()) / 3);
            if(left > limit)
                left = 0;
            if(top > limit)
                top = 0;
            if(right > limit)
                right = 0;
            if(bottom > limit)
                bottom = 0;
        }
    }

    if(m_window && m_window->screen())
    {
        const QRect full = m_window->screen()->geometry();
        const QRect available = m_window->screen()->availableGeometry();
        left = qMax(left, qMax(0, available.left() - full.left()));
        top = qMax(top, qMax(0, available.top() - full.top()));
        right = qMax(right, qMax(0, (full.left() + full.width()) - (available.left() + available.width())));
        bottom = qMax(bottom, qMax(0, (full.top() + full.height()) - (available.top() + available.height())));
    }

    if(left == m_left && top == m_top && right == m_right && bottom == m_bottom)
        return;

    m_left = left;
    m_top = top;
    m_right = right;
    m_bottom = bottom;
    emit insetsChanged();
}

} // namespace workorder
