import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    id: page

    property string cfg_theme
    property string cfg_themeDefault: "nothing"
    property string cfg_accentColor
    property string cfg_accentColorDefault: ""

    // what the colour button should show: the user's pick, or the look's own accent
    readonly property color effectiveAccent: page.cfg_accentColor.length > 0
                                             ? page.cfg_accentColor
                                             : liveTheme.themeAccent

    Theme {
        id: liveTheme
        name: page.cfg_theme
    }

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
            Kirigami.FormData.label: i18n("Look:")
            text: i18n("Nothing")
            checked: page.cfg_theme !== "kde" && page.cfg_theme !== "minimal"
                     && page.cfg_theme !== "neon"
            onToggled: if (checked) page.cfg_theme = "nothing"
        }
        Swatch { themeName: "nothing" }
        Hint { text: i18n("Dot-matrix type, red on near-black. The original.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            text: i18n("Classic KDE")
            checked: page.cfg_theme === "kde"
            onToggled: if (checked) page.cfg_theme = "kde"
        }
        Swatch { themeName: "kde" }
        Hint { text: i18n("Your desktop theme's colours and interface font. Follows light and dark.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            text: i18n("Minimal")
            checked: page.cfg_theme === "minimal"
            onToggled: if (checked) page.cfg_theme = "minimal"
        }
        Swatch { themeName: "minimal" }
        Hint { text: i18n("No colour at all: greys and the interface font. A switched-on display is simply brighter.") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            text: i18n("Neon")
            checked: page.cfg_theme === "neon"
            onToggled: if (checked) page.cfg_theme = "neon"
        }
        Swatch { themeName: "neon" }
        Hint { text: i18n("Aqua and magenta on black, in a monospace face.") }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Accent colour:")
            spacing: Kirigami.Units.smallSpacing

            KQC.ColorButton {
                id: accentButton
                showAlphaChannel: false
                dialogTitle: i18n("Accent colour")
                color: page.effectiveAccent
                onAccepted: (picked) => page.cfg_accentColor = picked.toString()
            }

            QQC2.Button {
                text: i18n("Use the look's own")
                enabled: page.cfg_accentColor.length > 0
                icon.name: "edit-undo-symbolic"
                onClicked: page.cfg_accentColor = ""
            }
        }

        Hint {
            text: page.cfg_accentColor.length > 0
                  ? i18n("Your colour, on top of the chosen look. Everything the widget paints in colour follows it: the switches, the bar beside each name and the status dot.")
                  : i18n("Following the chosen look. Pick a colour to override it.")
        }

        Item { Kirigami.FormData.isSection: true }

        Hint {
            text: i18n("Only colours and typefaces change between looks. Sizes, spacing and motion stay the same in every one.")
        }
    }
}
