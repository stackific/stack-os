// The Stack OS lock screen (decision 03): Quickshell's session lock, with a
// lock surface on every monitor and the password checked through PAM.
//
// Locking is one IPC call, `qs ipc call lock lock`, used by the power menu and
// by the Super+L binding alike. The PAM service is Stack OS's own password-only
// file (src/pam/stack-os-lock), read from /usr/share/stack-os/pam/ unless
// STACK_OS_PAM_DIR points elsewhere (the dev session points it at the repo).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
    id: root

    // Shared by every monitor's surface, so typing on one shows on all.
    property string password: ""
    property bool busy: false
    // Message under the field: empty, "Wrong password", or a PAM problem.
    property string error: ""

    function lock(): void {
        sessionLock.locked = true;
    }

    function tryUnlock(): void {
        if (password === "" || busy)
            return;
        busy = true;
        // start() returns false without any signal when PAM cannot begin
        // (e.g. the service file is missing); never stay busy for ever.
        if (!pam.start())
            fail("Could not check the password");
    }

    function fail(message): void {
        busy = false;
        password = "";
        error = message;
        console.warn("lock: " + message);
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.env("STACK_OS_PAM_DIR") || "/usr/share/stack-os/pam"
        config: "stack-os-lock"

        // pam_unix asks once, for the password.
        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.busy = false;
                root.password = "";
                root.error = "";
                sessionLock.locked = false;
            } else if (result === PamResult.Failed) {
                root.fail("Wrong password");
            } else {
                // Error or MaxTries: not a typo, so say so.
                root.fail("Could not check the password");
            }
        }

        onError: error => root.fail("Could not check the password")
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            color: "#11111b"

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#cdd6f4"
                    font.pixelSize: 20
                    text: "Locked"
                }

                // Password field; Enter checks it.
                Rectangle {
                    width: 260
                    height: 36
                    radius: 8
                    color: "#1e1e2e"
                    border.color: root.error ? "#f38ba8" : "#45475a"

                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cdd6f4"
                        echoMode: TextInput.Password
                        // readOnly, not enabled: disabling would drop keyboard focus
                        // and nothing could be typed after a wrong password.
                        readOnly: root.busy
                        focus: true
                        text: root.password
                        onTextEdited: {
                            root.password = text;
                            root.error = "";
                        }
                        onAccepted: root.tryUnlock()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#f38ba8"
                    font.pixelSize: 13
                    text: root.error || " "
                }
            }
        }
    }
}
