import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// One widget for both places. Plasma tells us where it was dropped through
// formFactor: on the desktop the card is shown directly, on a panel the
// compact form (switches or badge) sits on the panel and the card is the popup.
PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property bool onPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                 || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    toolTipMainText: i18n("Displays")
    toolTipSubText: ctl.failedConn !== "" ? i18n("Could not switch %1: %2", ctl.failedConn, ctl.failedReason)
                  : !ctl.queried ? i18n("Reading displays…")
                  : ctl.outputs.count === 0 ? i18n("No display found")
                  : i18n("%1 of %2 switched on", ctl.enabledCount, ctl.outputs.count)

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
        backgroundOverride: Plasmoid.configuration.backgroundColor
        textOverride: Plasmoid.configuration.textColor
        customNames: root.customNames

        // hand the settings page the list of connectors it can rename
        onOutputsJsonChanged: {
            if (Plasmoid.configuration.knownOutputs !== outputsJson) {
                Plasmoid.configuration.knownOutputs = outputsJson;
            }
        }
    }

    // Panel only. "auto" keeps a switch per display on the panel while they
    // still fit, and falls back to a badge once there are more displays than
    // a panel can hold.
    readonly property string mode: {
        var m = Plasmoid.configuration.panelMode;
        if (m === "inline" || m === "popup") return m;
        return ctl.outputs.count <= Plasmoid.configuration.inlineThreshold
               ? "inline" : "popup";
    }

    // the strip acts on click, so there is nothing left expanded behind it
    onModeChanged: if (mode === "inline") root.expanded = false

    preferredRepresentation: onPanel ? compactRepresentation : fullRepresentation

    compactRepresentation: PanelCompact {
        controller: ctl
        mode: root.mode
        onBadgeClicked: root.expanded = !root.expanded
    }

    fullRepresentation: DisplayCard {
        controller: ctl
        // the desktop widget floats the card with a margin; the popup fills instead
        margin: root.onPanel ? 0 : 10
        // the popup sits on Plasma's own dialog background, so it stays solid
        backgroundOpacity: root.onPanel ? 1.0 : Plasmoid.configuration.backgroundOpacity / 100

        Layout.preferredWidth: 220
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: 195
        // the rows do not stretch, so a taller box would only add empty space
        // under the last one; the card grows and shrinks with its row count
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
    }
}
