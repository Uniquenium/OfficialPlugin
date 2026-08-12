#ifndef PLUGIN_H
#define PLUGIN_H

#include <QObject>
#include <UniDeskPluginInterface.h>

class Plugin : public QObject, public UniDeskPluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID UniDeskPluginInterface_iid)
    Q_INTERFACES(UniDeskPluginInterface)

public:
    Plugin();
    ~Plugin() override;

    void registerQmlTypes(QQmlApplicationEngine *engine) override;


    void initialize() override;
};

#endif // PLUGIN_H
