import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Templates as T
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskWindow{
    id: window
    width: 1000
    height: 700
    title: qsTr("Uniquenium官方插件包设置")
    autoVisible: false
    showMinimize: false
    showMaximize: false
    autoDestroy: false

    readonly property string pluginId: "uniquenium-official-plugin"

    ScrollView{
        anchors.fill: parent
        hoverEnabled: true
        clip: true
        contentHeight: columnLayout.childrenRect.height + 20

        ColumnLayout{
            id: columnLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10
            anchors.margins: 10

            UniDeskText{
                text: qsTr("显示语言")
                font: UniDeskTextStyle.little
                Layout.topMargin: 5
            }
            RowLayout{
                Layout.fillWidth: true
                spacing: 10
                UniDeskText{
                    text: qsTr("语言")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                UniDeskComboBox{
                    id: languageComboBox
                    Layout.fillWidth: true
                    model: ["中文", "English"]
                    currentIndex: ["zh_CN", "en_US"].indexOf(
                        UniDeskSettings.get("language", pluginId) || "zh_CN"
                    )
                    onActivated: {
                        var lang = ["zh_CN", "en_US"][currentIndex]
                        UniDeskSettings.set("language", lang, pluginId)
                        BackendAll.retranslate(window, lang)
                    }
                }
            }
        }
    }
}