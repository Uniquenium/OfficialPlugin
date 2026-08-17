import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import UniDesk
import UniDesk.Controls
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskComBase{
    id: base
    visible: true
    width: 360
    height: 500
    chosen: comManager.selectMode===UniDeskComponentSelectMode.NoSelect ? (optionsWindow.visible) : selected

    property string inputText: ""
    property int filterIndex: 0
    property int completedCount: 0

    ListModel{
        id: todosModel
    }

    ListModel{
        id: filteredModel
    }

    function updateCompletedCount() {
        var count = 0;
        for (var i = 0; i < todosModel.count; i++) {
            if (todosModel.get(i).completed) count++;
        }
        base.completedCount = count;
    }

    function saveTodos() {
        base.saveComToFile();
    }

    function addTodo(text) {
        text = (text || "").trim();
        if (text.length === 0) return;
        todosModel.append({
            "text": text,
            "completed": false,
            "createdAt": Date.now()
        });
        base.inputText = "";
        base.saveTodos();
        base.updateCompletedCount();
        base.rebuildFilter();
    }

    function removeTodo(filteredIndex) {
        if (filteredIndex < 0 || filteredIndex >= filteredModel.count) return;
        var item = filteredModel.get(filteredIndex);
        var sourceIndex = item.sourceIndex;
        if (sourceIndex >= 0 && sourceIndex < todosModel.count) {
            todosModel.remove(sourceIndex);
            base.saveTodos();
            base.updateCompletedCount();
            base.rebuildFilter();
        }
    }

    function toggleTodo(filteredIndex) {
        if (filteredIndex < 0 || filteredIndex >= filteredModel.count) return;
        var item = filteredModel.get(filteredIndex);
        var sourceIndex = item.sourceIndex;
        if (sourceIndex >= 0 && sourceIndex < todosModel.count) {
            var current = todosModel.get(sourceIndex).completed;
            todosModel.setProperty(sourceIndex, "completed", !current);
            base.saveTodos();
            base.updateCompletedCount();
            base.rebuildFilter();
        }
    }

    function editTodo(filteredIndex, newText) {
        newText = (newText || "").trim();
        if (newText.length === 0) return;
        if (filteredIndex < 0 || filteredIndex >= filteredModel.count) return;
        var item = filteredModel.get(filteredIndex);
        var sourceIndex = item.sourceIndex;
        if (sourceIndex >= 0 && sourceIndex < todosModel.count) {
            todosModel.setProperty(sourceIndex, "text", newText);
            base.saveTodos();
            base.rebuildFilter();
        }
    }

    function clearCompleted() {
        var i = todosModel.count - 1;
        while (i >= 0) {
            if (todosModel.get(i).completed) {
                todosModel.remove(i);
            }
            i--;
        }
        base.saveTodos();
        base.updateCompletedCount();
        base.rebuildFilter();
    }

    function rebuildFilter() {
        filteredModel.clear();
        for (var i = 0; i < todosModel.count; i++) {
            var item = todosModel.get(i);
            if (filterIndex === 1 && item.completed) continue;
            if (filterIndex === 2 && !item.completed) continue;
            filteredModel.append({
                "text": item.text,
                "completed": item.completed || false,
                "createdAt": item.createdAt || 0,
                "sourceIndex": i
            });
        }
    }

    onFilterIndexChanged: rebuildFilter()

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout{
            width: parent.width
            spacing: 8
            UniDeskText{
                text: qsTr("Todo List")
                font.pixelSize: 16
                font.bold: true
            }
            Item{ Layout.fillWidth: true }
            UniDeskText{
                text: (todosModel.count - completedCount) + qsTr(" / ") + completedCount
                font.pixelSize: 10
                color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
            }
        }

        RowLayout{
            width: parent.width
            spacing: 8
            UniDeskTextField{
                id: inputField
                Layout.fillWidth: true
                text: base.inputText
                placeholderText: qsTr("添加新的待办事项...")
                onAccepted: base.addTodo(text)
            }
            UniDeskButton{
                display: Button.TextOnly
                contentText: qsTr("添加")
                bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.2) : Qt.rgba(0,0,0,0.5).lighter(1.2)
                bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.5) : Qt.rgba(0,0,0,0.5).lighter(1.5)
                borderWidth: 1
                borderColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                onClicked: base.addTodo(inputField.text)
            }
        }

        RowLayout{
            width: parent.width
            spacing: 6
            Repeater{
                model: [qsTr("全部"), qsTr("未完成"), qsTr("已完成")]
                delegate: UniDeskButton{
                    Layout.preferredWidth: 70
                    display: Button.TextOnly
                    contentText: modelData
                    checkable: true
                    checked: index === base.filterIndex
                    bgNormalColor: checked ? (UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.08) : Qt.rgba(1,1,1,0.08)) : "transparent"
                    bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.2) : Qt.rgba(0,0,0,0.5).lighter(1.2)
                    bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.5) : Qt.rgba(0,0,0,0.5).lighter(1.5)
                    borderWidth: 1
                    borderColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                    onClicked: {
                        base.filterIndex = index;
                        base.saveTodos();
                    }
                }
            }
            Item{ Layout.fillWidth: true }
            UniDeskButton{
                display: Button.TextOnly
                contentText: qsTr("清除已完成")
                enabled: completedCount > 0
                bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.2) : Qt.rgba(0,0,0,0.5).lighter(1.2)
                bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.5).darker(1.5) : Qt.rgba(0,0,0,0.5).lighter(1.5)
                borderWidth: 1
                borderColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                onClicked: base.clearCompleted()
            }
        }

        ListView{
            id: todosView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: filteredModel

            ScrollBar.vertical: ScrollBar{
                active: true
                policy: ScrollBar.AsNeeded
                width: 6
                anchors.right: parent.right
                anchors.rightMargin: 2
            }

            delegate: Rectangle{
                id: todoDelegate
                width: parent.width
                height: Math.max(todoRow.implicitHeight + 12, 50)
                radius: 6
                color: UniDeskGlobals.isLight ? Qt.rgba(0.96,0.96,0.96,0.95) : Qt.rgba(0.12,0.12,0.12,0.95)
                border.color: UniDeskGlobals.isLight ? "#e0e0e0" : "#2a2a2a"
                border.width: 1

                property int delegateIndex: index
                property bool editing: false

                RowLayout{
                    id: todoRow
                    x: 8
                    y: 6
                    width: parent.width - 16
                    spacing: 8

                    UniDeskCheckBox{
                        checked: model.completed !== undefined ? model.completed : false
                        onToggled: base.toggleTodo(delegateIndex)
                    }

                    Column{
                        Layout.fillWidth: true
                        spacing: 2

                        UniDeskText{
                            visible: !todoDelegate.editing
                            text: model.text !== undefined ? model.text : ""
                            font.pixelSize: 13
                            font.strikeout: (model.completed !== undefined ? model.completed : false)
                            color: (model.completed !== undefined ? model.completed : false)
                                ? (UniDeskGlobals.isLight ? "#aaaaaa" : "#666666")
                                : (UniDeskGlobals.isLight ? "#333333" : "#dddddd")
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }

                        UniDeskTextField{
                            visible: todoDelegate.editing
                            text: model.text !== undefined ? model.text : ""
                            Layout.fillWidth: true
                            onAccepted: {
                                todoDelegate.editing = false;
                                base.editTodo(delegateIndex, text);
                            }
                            onEditingFinished: {
                                if (!activeFocus) {
                                    todoDelegate.editing = false;
                                }
                            }
                        }

                        UniDeskText{
                            text: formatDate(model.createdAt !== undefined ? model.createdAt : 0)
                            font.pixelSize: 9
                            color: UniDeskGlobals.isLight ? "#bbbbbb" : "#555555"
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout{
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        UniDeskButton{
                            display: Button.IconOnly
                            iconSource: "file:" + (base.pluginDir || "") + "/media/edit.svg"
                            iconColor: UniDeskGlobals.isLight ? "#666666" : "#aaaaaa"
                            iconSize: 14
                            bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.08) : Qt.rgba(1,1,1,0.08)
                            bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.15) : Qt.rgba(1,1,1,0.15)
                            radius: width / 2
                            contentText: qsTr("编辑")
                            onClicked: todoDelegate.editing = true
                        }

                        UniDeskButton{
                            display: Button.IconOnly
                            iconSource: "file:" + (base.pluginDir || "") + "/media/delete-bin.svg"
                            iconColor: UniDeskGlobals.isLight ? "#cc6666" : "#ee8888"
                            iconSize: 14
                            bgHoverColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.08) : Qt.rgba(1,1,1,0.08)
                            bgPressColor: UniDeskGlobals.isLight ? Qt.rgba(0,0,0,0.15) : Qt.rgba(1,1,1,0.15)
                            radius: width / 2
                            contentText: qsTr("删除")
                            onClicked: base.removeTodo(delegateIndex)
                        }
                    }
                }

                Component.onCompleted: {
                    editing = false;
                }
            }
        }

        RowLayout{
            width: parent.width
            spacing: 8
            visible: todosModel.count === 0
            Item{ Layout.fillWidth: true }
            UniDeskText{
                text: qsTr("暂无待办事项")
                font.pixelSize: 12
                color: UniDeskGlobals.isLight ? "#aaaaaa" : "#555555"
                Layout.alignment: Qt.AlignCenter
            }
            Item{ Layout.fillWidth: true }
        }
    }

    function formatDate(ts) {
        if (!ts) return "";
        var d = new Date(ts);
        return d.getFullYear() + "-" +
               String(d.getMonth() + 1).padStart(2, "0") + "-" +
               String(d.getDate()).padStart(2, "0") + " " +
               String(d.getHours()).padStart(2, "0") + ":" +
               String(d.getMinutes()).padStart(2, "0");
    }

    Component.onCompleted: {
        updateCompletedCount();
        rebuildFilter();
    }

    optionsWindow: TodoListOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }

    function propertyDataEx(){
        var data = [];
        for (var i = 0; i < todosModel.count; i++) {
            var item = todosModel.get(i);
            data.push({
                text: item.text,
                completed: item.completed,
                createdAt: item.createdAt
            });
        }
        return {
            "todos": data,
            "filterIndex": base.filterIndex
        };
    }

    function loadPropertyDataEx(data){
        if(data.filterIndex!==undefined){base.filterIndex=data.filterIndex;}
        if(data.todos!==undefined && data.todos.length){
            todosModel.clear();
            for(var i=0;i<data.todos.length;i++){
                var t = data.todos[i];
                todosModel.append({
                    "text": t.text || "",
                    "completed": t.completed || false,
                    "createdAt": t.createdAt || Date.now()
                });
            }
        }
        updateCompletedCount();
        rebuildFilter();
    }
}