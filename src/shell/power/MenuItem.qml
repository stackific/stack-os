// One row of the power menu: a label that highlights on hover and emits
// `clicked`.
import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    signal clicked

    width: parent.width
    height: 32
    radius: 6
    color: mouse.pressed ? "#585b70" : mouse.containsMouse ? "#45475a" : "transparent"

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 10
        color: "#cdd6f4"
        font.pixelSize: 14
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
