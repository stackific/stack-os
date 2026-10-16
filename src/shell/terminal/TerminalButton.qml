// Bar widget that opens the foot terminal.
//
// The icon is an SVG shipped next to this file, because the installed system
// has no icon theme. foot is started detached, not as a child of the shell,
// so a live reload does not close it.
import QtQuick
import Quickshell

Item {
    id: root

    implicitWidth: 28
    implicitHeight: 28

    // Hover highlight, so the icon reads as a button.
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouse.pressed ? "#585b70" : mouse.containsMouse ? "#45475a" : "transparent"
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        sourceSize: Qt.size(width, height)
        source: Qt.resolvedUrl("terminal.svg")
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["foot"])
    }
}
