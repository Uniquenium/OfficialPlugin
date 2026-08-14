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
    title: qsTr("输入跟随器选项")
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
                UniDeskText{
                    text: qsTr("淡出延迟(ms)")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskSpinBox{
                    Layout.alignment: Qt.AlignVCenter
                    editable: true
                    value: editingComponent ? editingComponent.fadeDelay : 1500
                    from: 0
                    to: 10000
                    stepSize: 100
                    onValueModified: {
                        if (editingComponent) {
                            editingComponent.fadeDelay = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }
            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("淡出时长(ms)")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskSpinBox{
                    Layout.alignment: Qt.AlignVCenter
                    editable: true
                    value: editingComponent ? editingComponent.fadeDuration : 400
                    from: 0
                    to: 5000
                    stepSize: 50
                    onValueModified: {
                        if (editingComponent) {
                            editingComponent.fadeDuration = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }
            UniDeskCheckBox{
                text: qsTr("监听鼠标")
                checked: editingComponent ? editingComponent.listenMouse : true
                onCheckedChanged: {
                    if (editingComponent) {
                        editingComponent.listenMouse = checked;
                        editingComponent.saveComToFile();
                    }
                }
            }
            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("显示顺序")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskComboBox{
                    comManager: window.comManager
                    model: [qsTr("从上到下"), qsTr("从下到上")]
                    currentIndex: editingComponent ? (editingComponent.displayOrder === "bottomToTop" ? 1 : 0) : 0
                    onActivated: {
                        if (editingComponent) {
                            editingComponent.displayOrder = currentIndex === 1 ? "bottomToTop" : "topToBottom";
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }
        }
    }
}