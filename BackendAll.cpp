#include "BackendAll.h"
#include <QTranslator>
#include <QCoreApplication>
#include <QQmlEngine>

BackendAll::BackendAll(QObject *parent)
    : QObject(parent)
{
    m_translator = new QTranslator(this);
    QCoreApplication::installTranslator(m_translator);
}

void BackendAll::retranslate(const QObject *object, const QString &language)
{
    QQmlEngine *engine = qmlEngine(object);
    if (engine) {
        m_translator->load(":/uniquenium/officialplugin/i18n/BackendAll_" + language);
        engine->retranslate();
    }
}

