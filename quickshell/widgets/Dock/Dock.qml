// ═══════════════════════════════════════════════════════════════════
//  Dock/Dock.qml — док закреплённых приложений
//
//  Клик по иконке: если приложение уже открыто — поднимаем его окно,
//  иначе запускаем.
//
//  Поднять окно в этом Hyprland можно только через Lua-API:
//  обычный `hyprctl dispatch` здесь работает как шорткат для Lua и
//  классический синтаксис не принимает. Проверено:
//      hl.get_window("address:0x...")  → окно
//      hl.dsp.focus({ window = w })    → правильная форма
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

Item {
    id: dock

    // ── Закреплённые приложения ─────────────────────────────────────
    // cls — имена классов окон, по которым узнаём «приложение открыто».
    // Хранится списком: у VS Code класс com.microsoft.VSCode, а иконка vscode.
    readonly property var apps: [
        {
            name: "Терминал",
            icon: "kitty",
            cmd:  ["kitty"],
            cls:  ["kitty"]
        },
        {
            name: "Chromium",
            icon: "chromium-browser",
            cmd:  ["chromium-browser"],
            cls:  ["chromium-browser", "chromium"]
        },
        {
            name: "VS Code",
            icon: "vscode",
            cmd:  ["code"],
            cls:  ["code", "com.microsoft.VSCode", "vscode"]
        },
        {
            name: "Happ",
            icon: "happ",
            cmd:  ["happ"],
            cls:  ["happ"]
        },
        {
            name: "Wireshark",
            icon: "org.wireshark.Wireshark",
            cmd:  ["wireshark"],
            cls:  ["wireshark", "org.wireshark.Wireshark"]
        }
    ]

    // ── Поиск открытого окна приложения ─────────────────────────────
    function toplevelFor(app) {
        const list = Hyprland.toplevels.values

        for (let i = 0; i < list.length; i++) {
            const top = list[i]
            if (!top || !top.lastIpcObject) continue

            const cls = (top.lastIpcObject.class || "").toLowerCase()
            if (cls === "") continue

            for (let j = 0; j < app.cls.length; j++) {
                if (app.cls[j].toLowerCase() === cls) return top
            }
        }
        return null
    }

    // ── Клик: поднять или запустить ─────────────────────────────────
    function activate(app) {
        const top = toplevelFor(app)

        if (top && top.address) {
            const lua = 'local w = hl.get_window("address:' + top.address
                + '"); if w then hl.dispatch(hl.dsp.focus({ window = w })) end'
            focuser.command = ["hyprctl", "eval", lua]
            focuser.running = true
            return
        }

        launcher.command = app.cmd
        launcher.running = true
    }

    Process {
        id: launcher
        command: []
    }

    Process {
        id: focuser
        command: []
    }

    // ── Внешний вид ─────────────────────────────────────────────────
    implicitWidth:  row.width + Theme.dockPad * 2
    implicitHeight: row.height + Theme.dockPad * 2

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.glass
        border.width: 1
        border.color: Theme.glassEdge
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: dock.apps

            delegate: DockItem {
                required property var modelData

                app: modelData
                running: dock.toplevelFor(modelData) !== null
                onActivated: dock.activate(modelData)
            }
        }
    }
}
