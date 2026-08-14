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
    property int fadeDelay: 1500
    property int fadeDuration: 400

    ListModel{
        id: keysModel
    }

    TypingFollowerBackend{
        id: backend
        onKeyPressed:(key) => {
            base.handlePressed(key)
        }
        onKeyReleased:(key) => {
            base.handleReleased(key)
        }
        onMousePressed:(button) => {
            base.handlePressed(button)
        }
        onMouseReleased:(button) => {
            base.handleReleased(button)
        }
    }

    function handlePressed(text) {
        for (var i = 0; i < keysModel.count; i++) {
            var item = keysModel.get(i)
            if (item.text === text && item.releasedAt === 0) {
                return
            }
        }
        var uniqueId = 'key_' + Date.now() + '_' + Math.floor(Math.random() * 10000)
        keysModel.append({
            id: uniqueId,
            text: text,
            releasedAt: 0
        })
    }

    function handleReleased(text) {
        for (var i = 0; i < keysModel.count; i++) {
            var item = keysModel.get(i)
            if (item.text === text && item.releasedAt === 0) {
                keysModel.setProperty(i, "releasedAt", Date.now())
                break
            }
        }
    }

    function removeKeyById(keyId) {
        for (var i = 0; i < keysModel.count; i++) {
            if (keysModel.get(i).id === keyId) {
                keysModel.remove(i)
                break
            }
        }
    }

    Item{
        width: base.width
        height: base.height
        Column{
            spacing: 10
            Repeater{
                model: keysModel
                delegate: Rectangle{
                    id: keyDelegate
                    radius: 8
                    opacity: 1.0
                    color: UniDeskGlobals.isLight ? Qt.rgba(0.2,0.2,0.2,0.85) : Qt.rgba(0.9,0.9,0.9,0.85)

                    property string delegateId: model.id
                    property string delegateText: model.text
                    property bool delegateReleased: model.releasedAt > 0

                    onDelegateReleasedChanged: {
                        if (delegateReleased) {
                            var elapsed = Date.now() - model.releasedAt
                            removalTimer.interval = Math.max(0, base.fadeDelay - elapsed)
                            removalTimer.start()
                        } else {
                            removalTimer.stop()
                            fadeOut.stop()
                            keyDelegate.opacity = 1.0
                        }
                    }

                    Row{
                        id: contentRow
                        spacing: 8
                        x: 8
                        y: 8

                        Rectangle{
                            width: 8
                            height: 8
                            radius: 4
                            color: UniDeskSettings.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        UniDeskText{
                            text: keyDelegate.delegateText
                            font.pixelSize: 16
                            color: UniDeskGlobals.isLight ? "#ffffff" : "#222222"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    width: Math.max(40, contentRow.width + 16)
                    height: Math.max(20, contentRow.height + 16)

                    Timer{
                        id: removalTimer
                        repeat: false
                        onTriggered: fadeOut.start()
                    }

                    SequentialAnimation{
                        id: fadeOut
                        NumberAnimation{
                            target: keyDelegate
                            property: "opacity"
                            from: 1.0
                            to: 0
                            duration: base.fadeDuration
                        }
                        ScriptAction{
                            script: base.removeKeyById(keyDelegate.delegateId)
                        }
                    }

                    Component.onCompleted: {
                        if (delegateReleased) {
                            var elapsed = Date.now() - model.releasedAt
                            removalTimer.interval = Math.max(0, base.fadeDelay - elapsed)
                            removalTimer.start()
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        backend.listening = true
    }

    Component.onDestruction: {
        backend.listening = false
    }

    optionsWindow: TypingFollowerOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }

}