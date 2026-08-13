import QtQuick
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskPluginSignals {
    id: signalHandlerSignals

    Component.onCompleted: {
        var lang = UniDeskSettings.get("language", Settings.pluginId) || "zh_CN"
        BackendAll.retranslate(signalHandlerSignals, lang)
    }

    onLanguageChanged: {
        var lang = UniDeskSettings.get("language", Settings.pluginId) || "zh_CN"
        BackendAll.retranslate(signalHandlerSignals, lang)
    }

    
}