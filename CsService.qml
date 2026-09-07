import QtQuick
import "SportsTime.js" as SportsTime
import "SportsModel.js" as SportsModel
import "CsModel.js" as CsModel

QtObject {
  id: root

  property double now: Date.now()
  property int refreshMinutes: 15
  property string highlightPlayer: ""
  property string highlightTeam: ""

  property var events: []
  property var teamRows: []
  property var playerRows: []
  property var matches: []

  readonly property int currentIndex: SportsModel.currentEventIndex(events, now)
  readonly property var event: currentIndex >= 0 ? events[currentIndex] : null
  readonly property var upcoming: SportsModel.upcomingEvents(events, currentIndex, 3)
  readonly property var weekend: SportsModel.weekendState(event, now, "CS")
  readonly property var liveSession: event ? SportsModel.liveSession(event, now) : null
  readonly property var teamStandings: SportsModel.standingsWithPin(teamRows, 5, highlightTeam)
  readonly property var playerStandings: SportsModel.standingsWithPin(playerRows, 5, highlightPlayer)
  readonly property var recent: matches.slice(0, 6)
  readonly property bool offSeason: events.length > 0 && currentIndex < 0
  readonly property bool loaded: events.length > 0 || teamRows.length > 0
  readonly property bool stale: calendar.isStale || rankings.isStale
  readonly property bool failed: !loaded && (calendar.status === "empty" || rankings.status === "empty")
  readonly property double lastUpdatedAt: Math.max(calendar.lastSuccessAt, rankings.lastSuccessAt, results.lastSuccessAt)

  function refresh(force) {
    calendar.fetch(force)
    rankings.fetch(force)
    results.fetch(force)
    players.fetch(force)
  }

  property CachedFetch calendar: CachedFetch {
    id: calendar
    name: "cs-seed-noop"
    url: ""
  }

  property CachedFetch rankings: CachedFetch {
    id: rankings
    name: "cs-rankings"
    url: "https://api.csapi.de/rankings/"
    ttlSeconds: Math.max(300, root.refreshMinutes * 60)
    onPayload: function(text) {
      var parsed = CsModel.parseRankings(text)
      if (parsed.length > 0) root.teamRows = parsed
    }
  }

  property CachedFetch results: CachedFetch {
    id: results
    name: "cs-matches-latest"
    url: "https://api.csapi.de/matches/latest?limit=40"
    ttlSeconds: 600
    onPayload: function(text) {
      root.matches = CsModel.parseMatches(text)
    }
  }

  property CachedFetch players: CachedFetch {
    id: players
    name: "cs-player-stats"
    url: "https://api.csapi.de/players/stats"
    ttlSeconds: 3600
    onPayload: function(text) {
      var parsed = CsModel.parsePlayerStats(text)
      if (parsed.length > 0) root.playerRows = parsed
    }
  }

  Component.onCompleted: {
    root.events = CsModel.seedCalendar()
    root.refresh(false)
  }
}
