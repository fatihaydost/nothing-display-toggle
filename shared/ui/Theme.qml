// Colour and type tokens for the four looks. Only colours and typefaces change
// between them — sizes, spacing, radii and motion are the same everywhere, so
// the widget stays one design rather than four.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: t

    // No visual content and no size, but NOT visible:false — Kirigami.Theme
    // resolves its colours to black on an invisible item.
    implicitWidth: 0
    implicitHeight: 0

    // "nothing" | "kde" | "minimal" | "neon"
    property string name: "nothing"
    // the bundled dot-matrix family, resolved by DisplayController
    property string dotFamily: "monospace"
    // empty means "use the accent this look ships with"
    property string accentOverride: ""

    readonly property bool isKde: name === "kde"
    readonly property bool isMinimal: name === "minimal"
    readonly property bool isNeon: name === "neon"

    // follow the desktop palette rather than whatever is behind the widget
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    readonly property var palette: {
        if (isKde) return {
            background: Kirigami.Theme.backgroundColor,
            accent:     Kirigami.Theme.highlightColor,
            onSurface:  Kirigami.Theme.textColor,
            knob:       Kirigami.Theme.backgroundColor,
            divider:    Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                Kirigami.Theme.textColor.b, 0.16),
            trackOff:   Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                Kirigami.Theme.textColor.b, 0.22),
            danger:     Kirigami.Theme.negativeTextColor
        }
        // no colour at all: the "on" state is simply brighter than the "off" one.
        // Kept dark like the others because the panel forms draw straight onto the
        // panel, where a light palette would vanish.
        if (isMinimal) return {
            background: "#141414",
            accent:     "#e8e8e6",
            onSurface:  "#f2f2f0",
            knob:       "#141414",
            divider:    "#272727",
            trackOff:   "#2c2c2c",
            danger:     "#9a9a96"
        }
        if (isNeon) return {
            background: "#05060f",
            accent:     "#00f5d4",
            onSurface:  "#d7fff7",
            knob:       "#05060f",
            divider:    "#14243d",
            trackOff:   "#14243d",
            danger:     "#ff3ea5"
        }
        return {
            background: "#1a1a1a",
            accent:     "#ff4444",
            onSurface:  "#ffffff",
            knob:       "#ffffff",
            divider:    "#2e2e2e",
            trackOff:   "#333333",
            danger:     "#ff4444"
        }
    }

    readonly property color background: palette.background
    readonly property color themeAccent: palette.accent
    readonly property color accent: accentOverride.length > 0 ? accentOverride : themeAccent
    readonly property color onSurface: palette.onSurface
    readonly property color knob: palette.knob
    readonly property color divider: palette.divider
    readonly property color trackOff: palette.trackOff
    readonly property color danger: palette.danger

    readonly property string fontFamily: isKde || isMinimal
                                         ? Kirigami.Theme.defaultFont.family
                                         : isNeon ? "monospace" : dotFamily

    // the dot-matrix and monospace faces want air; a UI face does not
    readonly property real headerSpacing: isKde ? 1.0 : isMinimal ? 1.6 : 3.0
    readonly property real labelSpacing: isKde ? 0.4 : isMinimal ? 0.8 : 1.5
    readonly property int titleWeight: isKde ? Font.DemiBold
                                     : isMinimal ? Font.Normal
                                     : isNeon ? Font.Bold : Font.Medium
}
