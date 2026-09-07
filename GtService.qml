import QtQuick
import "SportsModel.js" as SportsModel
import "GtModel.js" as GtModel

QtObject {
  id: root

  property double now: Date.now()
  property int refreshMinutes: 15
  property string highlightPlayer: ""
  property string highlightTeam: ""
  property string continentFilter: "all"

  property var events: []
  property var allEvents: []
  property var playerRows: []
  property var teamRows: []

  readonly property int currentIndex: SportsModel.currentEventIndex(events, now)
  readonly property var event: currentIndex >= 0 ? events[currentIndex] : null
  readonly property var upcoming: SportsModel.upcomingEvents(events, currentIndex, 3)
  readonly property var weekend: SportsModel.weekendState(event, now, "GT")
  readonly property var liveSession: event ? SportsModel.liveSession(event, now) : null
  readonly property var playerStandings: SportsModel.standingsWithPin(playerRows, 5, highlightPlayer)
  readonly property var teamStandings: SportsModel.standingsWithPin(teamRows, 5, highlightTeam)
  readonly property var recent: []
  readonly property bool offSeason: events.length > 0 && currentIndex < 0
  readonly property bool loaded: events.length > 0
  readonly property bool stale: false
  readonly property bool failed: false
  readonly property double lastUpdatedAt: now

  function applyFilter() {
    var all = root.allEvents
    if (root.continentFilter && root.continentFilter !== "all") {
      var out = []
      for (var i = 0; i < all.length; i++) {
        if (all[i].continent === root.continentFilter) out.push(all[i])
      }
      root.events = out
    } else {
      root.events = all
    }
  }

  function refresh(force) {
    root.allEvents = GtModel.seedCalendar()
    applyFilter()
  }

  onContinentFilterChanged: applyFilter()

  Component.onCompleted: refresh(false)
}
