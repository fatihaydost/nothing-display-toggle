import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property bool busy: false
    property int enabledCount: 0
    // model signature: only rebuild when the set of outputs changes
    property string _signature: ""

    readonly property string uiFont: dotFont.status === FontLoader.Ready
                                     ? dotFont.name : "monospace"
    // Doto is a variable font: ROND=100 gives fully round dots, wght picks the weight.
    // Ignored by the monospace fallback, which simply has no such axes.
    readonly property var axesText: ({ "ROND": 100, "wght": 400 })
    readonly property var axesTitle: ({ "ROND": 100, "wght": 500 })

    FontLoader {
        id: dotFont
        source: Qt.resolvedUrl("../fonts/Doto-VariableFont.ttf")
    }

    ListModel {
        id: outputModel
    }

    P5Support.DataSource {
        id: queryDS
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (!data || data["exit code"] !== 0) return;
            root._handleQuery(data.stdout || "");
        }

        function refresh() {
            connectSource("kscreen-doctor -j");
        }
    }

    P5Support.DataSource {
        id: runDS
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            settleTimer.restart();
        }

        function exec(cmd) {
            root.busy = true;
            connectSource(cmd);
        }
    }

    // kscreen needs a moment before the new state can be read back
    Timer {
        id: settleTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.busy = false;
            queryDS.refresh();
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!root.busy) queryDS.refresh()
    }

    // libkscreen Output::Type -> short label
    function _typeName(t) {
        switch (t) {
        case 1:  return "VGA";
        case 2:
        case 3:
        case 4:
        case 5:  return "DVI";
        case 6:  return "HDMI";
        case 7:  return "LAPTOP";
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13: return "TV";
        case 14: return "DP";
        default: return "DISPLAY";
        }
    }

    function _handleQuery(raw) {
        var list = [];
        try {
            var data = JSON.parse(raw);
            var outs = data.outputs || [];
            for (var i = 0; i < outs.length; i++) {
                var o = outs[i];
                if (o.connected !== true) continue;
                list.push({
                    conn: o.name,
                    type: o.type,
                    enabled: o.enabled === true
                });
            }
        } catch (e) {
            return; // malformed output: keep the last known state
        }

        // number them when several outputs share the same type
        var totals = {};
        for (var a = 0; a < list.length; a++) {
            var tn = _typeName(list[a].type);
            totals[tn] = (totals[tn] || 0) + 1;
        }
        var seen = {};
        for (var b = 0; b < list.length; b++) {
            var name = _typeName(list[b].type);
            if (totals[name] > 1) {
                seen[name] = (seen[name] || 0) + 1;
                list[b].label = name + " " + seen[name];
            } else {
                list[b].label = name;
            }
        }

        var sig = list.map(function (x) { return x.conn; }).join(",");
        if (sig !== root._signature) {
            root._signature = sig;
            outputModel.clear();
            for (var c = 0; c < list.length; c++) outputModel.append(list[c]);
        } else {
            // same set: update states in place instead of resetting the model
            for (var d = 0; d < list.length && d < outputModel.count; d++) {
                if (outputModel.get(d).enabled !== list[d].enabled) {
                    outputModel.setProperty(d, "enabled", list[d].enabled);
                }
            }
        }

        var n = 0;
        for (var e = 0; e < list.length; e++) if (list[e].enabled) n++;
        root.enabledCount = n;
    }

    function toggleOutput(conn, isEnabled) {
        if (root.busy) return;
        runDS.exec("kscreen-doctor output." + conn + (isEnabled ? ".disable" : ".enable"));
    }

    fullRepresentation: Item {
        readonly property int rowCount: Math.max(1, outputModel.count)

        Layout.preferredWidth: 220
        Layout.preferredHeight: 57 * rowCount + 69
        Layout.minimumWidth: 195
        Layout.minimumHeight: 57 * rowCount + 55

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "#1a1a1a"
            radius: 22
            clip: true

            Column {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 8

                // ── header ───────────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 12

                    Text {
                        text: "DISPLAYS"
                        color: "#ffffff"
                        opacity: 0.5
                        font.pixelSize: 11
                        font.letterSpacing: 3
                        font.family: root.uiFont
                        font.variableAxes: root.axesTitle
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // red status dot — pings like a radar while any output is on
                    Item {
                        width: 7
                        height: 7
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: hdrRight.left
                        anchors.rightMargin: 7

                        Rectangle {
                            id: halo
                            anchors.centerIn: parent
                            width: 7
                            height: 7
                            radius: 3.5
                            color: "#ff4444"
                            visible: root.enabledCount > 0

                            SequentialAnimation {
                                running: true
                                loops: Animation.Infinite
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: halo; property: "scale"
                                        from: 1.0; to: 2.6; duration: 1200
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: halo; property: "opacity"
                                        from: 0.5; to: 0.0; duration: 1200
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                PauseAnimation { duration: 500 }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 3.5
                            color: "#ff4444"
                            opacity: root.enabledCount > 0 ? 1.0 : 0.28
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Text {
                        id: hdrRight
                        text: root.enabledCount + "/" + outputModel.count
                        color: "#ffffff"
                        opacity: 0.5
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        font.family: root.uiFont
                        font.variableAxes: root.axesText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                }

                // ── one row per output ────────────────────────────────────
                Repeater {
                    model: outputModel

                    delegate: Column {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#2e2e2e"
                            visible: index > 0
                        }

                        ToggleRow {
                            width: parent.width
                            title: model.label
                            connector: model.conn
                            fontFamily: root.uiFont
                            axesTitle: root.axesTitle
                            axesText: root.axesText
                            on: model.enabled
                            busy: root.busy
                            // the last enabled output cannot be switched off
                            locked: model.enabled && root.enabledCount < 2
                            onToggled: root.toggleOutput(model.conn, model.enabled)
                        }
                    }
                }

                // shown when kscreen-doctor is missing or reports no outputs
                Text {
                    visible: outputModel.count === 0
                    width: parent.width
                    text: "NO OUTPUT FOUND\nIS KSCREEN-DOCTOR INSTALLED?"
                    color: "#ff4444"
                    opacity: 0.9
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.family: root.uiFont
                    font.variableAxes: root.axesText
                    wrapMode: Text.WordWrap
                }

                // ── dot-matrix strip ──────────────────────────────────────
                Row {
                    width: parent.width
                    height: 6
                    spacing: (parent.width - (12 * 6)) / 11

                    Repeater {
                        model: 12

                        delegate: Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            // lit fraction of the strip = fraction of outputs that are on
                            color: outputModel.count > 0
                                   && index < Math.round(12 * root.enabledCount / outputModel.count)
                                   ? "#ff4444" : "#333333"
                            opacity: 0.9
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
