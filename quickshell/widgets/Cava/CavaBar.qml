// ═══════════════════════════════════════════════════════════════════
//  Cava/CavaBar.qml — эквалайзер на звук
//
//  Сам cava ничего не рисует: он отдаёт значения полосок текстом
//  (см. cava-raw.conf), а полоски рисует QML. Высота полосок плавно
//  перетекает, поэтому спектр выглядит живым, а не дёрганым.
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell.Io
import ".."

Item {
    id: root

    // Текущие значения полосок, 0..1
    property var values: []

    readonly property int barCount:  24   // столько же, сколько bars в cava-raw.conf
    readonly property int barWidth:  4
    readonly property int barGap:    3
    readonly property int barHeight: 40   // максимальная высота полоски
    readonly property int innerPad:  12

    implicitWidth:  barCount * barWidth + (barCount - 1) * barGap + innerPad * 2
    implicitHeight: barHeight + innerPad * 2

    // ── Стеклянный фон ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.glass
        border.width: 1
        border.color: Theme.glassEdge
    }

    // ── Полоски ─────────────────────────────────────────────────────
    Row {
        anchors.centerIn: parent
        spacing: root.barGap

        Repeater {
            model: root.barCount

            delegate: Item {
                required property int index

                width:  root.barWidth
                height: root.barHeight

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width

                    // Даже в тишине у полоски есть минимальная высота,
                    // иначе виджет выглядит сломанным.
                    height: {
                        const v = root.values[index]
                        const level = (typeof v === "number" && isFinite(v)) ? v : 0
                        return Math.max(3, Math.round(level * root.barHeight))
                    }

                    radius: width / 2

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.mauve }
                        GradientStop { position: 1.0; color: Theme.blue }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }

    // ── Источник данных ─────────────────────────────────────────────
    Process {
        id: cava

        running: true
        command: ["cava", "-p", "/home/kudensik/rice/quickshell/widgets/cava-raw.conf"]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";")
                const next = []

                for (let i = 0; i < parts.length; i++) {
                    const v = parseInt(parts[i], 10)
                    if (!isNaN(v)) next.push(v / 100)
                }

                if (next.length > 0) root.values = next
            }
        }

        // Если cava упал — поднимаем снова, виджет не должен умирать.
        onExited: running = true
    }
}
