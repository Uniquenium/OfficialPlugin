#ifndef BACKENDALL_H
#define BACKENDALL_H

#include <QObject>
#include <QTranslator>
#include <QtQml/qqml.h>
#include "stdafx.h"
#include "singleton.h"

class QQmlEngine;
class QJSEngine;

class BackendAll : public QObject
{
    Q_OBJECT
    QML_SINGLETON
public:
    SINGLETON(BackendAll)
    static auto create(QQmlEngine*, QJSEngine*) { return getInstance(); }
    explicit BackendAll(QObject *parent = nullptr);

    Q_INVOKABLE void retranslate(const QObject *object, const QString &language);



private:
    QTranslator* m_translator;
};

#endif // BACKENDALL_H