#include "Plugin.h"
#include "BackendAll.h"
#include "TypingFollower/TypingFollowerBackend.h"
#include "TwikooComments/TwikooCommentsBackend.h"
#include "AudioVisualizer/AudioVisualizerBackend.h"
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
    QByteArray uriBytes = URI.toUtf8();
    const char *URI2 = uriBytes.constData();
    qmlRegisterSingletonType<BackendAll>(URI2, 1, 0, "BackendAll", BackendAll::create);
    qmlRegisterType<TypingFollowerBackend>(URI2, 1, 0, "TypingFollowerBackend");
    qmlRegisterType<TwikooCommentsBackend>(URI2, 1, 0, "TwikooCommentsBackend");
    qmlRegisterType<AudioVisualizerBackend>(URI2, 1, 0, "AudioVisualizerBackend");
    qDebug() << "Plugin: registered QML types with URI:" << URI;
}


void Plugin::initialize()
{
    qDebug() << "Plugin initialized";
}