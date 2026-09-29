import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: page

    property string cfg_theme
    property string cfg_themeDefault: "nothing"
    property string cfg_accentColor
    property string cfg_accentColorDefault: ""
    property string cfg_backgroundColor
    property string cfg_backgroundColorDefault: ""
    property string cfg_textColor
    property string cfg_textColorDefault: ""
    property alias cfg_backgroundOpacity: opacitySlider.value
    property int cfg_backgroundOpacityDefault: 100

    // the opacity only reaches the desktop card; on a panel the popup stays solid
    readonly property bool onDesktop: Plasmoid.formFactor !== PlasmaCore.Types.Horizontal
                                      && Plasmoid.formFactor !== PlasmaCore.Types.Vertical

    readonly property bool anyColourSet: cfg_accentColor.length > 0
                                         || cfg_backgroundColor.length > 0
                                         || cfg_textColor.length > 0

    Theme {
        id: liveTheme
        name: page.cfg_theme
    }

    // A RadioButton's `checked` binding dies on the first click, and
    // ColorButton.color is an alias onto its dialog, written when a colour is
    // picked. Both are therefore set from here, on every change of the
    // setting, so the Defaults button and the reset below stay in step.
    function syncControls() {
        var t = page.cfg_theme;
        lookNothing.checked = t !== "kde" && t !== "minimal" && t !== "neon";
        lookKde.checked = t === "kde";
        lookMinimal.checked = t === "minimal";
        lookNeon.checked = t === "neon";
        accentButton.color = page.cfg_accentColor.length > 0
                             ? page.cfg_accentColor : liveTheme.themeAccent;
        backgroundButton.color = page.cfg_backgroundColor.length > 0
                                 ? page.cfg_backgroundColor : liveTheme.themeBackground;
        textButton.color = page.cfg_textColor.length > 0
                           ? page.cfg_textColor : liveTheme.themeText;
    }
    onCfg_themeChanged: syncControls()
    onCfg_accentColorChanged: syncControls()
    onCfg_backgroundColorChanged: syncControls()
    onCfg_textColorChanged: syncControls()
    Component.onCompleted: syncControls()

    // background / accent / text of one theme, so the choice is visible here
    component Swatch: Item {
        id: sw
        property string themeName: "nothing"

        implicitWidth: chips.implicitWidth
        implicitHeight: chips.implicitHeight

        // sized zero and kept out of the row, but never visible:false — that
        // would resolve every Kirigami colour to black
        Theme {
            id: swTheme
            name: sw.themeName
        }

        Row {
            id: chips
            spacing: 4

            Repeater {
                model: [swTheme.background, swTheme.accent, swTheme.onSurface]

                delegate: Rectangle {
                    width: 18
                    height: 18
                    radius: 4
                    color: modelData
                    border.width: 1
                    border.color: Qt.rgba(0.5, 0.5, 0.5, 0.35)
                }
            }
        }
    }

    component Hint: QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        opacity: 0.7
        font: Kirigami.Theme.smallFont
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.RadioButton {
            id: lookNothing
            Kirigami.FormData.label: i18n("Look:")
            text: i18n("Nothing")
            onToggled: if (checked) page.cfg_theme = "nothing"
        }
        Swatch { themeName: "nothing" }
        Hint { text: i18n("Dot-matrix type, red on near-black. The original.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            id: lookKde
            text: i18n("Classic KDE")
            onToggled: if (checked) page.cfg_theme = "kde"
        }
        Swatch { themeName: "kde" }
        Hint { text: i18n("Your desktop theme's colours and interface font. Follows light and dark.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            id: lookMinimal
            text: i18n("Minimal")
            onToggled: if (checked) page.cfg_theme = "minimal"
        }
        Swatch { themeName: "minimal" }
        Hint { text: i18n("No colour at all: greys in a quiet geometric face. A switched-on display is simply brighter.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            id: lookNeon
            text: i18n("Neon")
            onToggled: if (checked) page.cfg_theme = "neon"
        }
        Swatch { themeName: "neon" }
        Hint { text: i18n("Aqua and magenta on black, in a monospace face.") }

        Item { Kirigami.FormData.isSection: true }

        KQC.ColorButton {
            id: accentButton
            Kirigami.FormData.label: i18n("Accent:")
            showAlphaChannel: false
            dialogTitle: i18n("Accent colour")
            onAccepted: (picked) => page.cfg_accentColor = picked.toString()
        }

        KQC.ColorButton {
            id: backgroundButton
            Kirigami.FormData.label: i18n("Background:")
            showAlphaChannel: false
            dialogTitle: i18n("Background colour")
            onAccepted: (picked) => page.cfg_backgroundColor = picked.toString()
        }

        KQC.ColorButton {
            id: textButton
            Kirigami.FormData.label: i18n("Text:")
            showAlphaChannel: false
            dialogTitle: i18n("Text colour")
            onAccepted: (picked) => page.cfg_textColor = picked.toString()
        }

        QQC2.Button {
            text: i18n("Back to the look's own colours")
            enabled: page.anyColourSet
            icon.name: "edit-undo-symbolic"
            onClicked: {
                page.cfg_accentColor = "";
                page.cfg_backgroundColor = "";
                page.cfg_textColor = "";
            }
        }

        Hint {
            text: page.anyColourSet
                  ? i18n("Your colours, on top of the chosen look. Dividers, the switch track and the knob are worked out from them, so nothing is left behind.")
                  : i18n("Following the chosen look. Set any of the three to override it.")
        }

        Item {
            Kirigami.FormData.isSection: true
            visible: page.onDesktop
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            visible: page.onDesktop
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: opacitySlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                from: 0
                to: 100
                stepSize: 5
                snapMode: QQC2.Slider.SnapAlways
            }

            QQC2.Label {
                // wide enough for "100%" so the slider does not shift while dragging
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                text: i18nc("opacity in percent", "%1%", Math.round(opacitySlider.value))
            }
        }

        Hint {
            visible: page.onDesktop
            text: i18n("How much of the wallpaper shows through the card. Switches and text stay solid.")
        }

        Item { Kirigami.FormData.isSection: true }

        Hint {
            text: i18n("Only colours and typefaces change between looks. Sizes, spacing and motion stay the same in every one.")
        }
    }
}
