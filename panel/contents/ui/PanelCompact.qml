// The panel representation. Plasma builds compactRepresentation once and keeps
// it, so swapping that property at runtime does nothing — both forms live here
// instead and only their visibility changes when the display count crosses the
// threshold.
import QtQuick

Item {
    id: compact

    property DisplayController controller: null
    property string mode: "inline"
    signal badgeClicked()

    readonly property bool inline: mode === "inline"

    implicitWidth: inline ? strip.implicitWidth : badge.implicitWidth
    implicitHeight: inline ? strip.implicitHeight : badge.implicitHeight

    PanelStrip {
        id: strip
        anchors.fill: parent
        visible: compact.inline
        controller: compact.controller
    }

    PanelBadge {
        id: badge
        anchors.fill: parent
        visible: !compact.inline
        controller: compact.controller
        onClicked: compact.badgeClicked()
    }
}
