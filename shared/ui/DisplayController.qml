// Shared brain for both packages. Reads the display layout from kscreen-doctor,
// publishes it as a model, and applies toggles. Draws nothing itself.
//
// It also carries the type tokens, so the desktop card and the panel strip
// render in the same face without either one owning the font.
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: ctl

    visible: false
    implicitWidth: 0
    implicitHeight: 0

    // ── state ─────────────────────────────────────────────────────────────
    // roles: conn (connector name), type (libkscreen Output::Type), enabled, label
    property alias outputs: outputModel
    property int enabledCount: 0
    property bool busy: false
    // false until kscreen-doctor has answered once, so callers can keep the
    // "no output found" line hidden at startup instead of flashing it
    property bool queried: false

    // ── type tokens ───────────────────────────────────────────────────────
    // Two static faces baked out of the Doto variable font at ROND=100, one per
    // weight — see tools/make-fonts.py. Doto has no named instance with round
    // dots, and asking for the axis at runtime through font.variableAxes renders
    // the wrong glyphs inside plasmashell, so the axis is baked in instead.
    // Both files register the same family; font.weight picks the face.
    readonly property string uiFont: dotRegular.status === FontLoader.Ready
                                     ? dotRegular.name : "monospace"

    // the toggle we are waiting for kscreen to actually apply
    property string _pendingConn: ""
    property bool _pendingWant: false
    property int _pendingTries: 0
    // model signature: only rebuild when the set of outputs changes
    property string _signature: ""

    // ── public API ────────────────────────────────────────────────────────

    // the last enabled output cannot be switched off
    function isLocked(isEnabled) {
        return isEnabled && ctl.enabledCount < 2;
    }

    function toggle(conn, isEnabled) {
        if (ctl.busy || ctl.isLocked(isEnabled)) return;
        ctl._pendingConn = conn;
        ctl._pendingWant = !isEnabled;
        ctl._pendingTries = 0;
        runDS.exec("kscreen-doctor output." + conn + (isEnabled ? ".disable" : ".enable"));
    }

    // ── implementation ────────────────────────────────────────────────────

    FontLoader {
        id: dotRegular
        source: Qt.resolvedUrl("../fonts/Doto-Round-Regular.ttf")
    }

    // never referenced by name, but loading it is what makes the Medium face exist
    FontLoader {
        id: dotMedium
        source: Qt.resolvedUrl("../fonts/Doto-Round-Medium.ttf")
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
            // an answer, even a failing one: the error line may now be shown
            ctl.queried = true;
            if (!data || data["exit code"] !== 0) return;
            ctl._handleQuery(data.stdout || "");
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
            ctl.busy = true;
            failsafeTimer.restart();
            connectSource(cmd);
        }
    }

    // kscreen needs a moment before the new state can be read back
    Timer {
        id: settleTimer
        interval: 1500
        repeat: false
        onTriggered: queryDS.refresh()
    }

    // kscreen was not done yet: ask again instead of trusting a fixed delay
    Timer {
        id: retryTimer
        interval: 600
        repeat: false
        onTriggered: queryDS.refresh()
    }

    // the command never came back: do not sit in "SWITCHING" forever
    Timer {
        id: failsafeTimer
        interval: 12000
        repeat: false
        onTriggered: ctl._clearPending()
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!ctl.busy) queryDS.refresh()
    }

    function _clearPending() {
        retryTimer.stop();
        failsafeTimer.stop();
        ctl._pendingConn = "";
        ctl._pendingTries = 0;
        ctl.busy = false;
    }

    // Stop showing "SWITCHING" only once kscreen reports the state we asked for.
    // A fixed delay guesses wrong on a slow enable and paints one stale frame.
    function _resolvePending(list) {
        var found = false;
        var applied = false;
        for (var i = 0; i < list.length; i++) {
            if (list[i].conn === ctl._pendingConn) {
                found = true;
                applied = (list[i].enabled === ctl._pendingWant);
                break;
            }
        }
        // an output that dropped out of the list is certainly not enabled
        if (!found) applied = (ctl._pendingWant === false);

        if (applied) {
            ctl._clearPending();
        } else if (++ctl._pendingTries < 12) {
            retryTimer.restart();
        } else {
            ctl._clearPending(); // give up: the 4 s poll keeps the row honest
        }
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
        if (sig !== ctl._signature) {
            ctl._signature = sig;
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
        ctl.enabledCount = n;

        if (ctl._pendingConn !== "") ctl._resolvePending(list);
    }
}
