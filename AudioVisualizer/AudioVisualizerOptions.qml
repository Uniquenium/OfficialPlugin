import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Templates as T
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons

UniDeskWindow{
    id: window
    width: 1000
    height: 700
    title: qsTr("Audio Visualizer Options")
    autoVisible: false
    showMinimize: false
    showMaximize: false
    autoDestroy: false
    property var comManager
    property UniDeskComBase editingComponent
    ScrollView{
        anchors.fill: parent
        hoverEnabled: true
        contentHeight: settingsColumn.height+settingsColumn.y+20
        UniDeskComBasicOptions{
            id: basicOptions
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 10
            comManager: window.comManager
            editingComponent: window.editingComponent
        }
        Column{
            id: settingsColumn
            anchors.top: basicOptions.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 10

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Band Count")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Number of frequency bands (4-64)")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 4
                    to: 64
                    stepSize: 1
                    value: editingComponent ? editingComponent.bandCount : 32
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.bandCount = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.bandCount) : "32"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.minimumWidth: 30
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Bar Gap")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Spacing between bars in pixels")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 0
                    to: 10
                    stepSize: 1
                    value: editingComponent ? editingComponent.barGap : 2
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.barGap = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.barGap) : "2"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.minimumWidth: 30
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Minimum Bar Height")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Minimum height of each bar in pixels")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 0
                    to: 20
                    stepSize: 1
                    value: editingComponent ? editingComponent.minBarHeight : 2
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.minBarHeight = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.minBarHeight) : "2"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.minimumWidth: 30
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Auto Start")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Start listening when component loads")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskCheckBox{
                    checked: editingComponent ? editingComponent.autoStart : true
                    onToggled: {
                        if (editingComponent) {
                            editingComponent.autoStart = checked;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }
        }
    }
}