import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property string cfg_theme
    property string cfg_themeDefault: "nothing"

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

        Hint {
            text: i18n("Only colours and typefaces change. Sizes, spacing and motion stay the same in every look.")
        }
    }
}
