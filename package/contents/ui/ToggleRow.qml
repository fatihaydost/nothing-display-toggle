import QtQuick

Item {
    id: row

    property string title: ""
    property string connector: ""
    property string fontFamily: ""
    property var axesTitle: ({})
    property var axesText: ({})
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

    // red accent bar
    Rectangle {
        id: bar
        width: 3
        height: 28
        radius: 1.5
        color: "#ff4444"
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
            color: "#ffffff"
            opacity: row.on ? 1.0 : 0.45
            font.pixelSize: 17
            font.family: row.fontFamily
            font.variableAxes: row.axesTitle

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            text: row.busy ? "SWITCHING" : (row.on ? row.connector : "SLEEPING")
            color: row.on ? "#ffffff" : "#ff4444"
            opacity: row.on ? 0.45 : 0.9
            font.pixelSize: 9
            font.letterSpacing: 1.5
            font.family: row.fontFamily
            font.variableAxes: row.axesText
        }
    }

    // Nothing-style pill toggle
    Rectangle {
        id: track
        width: 44
        height: 22
        radius: 11
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: row.on ? "#ff4444" : "#333333"
        opacity: row.busy ? 0.55 : (row.locked ? 0.7 : 1.0)

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            x: row.on ? parent.width - width - 3 : 3

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
        }
    }
}
