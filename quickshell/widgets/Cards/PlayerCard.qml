// ═══════════════════════════════════════════════════════════════════
//  Cards/PlayerCard.qml — карточка плеера
//
//  Обложка, название, исполнитель, полоса прогресса и три кнопки.
//  Данные — из MPRIS через Quickshell.Services.Mpris.
//  Плеер может отсутствовать, поэтому КАЖДОЕ обращение к нему
//  защищено проверкой hasPlayer.
// ═══════════════════════════════════════════════════════════════════
import QtQuick
import Quickshell.Services.Mpris
import ".."

Item {
    id: card

    property MprisPlayer player: null
    readonly property bool hasPlayer: player !== null

    readonly property bool playing: hasPlayer && player.playbackState === MprisPlaybackState.Playing

    // Полоса прогресса: 0..1
    readonly property real progress: (hasPlayer && player.positionSupported && player.length > 0)
        ? Math.max(0, Math.min(1, player.position / player.length))
        : 0

    // Некоторые плееры (например VLC) отдают буквальное «<unknown>»
    // вместо пустой строки — показываем прочерк.
    readonly property string artistText: {
        const a = (hasPlayer && player.trackArtist) ? player.trackArtist : "";
        if (a === "" || a === "<unknown>" || a.toLowerCase() === "unknown") return "—";
        return a;
    }

    // Название трека; если плеер играет, но тегов в файле нет —
    // честно пишем, что названия нет, а не прячем карточку.
    readonly property string titleText: {
        const t = (hasPlayer && player.trackTitle) ? player.trackTitle : "";
        if (t !== "") return t;
        return playing ? "Без названия" : "—";
    }

    implicitWidth:  360
    implicitHeight: 96

    // Позицию трека обновляет корневой shell.qml: в MPRIS она не
    // приходит сама, а полосе прогресса нужно свежее значение.

    // ── Стеклянный фон ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.glass
        border.width: 1
        border.color: Theme.glassEdge
    }

    // ── Обложка трека ───────────────────────────────────────────────
    Rectangle {
        id: art
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 72
        height: 72
        radius: 10
        color: Theme.surface0
        clip: true

        Image {
            id: artImage
            anchors.fill: parent
            source: (card.hasPlayer && card.player.trackArtUrl) ? card.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        // Заглушка, пока обложки нет
        Text {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready
            text: "\uf001"
            color: Theme.overlay
            font.family: Theme.font
            font.pixelSize: 26
        }
    }

    // ── Тексты, прогресс, кнопки ────────────────────────────────────
    Column {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            width: parent.width
            text: card.titleText
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontNormal
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            width: parent.width
            text: card.artistText
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Полоса прогресса
        Rectangle {
            width: parent.width
            height: 3
            radius: 1.5
            color: Theme.surface0

            Rectangle {
                width: parent.width * card.progress
                height: parent.height
                radius: parent.radius
                color: Theme.mauve

                Behavior on width {
                    NumberAnimation { duration: 900; easing.type: Easing.Linear }
                }
            }
        }

        // Кнопки управления
        Row {
            spacing: 16

            Text {
                text: "\uf048"   // шаг назад
                color: (card.hasPlayer && card.player.canGoPrevious) ? Theme.subtext : Theme.overlay
                font.family: Theme.font
                font.pixelSize: Theme.fontLarge

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    enabled: card.hasPlayer && card.player.canGoPrevious
                    onClicked: card.player.previous()
                }
            }

            Text {
                text: card.playing ? "\uf04c" : "\uf04b"   // пауза / играть
                color: (card.hasPlayer && card.player.canTogglePlaying) ? Theme.mauve : Theme.overlay
                font.family: Theme.font
                font.pixelSize: Theme.fontLarge

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    enabled: card.hasPlayer && card.player.canTogglePlaying
                    onClicked: card.player.togglePlaying()
                }
            }

            Text {
                text: "\uf051"   // шаг вперёд
                color: (card.hasPlayer && card.player.canGoNext) ? Theme.subtext : Theme.overlay
                font.family: Theme.font
                font.pixelSize: Theme.fontLarge

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    enabled: card.hasPlayer && card.player.canGoNext
                    onClicked: card.player.next()
                }
            }
        }
    }
}
