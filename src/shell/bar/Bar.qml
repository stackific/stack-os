// The Stack OS bar: a thin strip along the top of every monitor holding the
// bar widgets, left to right. Each widget lives in its own folder under
// src/shell/ so it can later become a plugin without a rewrite (decision 05).
//
// M1 widgets: the terminal launcher (001-02) at the left end and the power
// menu (001-03) at the right end.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../power"
import "../terminal"

Scope {
    id: root

    // Monitor whose power menu is open, or null; shared by the click and the
    // `power toggle` IPC call, so one menu is open at a time.
    property var menuScreen: null

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.menuScreen = root.menuScreen ? null : (Quickshell.screens[0] ?? null);
        }
    }

    // One bar per monitor; Variants creates and removes them on hotplug.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 32
            color: "#1e1e2e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 4

                TerminalButton {
                    Layout.alignment: Qt.AlignVCenter
                }

                // Pushes the power menu to the right end.
                Item {
                    Layout.fillWidth: true
                }

                PowerButton {
                    Layout.alignment: Qt.AlignVCenter
                    bar: root
                    screen: modelData
                }
            }
        }
    }
}
