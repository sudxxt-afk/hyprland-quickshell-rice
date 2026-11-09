// ═══════════════════════════════════════════════════════════════════
//  shell.qml — корень конфига виджетов рабочего стола
//
//  Запуск:  quickshell --path ~/rice/quickshell/widgets
//           (в обычной жизни это делает служба quickshell-widgets)
//  Слой:    нижний (WlrLayer.Bottom) — виджеты лежат на рабочем столе
//           и всегда уходят под окна.
//  Стекло:  размытие включается правилом слоя в ~/.config/hypr/hyprland.lua
//           по namespace "qs-widgets" (см. Theme.ns).
//
//  Состав: карточка плеера (слева), док (по центру), эквалайзер (справа).
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

import "Cards"
import "Dock"
import "Cava"

ShellRoot {
    id: root

    // ── Обновление позиций и выбор плеера ────────────────────────────
    // Позиция трека в MPRIS не обновляется сама: её надо переспрашивать.
    // Раз в секунду дёргаем positionChanged() у играющих плееров — от
    // этого едет полоса прогресса — и пересчитываем, чей трек показывать
    // (tick ниже заставляет выбор перечитаться).
    property int tick: 0

    // Приложения, которые прямо сейчас издают звук (имена из PulseAudio),
    // и признак, что мы вообще смогли это выяснить.
    property var soundingApps: []
    property bool probeOk: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const list = Mpris.players.values
            for (let i = 0; i < list.length; i++) {
                if (list[i].playbackState === MprisPlaybackState.Playing)
                    list[i].positionChanged()
            }
            root.tick++
        }
    }

    Process {
        id: audioProbe
        command: ["pactl", "-f", "json", "list", "sink-inputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                let names = []
                try {
                    const items = JSON.parse(text)
                    for (let i = 0; i < items.length; i++) {
                        const props = items[i].properties || {}
                        // В PipeWire поле application.name часто пустое,
                        // зато node.name содержит узнаваемое имя приложения
                        // («VLC media player (LibVLC 3.0.24)»).
                        const name = props["application.name"] || props["node.name"] || ""
                        if (name !== "") names.push(String(name).toLowerCase())
                    }
                    root.soundingApps = names
                    root.probeOk = true
                } catch (e) {
                    root.soundingApps = []
                    root.probeOk = false
                }
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: audioProbe.running = true
    }

    // Какой плеер показывать.
    //
    // Тонкости, проверенные на живой системе:
    //  * playerctld — агрегатор: повторяет чужой трек и переживает
    //    закрытие настоящего плеера. Пропускаем.
    //  * Telegram умеет «залипнуть»: сообщает «играю», уже ничего не
    //    воспроизводя, причём навсегда, пока его не перезапустят.
    //    Ни позиция, ни длительность это не выдают (у VLC позиция
    //    тоже нулевая). Зато настоящий плеер всегда создаёт поток
    //    звука — на это и опираемся.
    function pickPlayer() {
        root.tick   // зависимость: пересчитывать выбор каждый тик

        const list = Mpris.players.values
        const known = root.probeOk          // знаем ли, кто сейчас звучит

        let playingAndSounding = null       // играет и правда звучит
        let pausedWithTrack = null          // на паузе, но трек есть
        let playing = null                  // числится играющим
        let anyPlayer = null

        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            if ((p.dbusName || "").indexOf("playerctld") >= 0) continue

            if (anyPlayer === null) anyPlayer = p

            const sounds = root.isSounding(p)
            const hasTrack = (p.trackTitle || "") !== ""

            if (p.playbackState === MprisPlaybackState.Playing) {
                if (playing === null) playing = p
                if (sounds && playingAndSounding === null) playingAndSounding = p
            } else if (pausedWithTrack === null && (hasTrack || sounds)) {
                pausedWithTrack = p
            }
        }

        // Если про звук мы знаем, то играющий плеер без потока звука —
        // это залипший MPRIS-клиент, и показывать его не надо.
        //
        // Настоящие плееры узнаются по имени приложения в потоке звука
        // (см. isSounding): так карточка и отличается от залипшей записи.
        if (known) return playingAndSounding || pausedWithTrack || null

        // Данных о звуке нет (например, нет pactl) — работаем по MPRIS.
        return playing || anyPlayer
    }

    // Издаёт ли приложение этого плеера звук прямо сейчас.
    function isSounding(p) {
        const apps = root.soundingApps || []
        if (apps.length === 0) return false    // данных нет — не угадываем

        const keys = ((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase()
        // Слишком общие слова не годятся как признак приложения.
        const stop = ["media", "player", "audio", "stream", "output", "input",
                      "desktop", "pipewire", "pulse", "playback", "consumer"]

        for (let i = 0; i < apps.length; i++) {
            const tokens = apps[i].split(/[^a-z0-9]+/)
            for (let j = 0; j < tokens.length; j++) {
                const t = tokens[j]
                if (t.length < 3 || stop.indexOf(t) >= 0) continue
                if (keys.indexOf(t) >= 0) return true
            }
        }
        return false
    }

    // ── Карточка плеера: левый нижний угол ──────────────────────────
    PanelWindow {
        id: playerWindow

        readonly property MprisPlayer currentPlayer: root.pickPlayer()

        // Карточка есть, если плееру есть что показать: либо он играет,
        // либо у трека есть название. Плеер без трека и на паузе не нужен.
        visible: currentPlayer !== null
                 && ((currentPlayer.trackTitle || "") !== ""
                     || currentPlayer.playbackState === MprisPlaybackState.Playing)

        anchors {
            bottom: true
            left: true
        }
        margins {
            bottom: Theme.margin
            left: Theme.margin
        }

        implicitWidth:  360
        implicitHeight: 96

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: Theme.ns
        WlrLayershell.layer: WlrLayer.Bottom

        PlayerCard {
            anchors.fill: parent
            player: playerWindow.currentPlayer
        }
    }

    // ── Док: снизу по центру ────────────────────────────────────────
    PanelWindow {
        id: dockWindow

        anchors {
            bottom: true
        }
        margins {
            bottom: Theme.margin
        }

        implicitWidth:  dockWidget.implicitWidth
        implicitHeight: dockWidget.implicitHeight

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: Theme.ns
        WlrLayershell.layer: WlrLayer.Bottom

        Dock {
            id: dockWidget
            anchors.fill: parent
        }
    }

    // ── Эквалайзер: правый нижний угол ──────────────────────────────
    PanelWindow {
        id: cavaWindow

        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: Theme.margin
            right: Theme.margin
        }

        implicitWidth:  cavaWidget.implicitWidth
        implicitHeight: cavaWidget.implicitHeight

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: Theme.ns
        WlrLayershell.layer: WlrLayer.Bottom

        CavaBar {
            id: cavaWidget
            anchors.fill: parent
        }
    }
}
