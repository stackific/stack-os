// Entry point of the Stack OS shell, loaded by Quickshell (`qs -p src/shell/`).
//
// One Quickshell process owns the whole shell (decision 05); this file only
// assembles its components, each of which lives in its own folder. M1 has one
// component so far: the bar.
import Quickshell
import "bar"

ShellRoot {
    Bar {}
}
