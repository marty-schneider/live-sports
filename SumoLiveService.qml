import QtQuick

// Free live view: today's Makuuchi torikumi, filled in as bouts complete.
QtObject {
  id: root

  property double now: Date.now()
  property bool enabled: false
  property int refreshSeconds: 12
  property var scheduledSession: null
  property var bouts: []

  readonly property var grid: bouts
  readonly property bool hasLiveSession: scheduledSession !== null || (enabled && bouts.length > 0)
  readonly property bool hasData: grid.length > 0
  readonly property bool polls: enabled
  readonly property string sessionName: scheduledSession ? scheduledSession.name : "Makuuchi"
  readonly property string lastError: ""
  readonly property double lastUpdateAt: now
  readonly property string statusLabel: hasData ? "TORIKUMI" : "WAITING"
  readonly property string statusKind: hasData ? "live" : "neutral"
  readonly property string liveReason: hasData ? "" : "Bouts appear here as the day’s Makuuchi card is published."
  readonly property int currentLap: 0
  readonly property int totalLaps: 0

  function refreshNow() {}
}
