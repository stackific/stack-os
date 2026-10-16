// Entry point of the Stack OS shell, loaded by Quickshell (`qs -p src/shell/`).
//
// M1-1 placeholder: one thin bar along the top of every monitor, proving the
// shell loads from the repository and reloads on save. The real bar replaces it
// in M1-2. STACK_OS_DEV=1 marks the nested dev session; the label shows it so
// a dev run is never mistaken for an installed system.
import QtQuick
import Quickshell

ShellRoot {
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

            Text {
                anchors.centerIn: parent
                color: "#ffffff"
                font.pixelSize: 14
                text: Quickshell.env("STACK_OS_DEV") === "1" ? "Stack OS (dev)" : "Stack OS"
            }
        }
    }
}
