import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskComBase{
    id: base
    visible: true
    width: 400
    height: 300

    property int bandCount: 32
    property bool autoStart: true
    property real barGap: 2
    property real minBarHeight: 2
    property color barColor: UniDeskSettings.primaryColor

    chosen: comManager.selectMode===UniDeskComponentSelectMode.NoSelect ? (optionsWindow.visible) : selected

    property var _smoothedBands: []

    AudioVisualizerBackend{
        id: backend
        bandCount: base.bandCount

        onBandsUpdated: function(bands) {
            var smoothed = base._smoothedBands.slice();
            if (smoothed.length !== bands.length) {
                smoothed = [];
                for (var i = 0; i < bands.length; i++) smoothed.push(0);
            }
            for (var i = 0; i < bands.length; i++) {
                var target = bands[i] || 0;
                smoothed[i] = smoothed[i] * 0.7 + target * 0.3;
            }
            base._smoothedBands = smoothed;
        }
        onErrorOccurred: function(error) {
            console.log("AudioVisualizer error:", error);
        }
    }

    onBandCountChanged: function() {
        backend.setBandCount(bandCount);
        _smoothedBands = [];
    }

    Component.onCompleted: {
        if (autoStart) {
            backend.start();
        }
    }

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout{
            width: parent.width
            spacing: 10
            UniDeskText{
                text: qsTr("Audio Visualizer")
                font.pixelSize: 16
                font.bold: true
            }
            Item{ Layout.fillWidth: true }
            Rectangle{
                width: 8
                height: 8
                radius: 4
                color: backend.running ? "#4CAF50" : "#F44336"
            }
            UniDeskText{
                text: backend.running ? qsTr("Listening") : qsTr("Stopped")
                color: backend.running ? "#4CAF50" : "#F44336"
                font.pixelSize: 12
            }
            UniDeskButton{
                display: Button.TextOnly
                contentText: backend.running ? qsTr("Stop") : qsTr("Start")
                bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.2) : Qt.rgba(0,0,0,0.5).lighter(1.2)
                bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.5) : Qt.rgba(0,0,0,0.5).lighter(1.5)
                borderWidth: 1
                borderColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                onClicked: {
                    if (backend.running) {
                        backend.stop();
                    } else {
                        backend.start();
                    }
                }
            }
        }

        Rectangle{
            id: vizArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: UniDeskGlobals.isLight ? Qt.rgba(0.95,0.95,0.95,0.9) : Qt.rgba(0.15,0.15,0.15,0.9)
            border.color: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
            border.width: 1

            Item{
                id: vizContent
                anchors.fill: parent
                anchors.leftMargin: base.barGap
                anchors.rightMargin: base.barGap
                anchors.bottomMargin: base.barGap
                clip: true

                property real barCount: base._smoothedBands.length
                property real gap: base.barGap
                property real minH: base.minBarHeight

                Repeater{
                    id: barRepeater
                    anchors.fill: parent
                    model: base._smoothedBands

                    delegate: Rectangle{
                        width: Math.max(1, (barRepeater.width - vizContent.gap * (vizContent.barCount - 1)) / Math.max(1, vizContent.barCount))
                        height: Math.max(vizContent.minH, (modelData || 0) * barRepeater.height * 0.95)
                        x: index * (width + vizContent.gap)
                        y: barRepeater.height - height
                        radius: Math.min(width / 2, 4)

                        gradient: Gradient{
                            GradientStop{ position: 0.0; color: base.barColor }
                            GradientStop{ position: 1.0; color: Qt.rgba(base.barColor.r, base.barColor.g, base.barColor.b, 0.4) }
                        }
                    }
                }
            }
        }
    }

    optionsWindow: AudioVisualizerOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }

    function propertyDataEx(){
        return {
            "bandCount": base.bandCount,
            "autoStart": base.autoStart,
            "barGap": base.barGap,
            "minBarHeight": base.minBarHeight
        }
    }

    function loadPropertyDataEx(data){
        if(data.bandCount!==undefined){base.bandCount=data.bandCount;}
        if(data.autoStart!==undefined){base.autoStart=data.autoStart;}
        if(data.barGap!==undefined){base.barGap=data.barGap;}
        if(data.minBarHeight!==undefined){base.minBarHeight=data.minBarHeight;}
    }
}