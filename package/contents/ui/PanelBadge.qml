// One compact badge: a status dot and the on/total count. Clicking opens the
// full card as a popup. Used when there are more displays than fit inline.
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: badge

    property DisplayController controller: null
    signal clicked()

    readonly property Theme theme: controller ? controller.theme : null

    // drawn straight onto the panel: text follows the panel's palette, unless
    // the user picked a text colour (see PanelStrip)
    readonly property color labelColor: theme && theme.textIsCustom
                                        ? theme.onSurface : Kirigami.Theme.textColor

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
            dotColor: badge.theme ? badge.theme.accent : "#ff4444"
        }

        Text {
            text: badge.controller
                  ? badge.controller.enabledCount + "/" + badge.controller.outputs.count
                  : "…"
            color: badge.labelColor
            opacity: 0.85
            // a vertical panel is only as wide as it is thick: shrink "10/12"
            // rather than paint over the neighbours
            width: badge.vertical ? badge.thickness - 2 * badge.gap : implicitWidth
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: badge.vertical ? Text.HorizontalFit : Text.FixedSize
            minimumPixelSize: 6
            font.pixelSize: badge.textPx
            font.letterSpacing: badge.theme ? badge.theme.labelSpacing : 1
            font.family: badge.theme ? badge.theme.fontFamily : "monospace"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: badge.clicked()
    }
}
