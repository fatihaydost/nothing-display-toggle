import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

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
        accentOverride: Plasmoid.configuration.accentColor
        customNames: root.customNames

        // hand the settings page the list of connectors it can rename
        onOutputsJsonChanged: {
            if (Plasmoid.configuration.knownOutputs !== outputsJson) {
                Plasmoid.configuration.knownOutputs = outputsJson;
            }
        }
    }

    // "auto" keeps a switch per display on the panel while they still fit, and
    // falls back to a badge once there are more displays than a panel can hold.
    readonly property string mode: {
        var m = Plasmoid.configuration.panelMode;
        if (m === "inline" || m === "popup") return m;
        return ctl.outputs.count <= Plasmoid.configuration.inlineThreshold
               ? "inline" : "popup";
    }

    // the strip acts on click, so there is nothing left expanded behind it
    onModeChanged: if (mode === "inline") root.expanded = false

    preferredRepresentation: compactRepresentation

    compactRepresentation: PanelCompact {
        controller: ctl
        mode: root.mode
        onBadgeClicked: root.expanded = !root.expanded
    }

    fullRepresentation: DisplayCard {
        controller: ctl
        margin: 0

        Layout.preferredWidth: 220
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: 195
        Layout.minimumHeight: implicitHeight
    }
}
