// ═══════════════════════════════════════════════════════════════════
//  Theme.qml — единственный источник визуальных значений (синглтон)
//
//  Правило проекта: цвета, отступы, радиусы и шрифты берутся ТОЛЬКО
//  отсюда. Литеральных значений в компонентах быть не должно.
//  Палитра — Catppuccin Mocha, та же, что в баре Wayle.
// ═══════════════════════════════════════════════════════════════════
pragma Singleton

import QtQuick

QtObject {
    // ── Палитра ─────────────────────────────────────────────────────
    readonly property color base:     "#1e1e2e"
    readonly property color mantle:   "#181825"
    readonly property color crust:    "#11111b"
    readonly property color text:     "#cdd6f4"
    readonly property color subtext:  "#a6adc8"
    readonly property color overlay:  "#6c7086"
    readonly property color mauve:    "#cba6f7"
    readonly property color blue:     "#89b4fa"
    readonly property color red:      "#f38ba8"
    readonly property color green:    "#a6e3a1"
    readonly property color yellow:   "#f9e2af"
    readonly property color teal:     "#94e2d5"
    readonly property color peach:    "#fab387"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"

    // ── Стекло ──────────────────────────────────────────────────────
    // В QML цвет с прозрачностью записывается как "#AARRGGBB";
    // рядом в комментарии — та же величина в привычном виде.
    readonly property color glass:     "#a6181825" // rgba(24, 24, 37, 0.65)
    readonly property color glassEdge: "#2ecdd6f4" // rgba(205, 214, 244, 0.18)
    readonly property color hover:     "#3311111b" // rgba(17, 17, 27, 0.20)
    readonly property color pressed:   "#55cba6f7" // rgba(203, 166, 247, 0.33)

    // ── Геометрия ───────────────────────────────────────────────────
    readonly property int radius:      16
    readonly property int margin:      16   // отступ виджетов от краёв экрана
    readonly property int gap:         10   // зазор между элементами внутри виджета
    readonly property int dockIcon:    40   // размер иконки в доке
    readonly property int dockPad:     8    // внутренний отступ дока

    // ── Типографика ─────────────────────────────────────────────────
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontTiny:   10
    readonly property int fontSmall:  11
    readonly property int fontNormal: 13
    readonly property int fontLarge:  15

    // ── Слой Hyprland ───────────────────────────────────────────────
    // По этому namespace в hyprland.lua включено размытие.
    readonly property string ns: "qs-widgets"
}
