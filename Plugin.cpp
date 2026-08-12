#include "Plugin.h"
#include "BackendAll.h"
#include "TypingFollower/TypingFollowerBackend.h"
#include <qqmlregistration.h>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QCoreApplication>

Plugin::Plugin()
{
}

Plugin::~Plugin()
{
}

void Plugin::registerQmlTypes(QQmlApplicationEngine *engine)
{
    Q_UNUSED(engine);
    QString URI = QStringLiteral("org.uniquenium.") + PLUGIN_NAME;
    char *URI2 = (char *)URI.toUtf8().data();
    qmlRegisterSingletonType<BackendAll>(URI2, 1, 0, "BackendAll", BackendAll::create);
    qmlRegisterType<TypingFollowerBackend>(URI2, 1, 0, "TypingFollowerBackend");
}


void Plugin::initialize()
{
    qDebug() << "Plugin initialized";
}