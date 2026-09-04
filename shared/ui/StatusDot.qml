// Red status dot that pings like radar while anything is live.
// Used by the desktop card header and by the panel badge.
import QtQuick

Item {
    id: dot

    property bool live: false
    property real size: 7

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: halo
        anchors.centerIn: parent
        width: dot.size
        height: dot.size
        radius: dot.size / 2
        color: "#ff4444"
        visible: dot.live

        SequentialAnimation {
            running: dot.live && dot.visible
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
        radius: dot.size / 2
        color: "#ff4444"
        opacity: dot.live ? 1.0 : 0.28
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
