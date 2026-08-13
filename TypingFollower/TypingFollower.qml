import QtQuick
import QtQuick.Controls
import UniDesk
import UniDesk.Controls
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskComBase{
    id: base
    visible: true
    width: 300
    height: 300
    chosen: comManager.selectMode===UniDeskComponentSelectMode.NoSelect ? (optionsWindow.visible) : selected
    Rectangle {
        id: cont
        width: base.width
        height: base.height
        color: "#f0f0f0"
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                text: qsTr("Plugin Component")
                font.bold: true
                font.pixelSize: 20
                color: "#333"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TypingFollowerBackend {
                id: backend
            }

            Image{
                id: img
                source: "file:" + (pluginDir || "") + "/media/uniquenium-l-bg.png"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 175
                height: 34
            }

            Text {
                text: qsTr("Message: %1 ") + backend.message
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: qsTr("Counter: %1 ") + backend.counter
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: qsTr("Say Hello")
                onClicked: {
                    console.log(backend.sayHello("QML"))
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: qsTr("Increment")
                onClicked: {
                    backend.incrementCounter()
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: qsTr("Add 5+3")
                onClicked: {
                    console.log(qsTr("Result: %1 ") + backend.addNumbers(5, 3))
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    optionsWindow: TypingFollowerOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }
    
}