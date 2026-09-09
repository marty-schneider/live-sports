import QtQuick
import Quickshell
import Quickshell.Io
import "CsModel.js" as CsModel
import "SportsTime.js" as SportsTime

// Scaffold for PandaScore live CS. Without a token the panel stays honest.
QtObject {
  id: root

  property double now: Date.now()
  property bool enabled: false
  property int refreshSeconds: 12
  property var scheduledSession: null
  property var matches: []

  property var grid: []
  property string lastError: ""
  property double lastUpdateAt: 0
  property string statusLabel: "IDLE"
  property string statusKind: "neutral"
  property string liveReason: ""
  property bool hasToken: false
  property bool polls: false

  readonly property var freeLive: CsModel.liveMatches(matches, now)
  readonly property bool hasLiveSession: scheduledSession !== null || freeLive.length > 0
  readonly property bool hasData: grid.length > 0 || (!hasToken && freeLive.length > 0)
  readonly property string sessionName: scheduledSession ? scheduledSession.name : ""
  readonly property int currentLap: 0
  readonly property int totalLaps: 0

  function refreshNow() {
    if (!enabled) return
    if (tokenProc.running) return
    tokenProc.running = true
  }

  function applyTokenCheck(raw) {
    var text = String(raw || "")
    root.hasToken = text.indexOf("yes") === 0
    if (!root.hasToken) {
      root.polls = false
      if (root.freeLive.length > 0) {
        root.liveReason = ""
        root.statusLabel = "LIVE"
        root.statusKind = "live"
      } else {
        root.liveReason = "No live CS match on the free feed. A PandaScore token in ~/.config/omarchy/sports-tracker/credentials unlocks round-by-round timing."
        root.statusLabel = "WAITING"
        root.statusKind = "neutral"
      }
      return
    }
    root.liveReason = ""
    root.polls = root.enabled
    if (root.enabled) pollProc.running = true
  }

  function applyLive(raw) {
    var parsed = CsModel.parsePandaScoreRunning(raw)
    if (parsed.length > 0) {
      root.grid = parsed
      root.lastUpdateAt = Date.now()
      root.lastError = ""
      root.statusLabel = "LIVE"
      root.statusKind = "live"
    } else {
      root.statusLabel = "NO MATCH"
      root.statusKind = "neutral"
      root.liveReason = "No live PandaScore CS match right now."
    }
  }

  readonly property string credentialsPrelude:
    'f="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/sports-tracker/credentials"\n' +
    'cred_ok() {\n' +
    '  [ -f "$f" ] && [ ! -L "$f" ] && [ -O "$f" ] || return 1\n' +
    '  case "$(stat -c %a "$f" 2>/dev/null)" in 600|400) return 0 ;; *) return 1 ;; esac\n' +
    '}\n'

  property Process tokenProc: Process {
    command: ["sh", "-c",
      'set -eu\n' + root.credentialsPrelude +
      'if cred_ok && grep -q "^pandascore_token=" "$f"; then echo yes; else echo no; fi']
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyTokenCheck(text)
    }
  }

  property Process pollProc: Process {
    command: ["sh", "-c",
      'set -eu\n' + root.credentialsPrelude +
      'cred_ok || exit 1\n' +
      'tok=$(sed -n "s/^pandascore_token=//p" "$f" | head -1 | tr -d "\\r")\n' +
      'case "$tok" in ""|*[!A-Za-z0-9._~+/=-]*) exit 1 ;; esac\n' +
      'curl -fsS --proto "=https" --max-redirs 0 \\\n' +
      '  --max-filesize 1048576 --max-time 12 \\\n' +
      '  -H "Authorization: Bearer ${tok}" \\\n' +
      '  -H "User-Agent: Mozilla/5.0 (compatible; omarchy-sports-tracker/0.8)" \\\n' +
      '  "https://api.pandascore.co/csgo/matches/running?per_page=1"\n']
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyLive(text)
    }
  }

  property Timer poll: Timer {
    interval: Math.max(5, root.refreshSeconds) * 1000
    running: root.enabled && root.hasToken
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNow()
  }

  onEnabledChanged: refreshNow()
}
