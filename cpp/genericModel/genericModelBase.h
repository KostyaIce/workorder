#ifndef WORKORDER_GENERIC_MODEL_BASE_H
#define WORKORDER_GENERIC_MODEL_BASE_H

#include <QAbstractListModel>
#include <QObject>

namespace workorder
{

class GenericBridgeBase : public QObject
{
    Q_OBJECT

public:
    explicit GenericBridgeBase(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

signals:
    void valueChanged(const QString &fieldName);
};

class GenericModelBase : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit GenericModelBase(QObject *parent = nullptr)
        : QAbstractListModel(parent)
    {
    }

    Q_PROPERTY(int size READ size NOTIFY sizeChanged)
    Q_PROPERTY(int count READ count NOTIFY sizeChanged)

    Q_INVOKABLE virtual QVariantMap getObject(int index) const = 0;
    Q_INVOKABLE virtual QVariant get(int index) = 0;
    Q_INVOKABLE virtual QVariant get(int index) const = 0;
    Q_INVOKABLE virtual void clear() = 0;
    Q_INVOKABLE virtual bool isEmpty() const = 0;
    Q_INVOKABLE virtual int size() const = 0;
    Q_INVOKABLE virtual int count() const = 0;

signals:
    void sizeChanged();
    void sigSizeChanged(int newSize);
    void sigItemAdded(int itemIndex);
    void sigItemRemoved(int itemIndex);
    void sigItemChanged(int itemIndex);
};

} // namespace workorder

#endif // WORKORDER_GENERIC_MODEL_BASE_H
