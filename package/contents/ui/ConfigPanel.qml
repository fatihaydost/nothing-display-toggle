import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property string cfg_panelMode
    property string cfg_panelModeDefault: "auto"
    property alias cfg_inlineThreshold: threshold.value
    property int cfg_inlineThresholdDefault: 2

    readonly property bool isAuto: cfg_panelMode !== "inline" && cfg_panelMode !== "popup"

    // a RadioButton's `checked` binding dies on the first click; set from the
    // setting instead so the Defaults button is reflected
    function syncControls() {
        modeAuto.checked = page.isAuto;
        modeInline.checked = page.cfg_panelMode === "inline";
        modePopup.checked = page.cfg_panelMode === "popup";
    }
    onCfg_panelModeChanged: syncControls()
    Component.onCompleted: syncControls()

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.RadioButton {
            id: modeAuto
            Kirigami.FormData.label: i18n("On the panel:")
            text: i18n("Automatic")
            onToggled: if (checked) page.cfg_panelMode = "auto"
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("A switch per display while they fit, a badge once there are more.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }

        QQC2.SpinBox {
            id: threshold
            Kirigami.FormData.label: i18n("Switch to a badge above:")
            from: 1
            to: 8
            enabled: page.isAuto
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            id: modeInline
            text: i18n("Always show a switch per display")
            onToggled: if (checked) page.cfg_panelMode = "inline"
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("One click switches a display. Takes more room on the panel as displays are added.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.RadioButton {
            id: modePopup
            text: i18n("Always show a badge")
            onToggled: if (checked) page.cfg_panelMode = "popup"
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("A dot and an on/total count. Clicking opens the full card.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
    }
}
