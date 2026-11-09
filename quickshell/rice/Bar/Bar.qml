// ═══════════════════════════════════════════════════════════════════
//  Bar.qml — верхний бар (PanelWindow, namespace "qs-bar")
//
//  Все визуальные значения — из синглтона Theme (корень конфига).
//  Фон рисует внутренний Rectangle: окно прозрачное, чтобы работал
//  радиус; blur для qs-bar в Hyprland выключен (см. hyprland.lua).
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight

    margins {
        top: Theme.barMarginTop
        left: Theme.barMarginSide
        right: Theme.barMarginSide
    }

    color: "transparent"

    // Верхняя полоса экрана резервируется, чтобы окна не заезжали под бар.
    exclusiveZone: Theme.barHeight + Theme.barMarginTop

    WlrLayershell.namespace: Theme.nsBar
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        radius: Theme.barRadius
    }
}
