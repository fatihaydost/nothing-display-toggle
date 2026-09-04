// One switch per display, sitting directly on the panel. A click toggles that
// display; there is no popup to open. Every size derives from the panel
// thickness, so it fits a 24 px panel and a 64 px one alike.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: strip

    property DisplayController controller: null

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property real thickness: vertical ? strip.width : strip.height

    readonly property int pillH: Math.max(9, Math.min(20, Math.round(thickness * 0.42)))
    readonly property int pillW: Math.round(pillH * 1.95)
    readonly property int labelPx: Math.max(7, Math.round(pillH * 0.66))
    readonly property int gap: Math.max(3, Math.round(pillH * 0.4))
    // a vertical panel is too narrow for the name; the switch alone has to do
    readonly property bool showLabel: !vertical && thickness >= 22

    implicitWidth: vertical ? thickness : layout.implicitWidth + 2 * gap
    implicitHeight: vertical ? layout.implicitHeight + 2 * gap : thickness

    Grid {
        id: layout
        anchors.centerIn: parent
        columns: strip.vertical ? 1 : 1000
        spacing: strip.gap * 2

        // shown until kscreen-doctor answers, so the widget is never invisible
        Item {
            visible: !strip.controller || strip.controller.outputs.count === 0
            width: strip.pillW
            height: strip.pillH

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: strip.controller && strip.controller.queried ? "#4a2020" : "#333333"
                opacity: 0.7
            }

            Text {
                anchors.centerIn: parent
                text: strip.controller && strip.controller.queried ? "!" : "…"
                color: "#ffffff"
                opacity: 0.7
                font.pixelSize: strip.labelPx
                font.family: strip.controller ? strip.controller.uiFont : "monospace"
            }
        }

        Repeater {
            model: strip.controller ? strip.controller.outputs : null

            delegate: Item {
                id: chip

                readonly property bool locked: strip.controller.isLocked(model.enabled)

                width: strip.showLabel ? label.implicitWidth + strip.gap + strip.pillW
                                       : strip.pillW
                height: strip.pillH

                Text {
                    id: label
                    text: model.label
                    visible: strip.showLabel
                    color: "#ffffff"
                    opacity: model.enabled ? 0.95 : 0.4
                    font.pixelSize: strip.labelPx
                    font.letterSpacing: 0.5
                    font.family: strip.controller.uiFont
                    font.weight: Font.Medium
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Rectangle {
                    id: track
                    width: strip.pillW
                    height: strip.pillH
                    radius: height / 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: model.enabled ? "#ff4444" : "#333333"
                    opacity: strip.controller.busy ? 0.55 : (chip.locked ? 0.7 : 1.0)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        readonly property int inset: Math.max(2, Math.round(strip.pillH * 0.14))

                        width: parent.height - 2 * inset
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: model.enabled ? parent.width - width - inset : inset

                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: chip.locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                    onClicked: strip.controller.toggle(model.conn, model.enabled)
                }
            }
        }
    }
}
