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
    title: qsTr("待办列表选项")
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
                    text: qsTr("默认筛选")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskComboBox{
                    comManager: window.comManager
                    model: [qsTr("全部"), qsTr("未完成"), qsTr("已完成")]
                    currentIndex: editingComponent ? editingComponent.filterIndex : 0
                    onActivated: {
                        if (editingComponent) {
                            editingComponent.filterIndex = currentIndex;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }
        }
    }
}