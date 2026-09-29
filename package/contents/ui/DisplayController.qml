// The brain behind every form. Reads the display layout from kscreen-doctor,
// publishes it as a model, and applies toggles. Draws nothing itself.
//
// It also carries the type tokens, so the desktop card and the panel strip
// render in the same face without either one owning the font.
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: ctl

    // Nothing to draw and no size. Deliberately not visible:false — that would
    // make the Theme child resolve every Kirigami colour to black.
    implicitWidth: 0
    implicitHeight: 0

    // ── state ─────────────────────────────────────────────────────────────
    // roles: conn (connector name), type (libkscreen Output::Type), enabled, label
    property alias outputs: outputModel
    property int enabledCount: 0
    property bool busy: false
    // the connector a toggle is in flight for, so only that row reads SWITCHING
    readonly property string pendingConn: _pendingConn
    // the connector whose last toggle kscreen refused, shown briefly as FAILED
    property string failedConn: ""
    property string failedReason: ""
    // false until kscreen-doctor has answered once, so callers can keep the
    // "no output found" line hidden at startup instead of flashing it
    property bool queried: false

    // connector -> name the user typed in the settings; empty means "use the type"
    property var customNames: ({})
    onCustomNamesChanged: _applyLabels()

    // what the settings page offers to rename: [{conn, auto}], as JSON so the
    // applet can hand it to its config through a plain string entry
    property string outputsJson: "[]"

    // ── theme ─────────────────────────────────────────────────────────────
    property alias themeName: uiTheme.name
    property alias accentOverride: uiTheme.accentOverride
    property alias backgroundOverride: uiTheme.backgroundOverride
    property alias textOverride: uiTheme.textOverride
    readonly property alias theme: uiTheme

    Theme {
        id: uiTheme
        dotFamily: ctl.uiFont
        elegantFamily: ctl.elegantFont
    }

    // ── type tokens ───────────────────────────────────────────────────────
    // Two static faces baked out of the Doto variable font at ROND=100, one per
    // weight — see tools/make-fonts.py. Doto has no named instance with round
    // dots, and asking for the axis at runtime through font.variableAxes renders
    // the wrong glyphs inside plasmashell, so the axis is baked in instead.
    // Both files register the same family; font.weight picks the face.
    readonly property string uiFont: dotRegular.status === FontLoader.Ready
                                     ? dotRegular.name : "monospace"
    // the quiet geometric face the Minimal look uses
    readonly property string elegantFont: elegantFace.status === FontLoader.Ready
                                          ? elegantFace.name : "sans-serif"

    // the toggle we are waiting for kscreen to actually apply
    property string _pendingConn: ""
    property bool _pendingWant: false
    property int _pendingTries: 0
    // "check": a fresh read is on its way before a disable is issued, so the
    // last-display lock is decided on current state rather than a poll up to
    // 4 s old (another copy, or System Settings, may have switched one off)
    // "apply": the command was issued, waiting for kscreen to report it
    property string _pendingStage: ""
    // model signature: only rebuild when the set of outputs changes
    property string _signature: ""

    // ── public API ────────────────────────────────────────────────────────

    // the last enabled output cannot be switched off
    function isLocked(isEnabled) {
        return isEnabled && ctl.enabledCount < 2;
    }

    function toggle(conn, isEnabled) {
        if (ctl.busy || ctl.isLocked(isEnabled)) return;
        ctl.failedConn = "";
        ctl._pendingConn = conn;
        ctl._pendingWant = !isEnabled;
        ctl._pendingTries = 0;
        ctl.busy = true;
        failsafeTimer.restart();
        if (isEnabled) {
            ctl._pendingStage = "check";
            queryDS.refresh();
        } else {
            ctl._apply();
        }
    }

    // the engine runs the command through sh -c, and the connector name comes
    // from kscreen: quote it so no name can break out of its argument
    function _shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function _apply() {
        ctl._pendingStage = "apply";
        runDS.exec("kscreen-doctor " + ctl._shellQuote("output." + ctl._pendingConn
                   + (ctl._pendingWant ? ".enable" : ".disable")));
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

    FontLoader {
        id: elegantFace
        source: Qt.resolvedUrl("../fonts/Jost-Book.ttf")
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
            if (!data || data["exit code"] !== 0) {
                ctl._queryFailed();
                return;
            }
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
            // kscreen-doctor exits 0 even when it refuses ("Output ... not
            // found", a config that cannot be applied); the complaint is on
            // stderr, so that is what decides
            var err = (data && data.stderr) ? data.stderr.trim() : "";
            if (!data || data["exit code"] !== 0 || err.length > 0) {
                ctl._fail(err.length > 0 ? err : "kscreen-doctor failed");
                return;
            }
            // the command returns once the change went through; read it
            // back now, and keep asking while kscreen still reports the old
            // state instead of guessing a fixed delay
            queryDS.refresh();
        }

        function exec(cmd) {
            connectSource(cmd);
        }
    }

    // kscreen was not done yet, or the read failed: ask again
    Timer {
        id: retryTimer
        interval: 600
        repeat: false
        onTriggered: queryDS.refresh()
    }

    // FAILED stays on the row long enough to be read, then the row goes back
    // to showing the real state
    Timer {
        id: failedTimer
        interval: 4000
        repeat: false
        onTriggered: ctl.failedConn = ""
    }

    // the command never came back: do not sit in "SWITCHING" forever
    Timer {
        id: failsafeTimer
        interval: 12000
        repeat: false
        onTriggered: ctl._fail("timed out")
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
        ctl._pendingStage = "";
        ctl._pendingTries = 0;
        ctl.busy = false;
    }

    function _fail(reason) {
        ctl.failedReason = reason;
        ctl.failedConn = ctl._pendingConn;
        failedTimer.restart();
        ctl._clearPending();
    }

    // a read that returned nothing usable while a toggle is pending: without
    // this the retry chain would stop and busy would hang until the failsafe
    function _queryFailed() {
        if (ctl._pendingConn === "") return;
        if (++ctl._pendingTries < 12) retryTimer.restart();
        else ctl._fail("kscreen-doctor gave no answer");
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
            ctl._fail("kscreen never reported the change");
        }
    }

    // the fresh read before a disable: decide the lock on what is true now
    function _resolveCheck(list) {
        var stillOn = 0;
        var target = null;
        for (var i = 0; i < list.length; i++) {
            if (list[i].enabled) stillOn++;
            if (list[i].conn === ctl._pendingConn) target = list[i];
        }
        if (!target || !target.enabled) {
            ctl._clearPending(); // already off, or gone: nothing to do
        } else if (stillOn < 2) {
            ctl._clearPending(); // became the last one on meanwhile: keep it
        } else {
            ctl._apply();
        }
    }

    // Name every row: the connector type, numbered when several share it, unless
    // the user gave that connector a name of their own. Kept as its own pass so a
    // rename lands immediately instead of waiting for the next poll.
    function _applyLabels() {
        var totals = {};
        var i;
        for (i = 0; i < outputModel.count; i++) {
            var tn = _typeName(outputModel.get(i).type);
            totals[tn] = (totals[tn] || 0) + 1;
        }

        var seen = {};
        var known = [];
        var custom = ctl.customNames || ({});
        for (i = 0; i < outputModel.count; i++) {
            var o = outputModel.get(i);
            var auto = _typeName(o.type);
            if (totals[auto] > 1) {
                seen[auto] = (seen[auto] || 0) + 1;
                auto = auto + " " + seen[auto];
            }
            var given = custom[o.conn];
            var label = (given && given.length > 0) ? given : auto;
            if (o.label !== label) outputModel.setProperty(i, "label", label);
            known.push({ conn: o.conn, auto: auto });
        }

        var json = JSON.stringify(known);
        if (json !== ctl.outputsJson) ctl.outputsJson = json;
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
            ctl._queryFailed();
            return; // malformed output: keep the last known state
        }

        var sig = list.map(function (x) { return x.conn; }).join(",");
        if (sig !== ctl._signature) {
            ctl._signature = sig;
            outputModel.clear();
            for (var c = 0; c < list.length; c++) {
                list[c].label = "";
                outputModel.append(list[c]);
            }
            _applyLabels();
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

        if (ctl._pendingConn === "") return;
        if (ctl._pendingStage === "check") ctl._resolveCheck(list);
        else ctl._resolvePending(list);
    }
}
