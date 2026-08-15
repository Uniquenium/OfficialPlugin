import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQml
import QtQuick.Templates as T
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import UniDesk.Controls
import UniDesk.Singletons
import UniDesk
import org.uniquenium.uniqueniumOfficialplugin 1.0

UniDeskComBase{
    id: base
    visible: true
    width: 400
    height: 500

    chosen: comManager.selectMode===UniDeskComponentSelectMode.NoSelect ? (optionsWindow.visible) : selected

    property string clusterUri: ""
    property string database: "test"
    property string collection: "comment"
    property string pageId: "/"
    property string blogUrl: ""

    property var _allComments: []

    ListModel{
        id: commentsModel
    }

    TwikooCommentsBackend{
        id: backend

        onCommentsUpdated: function(allComments) {
            console.log("TwikooComments: got", allComments ? allComments.length : 0, "total docs");
            base._allComments = allComments ? allComments.slice(0) : [];
            base.rebuildModel();
        }
        onFetchError: function(error) {
            console.log("TwikooComments: onFetchError:", error);
            errorArea.text = error;
            errorTimer.start();
        }
        onConnectionTested: function(success, message) {
            console.log("TwikooComments: onConnectionTested, success =", success, "message =", message);
            errorArea.text = message;
            errorTimer.start();
        }
    }

    onPageIdChanged: function() { base.rebuildModel(); }

    function rebuildModel() {
        commentsModel.clear();
        var all = base._allComments;
        if (!all || all.length === 0) return;

        var prefix = base.pageId;
        var filtered = [];
        for (var i = 0; i < all.length; i++) {
            var c = all[i];
            if (c.url && c.url.indexOf(prefix) === 0) {
                filtered.push(c);
            }
        }
        console.log("TwikooComments: filtered", filtered.length, "docs for prefix", prefix);

        var idMap = {};
        for (var i = 0; i < filtered.length; i++) {
            idMap[filtered[i].id] = filtered[i];
        }

        for (var i = 0; i < filtered.length; i++) {
            var item = filtered[i];
            var isReply = false;
            var parentName = "";
            var parentContent = "";
            var parentCreated = "";

            if (item.pid && item.pid !== "" && idMap[item.pid]) {
                var parent = idMap[item.pid];
                isReply = true;
                parentName = parent.name || "";
                parentContent = (parent.content || "").length > 80
                    ? (parent.content || "").slice(0, 80) + "..."
                    : (parent.content || "");
                parentCreated = parent.created || "";
            }

            commentsModel.append({
                "name": item.name || "",
                "created": item.created || "",
                "url": item.url || "",
                "content": item.content || "",
                "isReply": isReply,
                "parentName": parentName,
                "parentContent": parentContent,
                "parentCreated": parentCreated
            });
        }
        console.log("TwikooComments: model count =", commentsModel.count);
    }

    Timer{
        id: refreshTimer
        interval: 300
        repeat: false
        onTriggered: base.fetchComments()
    }

    onClusterUriChanged: function() { refreshTimer.restart(); }
    onDatabaseChanged: function() { refreshTimer.restart(); }
    onCollectionChanged: function() { refreshTimer.restart(); }

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout{
            width: parent.width
            spacing: 10
            UniDeskText{
                text: qsTr("Twikoo Comments")
                font.pixelSize: 16
                font.bold: true
            }
            Item{ Layout.fillWidth: true }
            Rectangle{
                width: 8
                height: 8
                radius: 4
                color: backend.connected ? "#4CAF50" : "#F44336"
            }
            UniDeskText{
                text: backend.connected ? qsTr("Connected") : qsTr("Disconnected")
                color: backend.connected ? "#4CAF50" : "#F44336"
                font.pixelSize: 12
            }
            MouseArea{
                width: 60
                height: 24
                onClicked: {
                    console.log("TwikooComments: Refresh clicked");
                    base.fetchComments();
                }
                enabled: !backend.loading
                Text{
                    text: backend.loading ? qsTr("Loading...") : qsTr("Refresh")
                    color: UniDeskSettings.primaryColor
                    font.pixelSize: 12
                    anchors.centerIn: parent
                }
            }
        }

        ListView{
            id: commentsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: commentsModel

            ScrollBar.vertical: ScrollBar{}

            delegate: Item{
                id: delegateItem
                width: commentsView.width
                height: commentColumn.height + 16

                Rectangle{
                    anchors.fill: parent
                    radius: 8
                    color: UniDeskGlobals.isLight ? Qt.rgba(0.95,0.95,0.95,0.9) : Qt.rgba(0.15,0.15,0.15,0.9)
                    border.color: UniDeskGlobals.isLight ? "#ddd" : "#333"
                    border.width: 1

                    MouseArea{
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            var urlStr = base.blogUrl + (model.url || base.pageId);
                            console.log("TwikooComments: opening URL:", urlStr);
                            Qt.openUrlExternally(urlStr);
                        }
                    }
                }

                Column{
                    id: commentColumn
                    x: 10
                    y: 8
                    width: parent.width - 20
                    spacing: 4

                    RowLayout{
                        width: parent.width
                        spacing: 8
                        UniDeskText{
                            text: model.name
                            font.pixelSize: 13
                            font.bold: true
                            color: UniDeskSettings.primaryColor
                        }
                        Item{ Layout.fillWidth: true }
                        UniDeskText{
                            text: model.created
                            font.pixelSize: 11
                            color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                        }
                    }

                    UniDeskText{
                        text: model.url
                        font.pixelSize: 10
                        color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }

                    UniDeskText{
                        text: model.content
                        font.pixelSize: 13
                        color: UniDeskGlobals.isLight ? "#333333" : "#dddddd"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Rectangle{
                        id: parentQuote
                        width: parent.width
                        height: parentQuoteColumn.height + 4
                        radius: 4
                        color: UniDeskGlobals.isLight ? Qt.rgba(1,1,1,0.6) : Qt.rgba(0,0,0,0.25)
                        border.color: UniDeskGlobals.isLight ? "#ddd" : "#333"
                        border.width: 1
                        visible: model.isReply

                        Column{
                            id: parentQuoteColumn
                            x: 6
                            y: 2
                            width: parent.width - 12
                            spacing: 1

                            RowLayout{
                                width: parent.width
                                spacing: 4
                                UniDeskText{
                                    text: qsTr("回复") + " @ " + model.parentName
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: UniDeskGlobals.isLight ? "#888888" : "#aaaaaa"
                                }
                                Item{ Layout.fillWidth: true }
                                UniDeskText{
                                    text: model.parentCreated
                                    font.pixelSize: 8
                                    color: UniDeskGlobals.isLight ? "#aaa" : "#666"
                                }
                            }

                            UniDeskText{
                                text: model.parentContent
                                font.pixelSize: 9
                                color: UniDeskGlobals.isLight ? "#777777" : "#888888"
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                console.log("TwikooComments: ListView completed, fetching comments...");
                base.fetchComments();
            }
        }

        UniDeskText{
            id: errorArea
            text: ""
            color: "#F44336"
            font.pixelSize: 11
            visible: text.length > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        Timer{
            id: errorTimer
            interval: 5000
            repeat: false
            onTriggered: errorArea.text = ""
        }
    }

    optionsWindow: TwikooCommentsOptions{
        id: options
        comManager: base.comManager
        editingComponent: base
    }

    function propertyDataEx(){
        return {
            "clusterUri": base.clusterUri,
            "database": base.database,
            "collection": base.collection,
            "pageId": base.pageId,
            "blogUrl": base.blogUrl
        }
    }

    function loadPropertyDataEx(data){
        if(data.clusterUri!==undefined){base.clusterUri=data.clusterUri;}
        if(data.database!==undefined){base.database=data.database;}
        if(data.collection!==undefined){base.collection=data.collection;}
        if(data.pageId!==undefined){base.pageId=data.pageId;}
        if(data.blogUrl!==undefined){base.blogUrl=data.blogUrl;}
    }

    function testConnection(){
        backend.testConnection(base.clusterUri);
    }

    function fetchComments(){
        backend.fetchComments(base.clusterUri, base.database, base.collection, base.pageId);
    }
}