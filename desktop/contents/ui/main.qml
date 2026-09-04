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

    // settings -> controller
    readonly property var customNames: {
        try {
            return JSON.parse(Plasmoid.configuration.outputNames || "{}");
        } catch (e) {
            return ({});
        }
    }

    DisplayController {
        id: ctl

        themeName: Plasmoid.configuration.theme
        customNames: root.customNames

        // hand the settings page the list of connectors it can rename
        onOutputsJsonChanged: {
            if (Plasmoid.configuration.knownOutputs !== outputsJson) {
                Plasmoid.configuration.knownOutputs = outputsJson;
            }
        }
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
