// ═══════════════════════════════════════════════════════════════════
//  Dock/DockItem.qml — одна иконка в доке
//
//  Клик: если приложение уже открыто — поднимаем его окно,
//  иначе запускаем. Точка под иконкой означает «запущено».
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell
import ".."

Item {
    id: item

    // { name, icon, cmd, cls } — приходит из Dock.qml
    required property var app
    property bool running: false

    implicitWidth:  Theme.dockIcon + 12
    implicitHeight: Theme.dockIcon + 12

    // ── Наведение ───────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: mouse.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    Image {
        id: icon
        anchors.centerIn: parent
        width: Theme.dockIcon
        height: Theme.dockIcon
        source: Quickshell.iconPath(item.app.icon)
        sourceSize.width: Theme.dockIcon * 2
        sourceSize.height: Theme.dockIcon * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // ── Точка «запущено» ────────────────────────────────────────────
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: 5
        height: 2
        radius: 1
        color: Theme.mauve
        visible: item.running
        opacity: item.running ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.activated()
    }

    // Реализация клика — задаётся в Dock.qml
    signal activated()
}
