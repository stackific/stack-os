// Bar widget: the power icon and its menu (Lock, Log out, Restart, Shut down).
//
// The menu opens below the icon on the monitor it was clicked on; which monitor
// is open is kept by the bar (`menuScreen`), so the `power toggle` IPC call and
// a click share one state. Lock goes through the lock's own IPC call, the same
// one Super+L uses. In the dev session (STACK_OS_DEV=1) Restart and Shut down
// only print the command, and the menu says so.
import QtQuick
import Quickshell

Item {
    id: root

    // The bar's Scope, which owns `menuScreen`, and this bar's monitor.
    required property var bar
    required property var screen

    readonly property bool dev: Quickshell.env("STACK_OS_DEV") === "1"
    readonly property bool open: bar.menuScreen === screen

    implicitWidth: 28
    implicitHeight: 28

    function close(): void {
        bar.menuScreen = null;
    }

    // Restart and Shut down only print in the dev session.
    function power(command): void {
        close();
        if (dev)
            console.info("dev session, not running: " + command.join(" "));
        else
            Quickshell.execDetached(command);
    }

    // Hover and pressed highlight, as on the terminal button.
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouse.pressed || root.open ? "#585b70" : mouse.containsMouse ? "#45475a" : "transparent"
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        sourceSize: Qt.size(width, height)
        source: Qt.resolvedUrl("power.svg")
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.bar.menuScreen = root.open ? null : root.screen
    }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.rect.y: root.height + 6
        anchor.rect.x: root.width - implicitWidth
        implicitWidth: 200
        implicitHeight: items.implicitHeight + 12
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#1e1e2e"
            border.color: "#45475a"

            Column {
                id: items

                anchors.fill: parent
                anchors.margins: 6

                MenuItem {
                    text: "Lock"
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "lock", "lock"]);
                    }
                }
                MenuItem {
                    text: "Log out"
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["mmsg", "dispatch", "quit"]);
                    }
                }
                MenuItem {
                    text: "Restart"
                    onClicked: root.power(["systemctl", "reboot"])
                }
                MenuItem {
                    text: "Shut down"
                    onClicked: root.power(["systemctl", "poweroff"])
                }

                Text {
                    visible: root.dev
                    width: parent.width
                    leftPadding: 10
                    topPadding: 4
                    bottomPadding: 2
                    wrapMode: Text.WordWrap
                    color: "#a6adc8"
                    font.pixelSize: 11
                    text: "Development session: Restart and Shut down only print."
                }
            }
        }
    }
}
