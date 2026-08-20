import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons

UniDeskWindow{
    id: window
    width: 1000
    height: 750
    title: qsTr("Line Chart Options")
    autoVisible: false
    showMinimize: false
    showMaximize: false
    autoDestroy: false
    property var comManager
    property UniDeskComBase editingComponent

    ScrollView{
        anchors.fill: parent
        hoverEnabled: true
        contentHeight: settingsColumn.height + settingsColumn.y + 20

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
                        text: qsTr("Data Source Type")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Expression: Use UniDeskExpr to get values. API: Fetch from an HTTP endpoint.")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskComboBox{
                    comManager: window.comManager
                    model: [qsTr("Expression"), qsTr("API")]
                    currentIndex: editingComponent ? editingComponent.sourceType : 0
                    onActivated: {
                        if (editingComponent) {
                            editingComponent.sourceType = currentIndex;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            Column{
                width: parent.width
                spacing: 8
                visible: (editingComponent ? editingComponent.sourceType : 0) === 0

                UniDeskText{
                    text: qsTr("Expression Mode")
                    font.pixelSize: 13
                    font.bold: true
                }

                RowLayout{
                    width: parent.width
                    spacing: 10
                    UniDeskText{
                        text: qsTr("Expression")
                        font: UniDeskTextStyle.little
                    }
                    Item{ Layout.fillWidth: true }
                    UniDeskTextField{
                        Layout.fillWidth: true
                        text: editingComponent ? editingComponent.dataExpression : ""
                        placeholderText: qsTr("e.g. %CpuPercent")
                        onEditingFinished: {
                            if (editingComponent) {
                                editingComponent.dataExpression = text;
                                editingComponent.saveComToFile();
                            }
                        }
                    }
                }

                UniDeskText{
                    text: qsTr("Use UniDeskExpr expression syntax. Available variables: %CpuPercent, %MemoryUsed, etc.")
                    font.pixelSize: 10
                    color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            Column{
                width: parent.width
                spacing: 8
                visible: (editingComponent ? editingComponent.sourceType : 0) === 1

                UniDeskText{
                    text: qsTr("API Mode")
                    font.pixelSize: 13
                    font.bold: true
                }

                RowLayout{
                    width: parent.width
                    spacing: 10
                    UniDeskText{
                        text: qsTr("API URL")
                        font: UniDeskTextStyle.little
                    }
                    Item{ Layout.fillWidth: true }
                    UniDeskTextField{
                        Layout.fillWidth: true
                        text: editingComponent ? editingComponent.apiUrl : ""
                        placeholderText: qsTr("https://api.example.com/data")
                        onEditingFinished: {
                            if (editingComponent) {
                                editingComponent.apiUrl = text;
                                editingComponent.saveComToFile();
                            }
                        }
                    }
                }

                RowLayout{
                    width: parent.width
                    spacing: 10
                    UniDeskText{
                        text: qsTr("Extraction Expression")
                        font: UniDeskTextStyle.little
                    }
                    Item{ Layout.fillWidth: true }
                    UniDeskTextField{
                        Layout.fillWidth: true
                        text: editingComponent ? editingComponent.apiExpression : ""
                        placeholderText: qsTr("response.data.value")
                        onEditingFinished: {
                            if (editingComponent) {
                                editingComponent.apiExpression = text;
                                editingComponent.saveComToFile();
                            }
                        }
                    }
                }

                UniDeskText{
                    text: qsTr("Use dot notation to access response fields. Example: response.data[0].value")
                    font.pixelSize: 10
                    color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Refresh on Start")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Fetch data once when component loads")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskCheckBox{
                    checked: editingComponent ? editingComponent.autoRefreshOnStart : true
                    onToggled: {
                        if (editingComponent) {
                            editingComponent.autoRefreshOnStart = checked;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                visible: (editingComponent ? editingComponent.sourceType : 0) === 0
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Refresh Interval")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Set to 0 to disable auto-refresh")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSpinBox{
                    id: intervalSpinExpr
                    editable: true
                    from: 0
                    to: {
                        var u = editingComponent ? editingComponent.refreshUnit : 1;
                        if (u === 0) return 3600000;
                        if (u === 1) return 3600;
                        if (u === 2) return 60;
                        if (u === 3) return 24;
                        return 3600;
                    }
                    stepSize: {
                        var u = editingComponent ? editingComponent.refreshUnit : 1;
                        if (u === 0) return 100;
                        return 1;
                    }
                    value: editingComponent ? editingComponent.refreshInterval : 0
                    onValueModified: {
                        if (editingComponent) {
                            editingComponent.refreshInterval = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskComboBox{
                    comManager: window.comManager
                    model: [qsTr("Milliseconds"), qsTr("Seconds"), qsTr("Minutes"), qsTr("Hours")]
                    currentIndex: editingComponent ? editingComponent.refreshUnit : 1
                    onActivated: {
                        if (editingComponent) {
                            editingComponent.refreshUnit = currentIndex;
                            var maxVals = [3600000, 3600, 60, 24];
                            if (editingComponent.refreshInterval > maxVals[currentIndex]) {
                                editingComponent.refreshInterval = maxVals[currentIndex];
                            }
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                visible: (editingComponent ? editingComponent.sourceType : 0) === 1
                Column{
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Refresh Interval")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Minimum 10 seconds for API requests")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSpinBox{
                    id: intervalSpinApi
                    editable: true
                    from: {
                        var u = editingComponent ? editingComponent.refreshUnit : 1;
                        if (u === 1) return 10;
                        return 1;
                    }
                    to: {
                        var u = editingComponent ? editingComponent.refreshUnit : 1;
                        if (u === 1) return 3600;
                        if (u === 2) return 60;
                        if (u === 3) return 24;
                        return 3600;
                    }
                    stepSize: 1
                    value: editingComponent ? Math.max(from, editingComponent.refreshInterval) : 10
                    onValueModified: {
                        if (editingComponent) {
                            editingComponent.refreshInterval = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskComboBox{
                    comManager: window.comManager
                    model: [qsTr("Seconds"), qsTr("Minutes"), qsTr("Hours")]
                    currentIndex: editingComponent ? Math.max(0, editingComponent.refreshUnit - 1) : 0
                    onActivated: {
                        if (editingComponent) {
                            editingComponent.refreshUnit = currentIndex + 1;
                            var maxVals = [3600, 60, 24];
                            var minVals = [10, 1, 1];
                            if (editingComponent.refreshInterval > maxVals[currentIndex]) {
                                editingComponent.refreshInterval = maxVals[currentIndex];
                            }
                            if (editingComponent.refreshInterval < minVals[currentIndex]) {
                                editingComponent.refreshInterval = minVals[currentIndex];
                            }
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                UniDeskText{
                    text: qsTr("Chart Title")
                    font: UniDeskTextStyle.little
                }
                Item{ Layout.fillWidth: true }
                UniDeskTextField{
                    Layout.fillWidth: true
                    text: editingComponent ? editingComponent.chartTitle : ""
                    placeholderText: qsTr("Line Chart")
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.chartTitle = text;
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
                        text: qsTr("Show Background")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Display chart background and border")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskCheckBox{
                    checked: editingComponent ? editingComponent.showBackground : true
                    onToggled: {
                        if (editingComponent) {
                            editingComponent.showBackground = checked;
                            editingComponent.saveComToFile();
                        }
                    }
                }
            }

            RowLayout{
                width: parent.width
                spacing: 10
                Column{
                    spacing: 2
                    UniDeskText{
                        text: qsTr("Value Expression")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Use %{value} to represent the fetched value")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskTextField{
                    Layout.fillWidth: true
                    text: editingComponent ? editingComponent.valueExpression : "%{value}"
                    placeholderText: qsTr("e.g. %{value}%%")
                    onEditingFinished: {
                        if (editingComponent) {
                            editingComponent.valueExpression = text;
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
                        text: qsTr("Max Data Points")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Number of data points to display on the chart")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 5
                    to: 300
                    stepSize: 1
                    value: editingComponent ? editingComponent.maxDataPoints : 60
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.maxDataPoints = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.maxDataPoints) : "60"
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
                        text: qsTr("Line Width")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Thickness of the chart line")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 1
                    to: 10
                    stepSize: 1
                    value: editingComponent ? editingComponent.lineWidth : 2
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.lineWidth = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.lineWidth) : "2"
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
                        text: qsTr("Point Size")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Size of data point markers")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskSlider{
                    from: 1
                    to: 10
                    stepSize: 1
                    value: editingComponent ? editingComponent.pointSize : 3
                    onValueChanged: {
                        if (editingComponent) {
                            editingComponent.pointSize = value;
                            editingComponent.saveComToFile();
                        }
                    }
                }
                UniDeskText{
                    text: editingComponent ? String(editingComponent.pointSize) : "3"
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
                        text: qsTr("Show Grid")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Display grid lines on the chart")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskCheckBox{
                    checked: editingComponent ? editingComponent.showGrid : true
                    onToggled: {
                        if (editingComponent) {
                            editingComponent.showGrid = checked;
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
                        text: qsTr("Line Color")
                        font: UniDeskTextStyle.little
                    }
                    UniDeskText{
                        text: qsTr("Color of the chart line and points")
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                    }
                }
                Item{ Layout.fillWidth: true }
                UniDeskColorPicker{
                    selectedColor: editingComponent ? editingComponent.lineColor : UniDeskSettings.primaryColor
                    onSelectedColorChanged: {
                        if (editingComponent) {
                            editingComponent.lineColor = selectedColor;
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
                    display: Button.TextOnly
                    contentText: qsTr("Clear Data")
                    bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.2) : Qt.rgba(0,0,0,0.5).lighter(1.2)
                    bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.5) : Qt.rgba(0,0,0,0.5).lighter(1.5)
                    borderWidth: 1
                    borderColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                    onClicked: {
                        if (editingComponent) {
                            editingComponent._dataPoints = [];
                            editingComponent._dataPointCount = 0;
                            editingComponent._minValue = 0;
                            editingComponent._maxValue = 100;
                        }
                    }
                }
            }
        }
    }
}