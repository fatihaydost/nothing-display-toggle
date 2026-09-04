// One compact badge: a status dot and the on/total count. Clicking opens the
// full card as a popup. Used when there are more displays than fit inline.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: badge

    property DisplayController controller: null
    signal clicked()

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property real thickness: vertical ? badge.width : badge.height

    readonly property int textPx: Math.max(8, Math.min(14, Math.round(thickness * 0.34)))
    readonly property real dotSize: Math.max(5, Math.round(textPx * 0.6))
    readonly property int gap: Math.max(3, Math.round(textPx * 0.45))

    implicitWidth: vertical ? thickness : layout.implicitWidth + 2 * gap
    implicitHeight: vertical ? layout.implicitHeight + 2 * gap : thickness

    Grid {
        id: layout
        anchors.centerIn: parent
        columns: badge.vertical ? 1 : 2
        spacing: badge.gap
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        StatusDot {
            size: badge.dotSize
            live: badge.controller && badge.controller.enabledCount > 0
        }

        Text {
            text: badge.controller
                  ? badge.controller.enabledCount + "/" + badge.controller.outputs.count
                  : "…"
            color: "#ffffff"
            opacity: 0.85
            font.pixelSize: badge.textPx
            font.letterSpacing: 1
            font.family: badge.controller ? badge.controller.uiFont : "monospace"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: badge.clicked()
    }
}
