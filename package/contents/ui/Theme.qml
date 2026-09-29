// Colour and type tokens for the four looks. Only colours and typefaces change
// between them — sizes, spacing, radii and motion are the same everywhere, so
// the widget stays one design rather than four.
//
// Three colours can be overridden from the settings: accent, background and
// text. Everything else is derived from them, so an override stays coherent
// instead of leaving hardcoded colours behind.
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

    // bundled families, resolved by DisplayController
    property string dotFamily: "monospace"
    property string elegantFamily: "monospace"

    // empty means "use what this look ships with"
    property string accentOverride: ""
    property string backgroundOverride: ""
    property string textOverride: ""

    readonly property bool isKde: name === "kde"
    readonly property bool isMinimal: name === "minimal"
    readonly property bool isNeon: name === "neon"

    // follow the desktop palette rather than whatever is behind the widget
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    // named `look`, not `palette`: Item already has a palette property in Qt 6
    // and shadowing it only works by accident
    readonly property var look: {
        if (isKde) return {
            background: Kirigami.Theme.backgroundColor,
            accent:     Kirigami.Theme.highlightColor,
            onSurface:  Kirigami.Theme.textColor,
            danger:     Kirigami.Theme.negativeTextColor,
            dividerMix: 0.16,
            trackMix:   0.22,
            knobIsBackground: true,
            dangerIsAccent: false
        }
        // no colour at all: the "on" state is simply brighter than the "off" one.
        // Kept dark like the others because the panel forms draw straight onto the
        // panel; the labels there take the panel's own text colour (PanelStrip).
        if (isMinimal) return {
            background: "#141414",
            accent:     "#e8e8e6",
            onSurface:  "#f2f2f0",
            danger:     "#9a9a96",
            dividerMix: 0.086,
            trackMix:   0.108,
            knobIsBackground: true,
            dangerIsAccent: false
        }
        if (isNeon) return {
            background: "#05060f",
            accent:     "#00f5d4",
            onSurface:  "#d7fff7",
            danger:     "#ff3ea5",
            dividerMix: 0.12,
            trackMix:   0.12,
            knobIsBackground: true,
            dangerIsAccent: false
        }
        return {
            background: "#1a1a1a",
            accent:     "#ff4444",
            onSurface:  "#ffffff",
            danger:     "#ff4444",
            dividerMix: 0.087,
            trackMix:   0.109,
            knobIsBackground: false,
            dangerIsAccent: true
        }
    }

    // ── the three the user can set ────────────────────────────────────────
    readonly property color themeAccent: look.accent
    readonly property color themeBackground: look.background
    readonly property color themeText: look.onSurface

    // Only "#rrggbb" is honoured. A hand-edited value, or "#aarrggbb" from a
    // build that still allowed alpha, falls back to the look instead of
    // logging a QColor assignment error and leaving the previous colour behind.
    function _valid(s) {
        return /^#[0-9a-fA-F]{6}$/.test(s);
    }

    readonly property color accent: _valid(accentOverride) ? accentOverride : themeAccent
    readonly property color background: _valid(backgroundOverride)
                                        ? backgroundOverride : themeBackground
    readonly property color onSurface: _valid(textOverride) ? textOverride : themeText
    // the panel forms follow the panel's own text colour unless this is set
    readonly property bool textIsCustom: _valid(textOverride)

    // ── derived from those, so an override carries all the way through ────
    // Opaque rather than translucent: the panel forms draw onto the panel, not
    // onto the card, where a translucent track would show the panel through.
    function _blend(fg, bg, amount) {
        return Qt.rgba(bg.r + (fg.r - bg.r) * amount,
                       bg.g + (fg.g - bg.g) * amount,
                       bg.b + (fg.b - bg.b) * amount,
                       1.0);
    }

    // The one exception: the divider only ever sits on the card, and the card can
    // be see-through on the desktop. A tint of the text colour lands on exactly
    // the blended colour over a solid card, and fades along with a faded one
    // instead of standing out as the darkest line on it.
    readonly property color divider: Qt.rgba(onSurface.r, onSurface.g, onSurface.b,
                                             look.dividerMix)
    readonly property color trackOff: _blend(onSurface, background, look.trackMix)
    readonly property color knob: look.knobIsBackground ? background : onSurface
    readonly property color danger: look.dangerIsAccent ? accent : look.danger

    // ── type ──────────────────────────────────────────────────────────────
    readonly property string fontFamily: isKde ? Kirigami.Theme.defaultFont.family
                                       : isMinimal ? elegantFamily
                                       : isNeon ? "monospace" : dotFamily

    // the dot-matrix, geometric and monospace faces want air; a UI face does not
    readonly property real headerSpacing: isKde ? 1.0 : isMinimal ? 2.2 : 3.0
    readonly property real labelSpacing: isKde ? 0.4 : isMinimal ? 1.0 : 1.5
    readonly property int titleWeight: isKde ? Font.DemiBold
                                     : isMinimal ? Font.Normal
                                     : isNeon ? Font.Bold : Font.Medium
}
