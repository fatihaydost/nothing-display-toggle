// The full card: one row per connected output. The desktop package shows it
// directly; the panel package shows it as the popup.
import QtQuick

Item {
    id: card

    property DisplayController controller: null
    // the desktop widget floats the card with a margin; the popup fills instead
    property int margin: 10

    readonly property Theme theme: controller ? controller.theme : null
    readonly property int rowCount: Math.max(1, controller ? controller.outputs.count : 0)

    implicitWidth: 220
    implicitHeight: 57 * rowCount + 49 + 2 * margin

    Rectangle {
        anchors.fill: parent
        anchors.margins: card.margin
        color: card.theme ? card.theme.background : "#1a1a1a"
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
                    text: "DISPLAYS"
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
                        busy: card.controller.busy
                        locked: card.controller.isLocked(model.enabled)
                        onToggled: card.controller.toggle(model.conn, model.enabled)
                    }
                }
            }

            // shown when kscreen-doctor is missing or reports no outputs
            Text {
                visible: card.controller && card.controller.queried
                         && card.controller.outputs.count === 0
                width: parent.width
                text: "NO OUTPUT FOUND\nIS KSCREEN-DOCTOR INSTALLED?"
                color: card.theme ? card.theme.danger : "#ff4444"
                opacity: 0.9
                font.pixelSize: 10
                font.letterSpacing: card.theme ? card.theme.labelSpacing : 1.5
                font.family: card.theme ? card.theme.fontFamily : "monospace"
                wrapMode: Text.WordWrap
            }

            // ── dot-matrix strip ──────────────────────────────────────
            Row {
                width: parent.width
                height: 6
                spacing: Math.max(0, (parent.width - (12 * 6)) / 11)

                Repeater {
                    model: 12

                    delegate: Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        // lit fraction of the strip = fraction of outputs that are on
                        color: card.controller && card.controller.outputs.count > 0
                               && index < Math.round(12 * card.controller.enabledCount
                                                     / card.controller.outputs.count)
                               ? (card.theme ? card.theme.accent : "#ff4444")
                               : (card.theme ? card.theme.dotOff : "#333333")
                        opacity: 0.9
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
