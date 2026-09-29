import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: page

    property string cfg_outputNames
    property string cfg_outputNamesDefault: "{}"

    // written by the widget itself whenever the set of connected outputs changes
    readonly property var known: {
        try {
            return JSON.parse(Plasmoid.configuration.knownOutputs || "[]");
        } catch (e) {
            return [];
        }
    }

    // Derived from the setting rather than cached once: the fields are built
    // before this page's own Component.onCompleted runs, and the Defaults
    // button rewrites the setting behind our back.
    readonly property var names: {
        try {
            return JSON.parse(page.cfg_outputNames || "{}");
        } catch (e) {
            return ({});
        }
    }

    function rename(conn, value) {
        var next = {};
        for (var k in page.names) next[k] = page.names[k];

        var trimmed = value.trim();
        if (trimmed.length > 0) {
            next[conn] = trimmed;
        } else {
            delete next[conn];
        }

        page.cfg_outputNames = JSON.stringify(next);
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            model: page.known

            delegate: QQC2.TextField {
                id: field

                readonly property string stored: page.names[modelData.conn] || ""

                Kirigami.FormData.label: modelData.conn
                placeholderText: modelData.auto
                maximumLength: 24
                // not bound, so typing does not fight the binding; refreshed
                // only when the stored value moves away from what is typed
                // (Defaults, or a rename of the same connector elsewhere)
                Component.onCompleted: text = stored
                onStoredChanged: if (text.trim() !== stored) text = stored
                onTextEdited: page.rename(modelData.conn, text)
            }
        }

        QQC2.Label {
            visible: page.known.length === 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("No displays reported yet. Close this window, give the widget a moment, and open it again.")
        }

        QQC2.Label {
            visible: page.known.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: i18n("Empty a field to go back to the name the widget works out on its own, shown in grey.")
        }
    }
}
