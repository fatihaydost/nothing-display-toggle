import QtQuick

Item {
    id: row

    property Theme theme: null
    property string title: ""
    property string connector: ""
    property bool on: true
    property bool busy: false
    // last enabled output cannot be switched off
    property bool locked: false

    signal toggled()

    implicitHeight: 40

    MouseArea {
        anchors.fill: parent
        cursorShape: row.locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
        onClicked: if (!row.locked) row.toggled()
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

    Column {
        anchors.left: bar.right
        anchors.leftMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
            text: row.title
            color: row.theme ? row.theme.onSurface : "#ffffff"
            opacity: row.on ? 1.0 : 0.45
            font.pixelSize: 17
            font.family: row.theme ? row.theme.fontFamily : "monospace"
            font.weight: row.theme ? row.theme.titleWeight : Font.Medium

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            text: row.busy ? "SWITCHING" : (row.on ? row.connector : "SLEEPING")
            color: row.on ? (row.theme ? row.theme.onSurface : "#ffffff")
                          : (row.theme ? row.theme.danger : "#ff4444")
            opacity: row.on ? 0.45 : 0.9
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
