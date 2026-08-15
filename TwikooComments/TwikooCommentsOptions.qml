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
    title: qsTr("Twikoo Comments Options")
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
                    text: qsTr("MongoDB Cluster URI")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskTextField{
                    id: clusterUriField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    text: editingComponent ? editingComponent.clusterUri : "mongodb://localhost:27017"
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.clusterUri = text;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("Database")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskTextField{
                    id: databaseField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    text: editingComponent ? editingComponent.database : "test"
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.database = text;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("Collection")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskTextField{
                    id: collectionField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    text: editingComponent ? editingComponent.collection : "comment"
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.collection = text;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("Page URL Prefix")
                    font: UniDeskTextStyle.little
                    Layout.alignment: Qt.AlignVCenter
                }
                Item{
                    Layout.fillWidth: true
                }
                UniDeskTextField{
                    id: pageIdField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    text: editingComponent ? editingComponent.pageId : "/"
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.pageId = text;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Blog URL")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Do not add trailing slash (e.g. https://example.com)")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                        Layout.alignment: Qt.AlignLeft
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskTextField{
                    id: blogUrlField
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    text: editingComponent ? editingComponent.blogUrl : ""
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.blogUrl = text;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Item{ Layout.fillWidth: true }
                UniDeskButton{
                    text: qsTr("Test Connection")
                    enabled: editingComponent ? editingComponent.clusterUri.length > 0 : false
                    onClicked: {
                        if (editingComponent) {
                            editingComponent.testConnection();
                        }
                    }
                }
                UniDeskButton{
                    text: qsTr("Load Comments")
                    enabled: editingComponent ? editingComponent.clusterUri.length > 0 : false
                    onClicked: {
                        if (editingComponent) {
                            editingComponent.saveComToFile();
                            editingComponent.fetchComments();
                        }
                    }
                }
            }
        }
    }
}