import QtQuick
import Quickshell
import Quickshell.Io

// Scaffold for SRO / Swiss Timing live. No public unauthenticated feed.
QtObject {
  id: root

  property double now: Date.now()
  property bool enabled: false
  property int refreshSeconds: 12
  property var scheduledSession: null

  property var grid: []
  property string lastError: ""
  property double lastUpdateAt: 0
  readonly property bool hasLiveSession: scheduledSession !== null
  readonly property bool hasData: false
  readonly property bool polls: false
  readonly property string sessionName: scheduledSession ? scheduledSession.name : ""
  readonly property string statusLabel: "NO FEED"
  readonly property string statusKind: "warn"
  readonly property string liveReason: "Live GT timing needs SRO/Swiss Timing credentials in ~/.config/omarchy/sports-tracker/credentials (sro_timing=…)."
  readonly property int currentLap: 0
  readonly property int totalLaps: 0

  function refreshNow() {
    if (checkProc.running) return
    checkProc.running = true
  }

  property Process checkProc: Process {
    command: ["sh", "-c",
      'set -eu\n' +
      'f="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/sports-tracker/credentials"\n' +
      '[ -f "$f" ] && [ ! -L "$f" ] && [ -O "$f" ] || { echo no; exit 0; }\n' +
      'case "$(stat -c %a "$f" 2>/dev/null)" in 600|400) ;; *) echo no; exit 0 ;; esac\n' +
      'if grep -q "^sro_timing=" "$f"; then echo yes; else echo no; fi']
    stdout: StdioCollector { waitForEnd: true }
  }

  onEnabledChanged: refreshNow()
}
