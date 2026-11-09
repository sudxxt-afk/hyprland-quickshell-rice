import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Cava-визуализатор на рабочем столе: прозрачная дорожка эквалайзера
// по центру снизу, без подложки — только бары поверх обоев.
// Отдельный инстанс (`qs -c cava`), цвета — из палитры matugen (colors.json),
// поэтому перекрашивается вместе с обоями. Клики проходят насквозь.
ShellRoot {
    id: shellRoot

    PanelWindow {
        id: root

        visible: true
        anchors { bottom: true; left: true; right: true }
        margins { bottom: 56 }
        implicitHeight: 170
        exclusiveZone: -1
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:cava"
        mask: Region {}

        property var levels: []
        property var palette: ({})

        readonly property int barCount: 44
        readonly property int gap: 4
        readonly property int barWidth: 8
        readonly property real minBarHeight: 14
        readonly property int barsHeight: 110

        FileView {
            id: colorFile
            path: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/colors.json"
            watchChanges: true
            onLoadedChanged: {
                try {
                    root.palette = JSON.parse(colorFile.text())
                } catch (e) {
                    root.palette = ({})
                }
            }
            onFileChanged: colorFile.reload()
        }

        Process {
            id: cavaProc
            running: true
            command: [
                "cava", "-p",
                Quickshell.env("HOME") + "/.config/quickshell/cava/raw_output_config.txt"
            ]
            stdout: SplitParser {
                onRead: data => {
                    const values = data.split(";")
                        .map(part => parseFloat(part.trim()))
                        .filter(value => !isNaN(value))
                    if (values.length > 0)
                        root.levels = values
                }
            }
            onRunningChanged: {
                if (!running)
                    root.levels = []
            }
        }

        Row {
            id: barsRow
            anchors.centerIn: parent
            height: root.barsHeight
            spacing: root.gap

            Repeater {
                model: root.barCount

                Item {
                    id: barSlot
                    required property int index

                    width: root.barWidth
                    height: parent.height

                    readonly property real value: {
                        if (root.levels.length === 0)
                            return 0
                        const step = Math.max(1, Math.floor(root.levels.length / root.barCount))
                        const start = index * step
                        const end = Math.min(start + step, root.levels.length)
                        let sum = 0
                        let count = 0
                        for (let i = start; i < end; i++) {
                            sum += root.levels[i] || 0
                            count++
                        }
                        return count > 0 ? Math.min(1, (sum / count) / 1000) : 0
                    }

                    Rectangle {
                        width: parent.width
                        height: Math.max(root.minBarHeight, barSlot.value * parent.height)
                        anchors.bottom: parent.bottom
                        radius: width / 2
                        color: {
                            if (barSlot.value > 0.66)
                                return root.palette.tertiary || "#ffb4ab"
                            if (barSlot.value > 0.33)
                                return root.palette.primary || "#e9e1e0"
                            return root.palette.secondary || "#968f8f"
                        }
                        opacity: 0.8 + barSlot.value * 0.2
                    }
                }
            }
        }
    }
}
