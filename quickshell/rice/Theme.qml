// ═══════════════════════════════════════════════════════════════════
//  Theme.qml — единственный источник визуальных значений (синглтон)
//
//  Правило проекта: цвета, отступы, радиусы и шрифты берутся ТОЛЬКО
//  отсюда. Литеральных значений в компонентах быть не должно.
//  Палитра — Catppuccin Mocha.
// ═══════════════════════════════════════════════════════════════════
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // ── Палитра ─────────────────────────────────────────────────────
    property color base:     "#1e1e2e"
    property color mantle:   "#181825"
    property color crust:    "#11111b"
    property color text:     "#cdd6f4"
    property color subtext:  "#a6adc8"
    property color overlay:  "#6c7086"
    property color mauve:    "#cba6f7"
    property color blue:     "#89b4fa"
    property color red:      "#f38ba8"
    property color green:    "#a6e3a1"
    property color yellow:   "#f9e2af"
    property color teal:     "#94e2d5"
    property color peach:    "#fab387"
    property color sky:      "#89dceb"
    property color lavender: "#b4befe"
    property color surface0: "#313244"
    property color surface1: "#45475a"

    // ── Поверхности ─────────────────────────────────────────────────
    // В QML цветовой литерал записывается как "#AARRGGBB": CSS-форма
    // rgba(r,g,b,a) в QML не поддерживается, поэтому в комментарии
    // рядом сохранена исходная запись из спеки.
    property color barBg:   "#9e181825" // rgba(24, 24, 37, 0.62)
    property color cardBg:  "#9e181825" // rgba(24, 24, 37, 0.62)
    property color dockBg:  "#9e181825" // rgba(24, 24, 37, 0.62)
    property color panelBg: "#eb11111b" // rgba(17, 17, 27, 0.92)

    // ── Геометрия ───────────────────────────────────────────────────
    property int barHeight:     36
    property int barMarginTop:  8
    property int barMarginSide: 12
    property int barRadius:     14
    property int cardMargin:    16
    property int cardRadius:    16
    property int panelRadius:   16
    property int panelWidth:    360
    property int panelGap:      8
    property int dockHeight:    56
    property int dockRadius:    28
    property int itemRadius:    9

    // ── Типографика ─────────────────────────────────────────────────
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize:  13
    property int clockSize: 34

    // ── Namespace'ы слоёв (для правил слоёв Hyprland) ───────────────
    property string nsBar:   "qs-bar"
    property string nsCard:  "qs-card"
    property string nsDock:  "qs-dock"
    property string nsPopup: "qs-popup"
}
