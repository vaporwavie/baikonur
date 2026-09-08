import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import QtQuick.Window

PlasmoidItem {
    id: root

    property string endpoint: "http://127.0.0.1:47421"
    property var sectionIcons: ({})
    property bool hasResults: false
    property string pendingQuery: ""

    Plasmoid.icon: "search"
    preferredRepresentation: compactRepresentation
    activationTogglesExpanded: false

    function query(text) {
        pendingQuery = text;
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 40
        onTriggered: root.fetch(root.pendingQuery)
    }

    function fetch(text) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", endpoint + "/q?text=" + encodeURIComponent(text));
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) return;
            if (field.text.trim() !== text) return;
            rebuild(JSON.parse(xhr.responseText).sections);
        };
        xhr.send();
    }

    function rebuild(sections) {
        const next = [];
        const icons = {};
        for (const s of sections) {
            icons[s.title] = s.icon;
            for (const it of s.items) {
                next.push({ section: s.title, itemId: it.id, kind: it.kind, title: it.title, subtitle: it.subtitle, icon: it.icon });
            }
        }
        sectionIcons = icons;
        const common = Math.min(results.count, next.length);
        for (let i = 0; i < common; i++) results.set(i, next[i]);
        for (let i = common; i < next.length; i++) results.append(next[i]);
        if (results.count > next.length) results.remove(next.length, results.count - next.length);
        hasResults = next.length > 0;
        list.currentIndex = next.length > 0 ? 0 : -1;
    }

    function launch(index) {
        if (index < 0 || index >= results.count) return;
        const it = results.get(index);
        const xhr = new XMLHttpRequest();
        xhr.open("POST", endpoint + "/launch");
        xhr.setRequestHeader("content-type", "application/json");
        xhr.send(JSON.stringify({ kind: it.kind, id: it.itemId, query: field.text.trim() }));
        win.visible = false;
    }

    ListModel { id: results }

    Connections {
        target: Plasmoid
        function onActivated() { win.toggle(); }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Kirigami.Units.iconSizes.small
        onClicked: win.toggle()
        Kirigami.Icon { anchors.fill: parent; source: "search" }
    }

    readonly property int boxWidth: 800

    PlasmaCore.Dialog {
        id: win
        type: PlasmaCore.Dialog.PopupMenu
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        x: Math.round((Screen.width - width) / 2)
        y: Math.round(Screen.height * 0.28)

        function toggle() { visible = !visible; }

        onVisibleChanged: {
            field.text = "";
            if (visible) {
                root.fetch("");
                field.forceActiveFocus(Qt.OtherFocusReason);
            }
        }

        mainItem: Rectangle {
            width: root.boxWidth
            height: 58
            radius: 12
            color: "#151517"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                font.family: "Geist"
                font.pixelSize: 20
                color: "white"
                selectionColor: Qt.rgba(1, 1, 1, 0.25)
                clip: true
                onTextChanged: root.query(text.trim())
                Keys.onDownPressed: if (list.currentIndex < results.count - 1) list.currentIndex++
                Keys.onUpPressed: if (list.currentIndex > 0) list.currentIndex--
                Keys.onReturnPressed: root.launch(list.currentIndex)
                Keys.onEnterPressed: root.launch(list.currentIndex)
                Keys.onEscapePressed: {
                    if (field.text.length > 0) field.text = "";
                    else win.visible = false;
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text.length === 0
                    text: "Start typing…"
                    font: field.font
                    color: Qt.rgba(1, 1, 1, 0.38)
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: resultsWin
        type: PlasmaCore.Dialog.Notification
        location: PlasmaCore.Types.Floating
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
        visible: win.visible && root.hasResults
        x: win.x
        y: win.y + win.height + 8

        mainItem: Rectangle {
            width: root.boxWidth
            height: list.contentHeight + 20
            radius: 12
            color: "#151517"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 10
                model: results
                interactive: false
                highlightMoveDuration: 0
                highlight: Rectangle { radius: 8; color: Qt.rgba(1, 1, 1, 0.09) }
                section.property: "section"
                section.delegate: Item {
                            width: ListView.view.width
                            height: 30
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Kirigami.Icon {
                                    width: 12; height: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.sectionIcons[section] || "view-list-details"
                                    color: "white"
                                }
                                Text {
                                    text: section
                                    font.family: "Geist"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Qt.rgba(1, 1, 1, 0.85)
                                }
                            }
                        }
                        delegate: Item {
                            id: row
                            required property int index
                            required property string title
                            required property string subtitle
                            required property string icon
                            width: ListView.view.width
                            height: 54
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                spacing: 12
                                Kirigami.Icon {
                                    width: 34; height: 34
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: row.icon
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: row.title
                                        font.family: "Geist"
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                        color: "white"
                                    }
                                    Text {
                                        text: row.subtitle
                                        visible: row.subtitle.length > 0
                                        font.family: "Geist"
                                        font.pixelSize: 12
                                        color: Qt.rgba(1, 1, 1, 0.6)
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = row.index
                                onClicked: root.launch(row.index)
                            }
                }
            }
        }
    }
}
