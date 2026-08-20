import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import UniDesk.Singletons
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskComBase{
    id: base
    visible: true
    width: 400
    height: 250

    chosen: comManager.selectMode===UniDeskComponentSelectMode.NoSelect ? (optionsWindow.visible) : selected

    property int sourceType: 0
    property string dataExpression: "%cpuPercent"
    property string apiUrl: ""
    property string apiExpression: "response.data.value"
    property bool autoRefreshOnStart: true
    property int refreshInterval: 0
    property int refreshUnit: 1
    property int maxDataPoints: 60
    property real barGap: 10
    property string chartTitle: "Line Chart"
    property bool showBackground: true
    property string valueUnit: ""
    property string valueExpression: "%{value}"
    property color lineColor: UniDeskSettings.primaryColor
    property real lineWidth: 2
    property real pointSize: 3
    property bool showGrid: true
    property color gridColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.1) : Qt.rgba(1,1,1,0.1)
    property color chartBgColor: UniDeskGlobals.isLight ? Qt.rgba(0.95,0.95,0.95,0.9) : Qt.rgba(0.12,0.12,0.12,0.9)
    property color axisColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.3) : Qt.rgba(1,1,1,0.3)
    property real currentValue: 0
    property string currentValueText: "--"

    property var _dataPoints: []
    property real _minValue: 0
    property real _maxValue: 100
    property int _dataPointCount: 0

    function getRefreshIntervalMs() {
        var interval = base.refreshInterval;
        if (interval <= 0) return 0;
        var unit = base.refreshUnit;
        var ms = 0;
        if (unit === 0) ms = interval;
        else if (unit === 1) ms = interval * 1000;
        else if (unit === 2) ms = interval * 60 * 1000;
        else if (unit === 3) ms = interval * 3600 * 1000;
        if (base.sourceType === 1 && ms < 10000) return 0;
        return ms;
    }

    function fetchData() {
        if (base.sourceType === 0) {
            fetchExpressionData();
        } else {
            fetchApiData();
        }
    }

    function fetchExpressionData() {
        try {
            var expr = base.dataExpression || "0";
            var result = UniDeskExpr.convertStr(expr);
            var value = parseFloat(result);
            if (isNaN(value)) value = 0;
            base.currentValue = value;
            base.currentValueText = base.formatValueText(value);
            addDataPoint(value);
        } catch(e) {
            console.log("LineChart expression error:", e);
        }
    }

    function fetchApiData() {
        var url = base.apiUrl;
        var expr = base.apiExpression;
        if (!url || !expr) return;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var result = UniDeskExpr.evalResponse(xhr.responseText, expr);
                        var value = parseFloat(result);
                        if (isNaN(value)) value = 0;
                        base.currentValue = value;
                        base.currentValueText = base.formatValueText(value);
                        addDataPoint(value);
                    } catch(e) {
                        console.log("LineChart API parse error:", e);
                    }
                } else {
                    console.log("LineChart API HTTP error:", xhr.status);
                }
            }
        };
        xhr.open("GET", url, true);
        xhr.send();
    }

    function formatValueText(value) {
        try {
            var text = base.valueExpression || "%{value}";
            var result = UniDeskExpr.convertStr(text, {"value": value});
            if (result !== undefined && result !== null && result !== "") return result.toString();
            return value.toString();
        } catch(e) {
            return value.toString();
        }
    }

    function addDataPoint(value) {
        var now = Date.now();
        var points = base._dataPoints.slice();
        points.push({time: now, value: value});
        while (points.length > base.maxDataPoints) {
            points.shift();
        }
        base._dataPoints = points;
        base._dataPointCount = points.length;
        recalcRange();
        chartCanvas.requestPaint();
    }

    function recalcRange() {
        var points = base._dataPoints;
        if (points.length === 0) {
            base._minValue = 0;
            base._maxValue = 100;
            return;
        }
        var min = points[0].value;
        var max = points[0].value;
        for (var i = 1; i < points.length; i++) {
            if (points[i].value < min) min = points[i].value;
            if (points[i].value > max) max = points[i].value;
        }
        if (min === max) {
            base._minValue = min - 1;
            base._maxValue = max + 1;
        } else {
            var range = max - min;
            base._minValue = min - range * 0.1;
            base._maxValue = max + range * 0.1;
        }
    }

    function getPointX(index) {
        var points = base._dataPoints;
        var pad = Math.max(30, base.lineWidth + 4);
        if (points.length <= 1) return chartArea.width / 2;
        var usable = Math.max(1, chartArea.width - pad * 2);
        return pad + (index / (points.length - 1)) * usable;
    }

    function getPointY(value) {
        var pad = Math.max(6, base.lineWidth + 4);
        var bottomPad = Math.max(16, base.barGap);
        var h = Math.max(1, chartArea.height - pad - bottomPad);
        var range = base._maxValue - base._minValue;
        if (range === 0) return pad + h / 2;
        var normalized = (value - base._minValue) / range;
        return pad + h - normalized * h;
    }

    function drawChart(ctx) {
        var w = chartCanvas.width;
        var h = chartCanvas.height;
        var points = base._dataPoints;
        var count = points.length;

        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, w, h);

        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";

        ctx.save();
        ctx.beginPath();
        ctx.rect(0, 0, w, h);
        ctx.clip();

        if (base.showGrid) {
            ctx.strokeStyle = base.gridColor;
            ctx.lineWidth = 1;
            for (var g = 1; g <= 5; g++) {
                var gy = Math.round(g * h / 6) + 0.5;
                ctx.beginPath();
                ctx.moveTo(0, gy);
                ctx.lineTo(w, gy);
                ctx.stroke();
            }
        }

        if (count > 1) {
            ctx.strokeStyle = base.lineColor;
            ctx.lineWidth = base.lineWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(getPointX(0), getPointY(points[0].value));
            for (var i = 1; i < count; i++) {
                ctx.lineTo(getPointX(i), getPointY(points[i].value));
            }
            ctx.stroke();
        }

        if (count > 0) {
            ctx.fillStyle = base.lineColor;
            var pointRadius = Math.max(1, base.pointSize);
            for (var j = 0; j < count; j++) {
                ctx.beginPath();
                ctx.arc(getPointX(j), getPointY(points[j].value), pointRadius, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        if (count >= 2) {
            ctx.fillStyle = base.gridColor;
            ctx.font = "9px sans-serif";
            ctx.textBaseline = "top";
            ctx.textAlign = "center";
            var minLabelSpacing = 70;
            var maxLabels = Math.min(4, count);
            var widthBased = Math.max(2, Math.floor(w / minLabelSpacing));
            var labelCount = Math.min(maxLabels, widthBased);
            var bottomPad = Math.max(16, base.barGap);
            for (var l = 0; l < labelCount; l++) {
                var idx = Math.round(l * (count - 1) / Math.max(1, labelCount - 1));
                var lx = getPointX(idx);
                var time = new Date(points[idx].time);
                var hh = time.getHours();
                var mm = time.getMinutes();
                var ss = time.getSeconds();
                var label = (hh < 10 ? "0" : "") + hh + ":" + (mm < 10 ? "0" : "") + mm + ":" + (ss < 10 ? "0" : "") + ss;
                ctx.fillText(label, lx, h - bottomPad);
            }
        }

        ctx.restore();
    }

    Timer{
        id: refreshTimer
        repeat: true
        onTriggered: base.fetchData()
    }

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout{
            width: parent.width
            spacing: 10
            UniDeskText{
                text: base.chartTitle
                font.pixelSize: 16
                font.bold: true
            }
            Item{ Layout.fillWidth: true }
            UniDeskText{
                text: base.currentValueText
                font.pixelSize: 14
                font.bold: true
                color: base.lineColor
            }
        }

        Item{
            id: chartContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle{
                anchors.fill: parent
                radius: 8
                color: base.showBackground ? base.chartBgColor : "transparent"
                border.color: base.showBackground ? base.axisColor : "transparent"
                border.width: base.showBackground ? 1 : 0

                Item{
                    id: chartArea
                    anchors.fill: parent
                    anchors.leftMargin: base.barGap
                    anchors.rightMargin: base.barGap
                    anchors.bottomMargin: base.barGap

                    Canvas{
                        id: chartCanvas
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d");
                            base.drawChart(ctx);
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        base.updateRefreshTimer();
        if (base.autoRefreshOnStart) {
            base.fetchData();
        }
    }

    function updateRefreshTimer() {
        var ms = base.getRefreshIntervalMs();
        if (ms > 0) {
            refreshTimer.interval = ms;
            refreshTimer.start();
        } else {
            refreshTimer.stop();
        }
    }

    onRefreshIntervalChanged: {
        base.updateRefreshTimer();
    }

    onRefreshUnitChanged: {
        base.updateRefreshTimer();
    }

    onLineWidthChanged: chartCanvas.requestPaint();
    onPointSizeChanged: chartCanvas.requestPaint();
    onShowGridChanged: chartCanvas.requestPaint();
    onLineColorChanged: chartCanvas.requestPaint();
    onGridColorChanged: chartCanvas.requestPaint();
    onShowBackgroundChanged: chartCanvas.requestPaint();
    onBarGapChanged: chartCanvas.requestPaint();
    onMaxDataPointsChanged: chartCanvas.requestPaint();
    onValueExpressionChanged: {
        if (_dataPoints.length > 0) {
            currentValueText = formatValueText(currentValue);
        }
    }

    onCloseSignal: {
        refreshTimer.stop();
    }

    optionsWindow: LineChartOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }

    function propertyDataEx(){
        return {
            "sourceType": base.sourceType,
            "dataExpression": base.dataExpression,
            "apiUrl": base.apiUrl,
            "apiExpression": base.apiExpression,
            "autoRefreshOnStart": base.autoRefreshOnStart,
            "refreshInterval": base.refreshInterval,
            "refreshUnit": base.refreshUnit,
            "maxDataPoints": base.maxDataPoints,
            "barGap": base.barGap,
            "chartTitle": base.chartTitle,
            "showBackground": base.showBackground,
            "valueExpression": base.valueExpression,
            "lineColorR": base.lineColor.r,
            "lineColorG": base.lineColor.g,
            "lineColorB": base.lineColor.b,
            "lineColorA": base.lineColor.a,
            "lineWidth": base.lineWidth,
            "pointSize": base.pointSize,
            "showGrid": base.showGrid
        };
    }

    function loadPropertyDataEx(data){
        if(data.sourceType!==undefined){base.sourceType=data.sourceType;}
        if(data.dataExpression!==undefined){base.dataExpression=data.dataExpression;}
        if(data.apiUrl!==undefined){base.apiUrl=data.apiUrl;}
        if(data.apiExpression!==undefined){base.apiExpression=data.apiExpression;}
        if(data.autoRefreshOnStart!==undefined){base.autoRefreshOnStart=data.autoRefreshOnStart;}
        if(data.refreshInterval!==undefined){base.refreshInterval=data.refreshInterval;}
        if(data.refreshUnit!==undefined){base.refreshUnit = data.refreshUnit;}
        if(data.maxDataPoints!==undefined){base.maxDataPoints=data.maxDataPoints;}
        if(data.barGap!==undefined){base.barGap=data.barGap;}
        if(data.chartTitle!==undefined){base.chartTitle=data.chartTitle;}
        if(data.showBackground!==undefined){base.showBackground=data.showBackground;}
        if(data.valueExpression!==undefined){base.valueExpression=data.valueExpression;}
        else if(data.valueUnit!==undefined && data.valueUnit.length>0){base.valueExpression="%{value} "+data.valueUnit;}
        if(data.lineColorR!==undefined){base.lineColor=Qt.rgba(data.lineColorR,data.lineColorG,data.lineColorB,data.lineColorA);}
        if(data.lineWidth!==undefined){base.lineWidth=data.lineWidth;}
        if(data.pointSize!==undefined){base.pointSize=data.pointSize;}
        if(data.showGrid!==undefined){base.showGrid=data.showGrid;}
        base.updateRefreshTimer();
    }
}