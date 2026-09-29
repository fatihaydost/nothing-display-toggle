import QtQuick

Item {
    id: row

    property Theme theme: null
    property string title: ""
    property string connector: ""
    property bool on: true
    // this row's own toggle is in flight
    property bool busy: false
    // another row's toggle is in flight: clicks here are ignored until it lands
    property bool blocked: false
    // last enabled output cannot be switched off
    property bool locked: false
    // kscreen refused the last toggle on this row
    property bool failed: false

    signal toggled()

    implicitHeight: 40

    MouseArea {
        anchors.fill: parent
        cursorShape: row.locked ? Qt.ForbiddenCursor
                   : row.blocked ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!row.locked && !row.blocked) row.toggled()
    }

    // accent bar
    Rectangle {
        id: bar
        width: 3
        height: 28
        radius: 1.5
        color: row.theme ? row.theme.accent : "#ff4444"
        opacity: row.on ? 1.0 : 0.3
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // bounded on the right by the switch, so a long name is cut with an
    // ellipsis instead of running underneath it
    Column {
        anchors.left: bar.right
        anchors.leftMargin: 9
        anchors.right: track.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.title
            color: row.theme ? row.theme.onSurface : "#ffffff"
            opacity: row.on ? 1.0 : 0.45
            font.pixelSize: 17
            font.family: row.theme ? row.theme.fontFamily : "monospace"
            font.weight: row.theme ? row.theme.titleWeight : Font.Medium

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.busy ? i18n("SWITCHING")
                : row.failed ? i18n("FAILED")
                : row.on ? row.connector : i18n("SLEEPING")
            color: (row.on && !row.failed) ? (row.theme ? row.theme.onSurface : "#ffffff")
                                           : (row.theme ? row.theme.danger : "#ff4444")
            opacity: (row.on && !row.failed) ? 0.45 : 0.9
            font.pixelSize: 9
            font.letterSpacing: row.theme ? row.theme.labelSpacing : 1.5
            font.family: row.theme ? row.theme.fontFamily : "monospace"
        }
    }

    // pill toggle
    Rectangle {
        id: track
        width: 44
        height: 22
        radius: 11
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: row.on ? (row.theme ? row.theme.accent : "#ff4444")
                      : (row.theme ? row.theme.trackOff : "#333333")
        opacity: row.busy ? 0.55 : (row.locked ? 0.7 : 1.0)

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: row.theme ? row.theme.knob : "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            x: row.on ? parent.width - width - 3 : 3

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
        }
    }
}
