import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    toolTipMainText: "Displays"
    toolTipSubText: ctl.enabledCount + " of " + ctl.outputs.count + " switched on"

    DisplayController {
        id: ctl
    }

    fullRepresentation: DisplayCard {
        controller: ctl
        margin: 10

        Layout.preferredWidth: 220
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: 195
        Layout.minimumHeight: implicitHeight - 14
    }
}
