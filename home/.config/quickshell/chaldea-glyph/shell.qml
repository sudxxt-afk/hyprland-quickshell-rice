import QtQuick
import Quickshell
import Quickshell.Wayland

// Отдельный инстанс: глиф-арт Chaldea (Tsugumori) на столе, слева сверху, под окнами.
ShellRoot {
    PanelWindow {
        visible: true
        anchors { top: true; left: true }
        margins { top: 78; left: 24 }
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "chaldea-glyph"
        color: "transparent"

        implicitWidth: 252
        implicitHeight: 252
        Widget { anchors.fill: parent }
    }
}
