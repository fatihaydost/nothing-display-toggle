// The full card: one row per connected output. On the desktop it is the
// widget itself; on a panel it is the popup behind the badge.
import QtQuick

Item {
    id: card

    property DisplayController controller: null
    // the desktop widget floats the card with a margin; the popup fills instead
    property int margin: 10
    // 0..1, only the card's fill: switches and text stay solid over the wallpaper
    property real backgroundOpacity: 1.0

    readonly property Theme theme: controller ? controller.theme : null
    readonly property int rowCount: Math.max(1, controller ? controller.outputs.count : 0)
    readonly property color fill: theme ? theme.background : "#1a1a1a"

    implicitWidth: 220
    implicitHeight: 57 * rowCount + 35 + 2 * margin

    Rectangle {
        anchors.fill: parent
        anchors.margins: card.margin
        color: Qt.rgba(card.fill.r, card.fill.g, card.fill.b, card.backgroundOpacity)
        radius: 22
        clip: true

        Column {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 8

            // ── header ───────────────────────────────────────────────
            Item {
                width: parent.width
                height: 12

                Text {
                    text: i18n("DISPLAYS")
                    color: card.theme ? card.theme.onSurface : "#ffffff"
                    opacity: 0.5
                    font.pixelSize: 11
                    font.letterSpacing: card.theme ? card.theme.headerSpacing : 3
                    font.family: card.theme ? card.theme.fontFamily : "monospace"
                    font.weight: card.theme ? card.theme.titleWeight : Font.Medium
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                StatusDot {
                    size: 7
                    live: card.controller && card.controller.enabledCount > 0
                    dotColor: card.theme ? card.theme.accent : "#ff4444"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: hdrRight.left
                    anchors.rightMargin: 7
                }

                Text {
                    id: hdrRight
                    text: card.controller
                          ? card.controller.enabledCount + "/" + card.controller.outputs.count
                          : ""
                    color: card.theme ? card.theme.onSurface : "#ffffff"
                    opacity: 0.5
                    font.pixelSize: 11
                    font.letterSpacing: card.theme ? card.theme.labelSpacing : 1
                    font.family: card.theme ? card.theme.fontFamily : "monospace"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                }
            }

            // ── one row per output ────────────────────────────────────
            Repeater {
                model: card.controller ? card.controller.outputs : null

                delegate: Column {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: card.theme ? card.theme.divider : "#2e2e2e"
                        visible: index > 0
                    }

                    ToggleRow {
                        width: parent.width
                        theme: card.theme
                        title: model.label
                        connector: model.conn
                        on: model.enabled
                        busy: card.controller.pendingConn === model.conn
                        blocked: card.controller.busy && !busy
                        locked: card.controller.isLocked(model.enabled)
                        failed: card.controller.failedConn === model.conn
                        onToggled: card.controller.toggle(model.conn, model.enabled)
                    }
                }
            }

            // shown when kscreen-doctor is missing or reports no outputs
            Text {
                visible: card.controller && card.controller.queried
                         && card.controller.outputs.count === 0
                width: parent.width
                text: i18n("NO OUTPUT FOUND\nIS KSCREEN-DOCTOR INSTALLED?")
                color: card.theme ? card.theme.danger : "#ff4444"
                opacity: 0.9
                font.pixelSize: 10
                font.letterSpacing: card.theme ? card.theme.labelSpacing : 1.5
                font.family: card.theme ? card.theme.fontFamily : "monospace"
                wrapMode: Text.WordWrap
            }
        }
    }
}
