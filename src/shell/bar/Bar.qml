// The Stack OS bar: a thin strip along the top of every monitor holding the
// bar widgets, left to right. Each widget lives in its own folder under
// src/shell/ so it can later become a plugin without a rewrite (decision 05).
//
// M1 widgets: the terminal launcher (001-02); the power menu follows (001-03).
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../terminal"

Scope {
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

                // Pushes later widgets (the power menu) to the right end.
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
