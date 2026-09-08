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
  property var highlightTeams: []
  readonly property string title: "Counter-Strike"

  property var events: []
  property var teamRows: []
  property var playerRows: []
  property var matches: []

  readonly property int currentIndex: SportsModel.currentEventIndex(events, now)
  readonly property var event: currentIndex >= 0 ? events[currentIndex] : null
  readonly property var upcoming: SportsModel.upcomingEvents(events, currentIndex, 3)
  readonly property var weekend: SportsModel.weekendState(event, now, "CS")
  readonly property var liveMatches: CsModel.liveMatches(matches, now)
  readonly property var liveSession: {
    if (liveMatches.length === 0) return null
    var first = liveMatches[0]
    return {
      key: "live", short: "LIVE", name: first.event || "Live match", group: "Match",
      startAt: now, endAt: now + 3 * SportsTime.HOUR, dateOnly: false
    }
  }
  readonly property var teamStandings: SportsModel.standingsWithFavorites(teamRows, 5, highlightTeams && highlightTeams.length > 0 ? highlightTeams : (highlightTeam ? [highlightTeam] : []))
  readonly property var playerStandings: SportsModel.standingsWithPin(playerRows, 5, highlightPlayer)
  readonly property var recent: matches.slice(0, 8)
  readonly property bool offSeason: events.length > 0 && currentIndex < 0
  readonly property bool loaded: events.length > 0 || teamRows.length > 0
  readonly property bool stale: rankings.isStale
  readonly property bool failed: !loaded && rankings.status === "empty"
  readonly property double lastUpdatedAt: Math.max(rankings.lastSuccessAt, results.lastSuccessAt, players.lastSuccessAt)

  function refresh(force) {
    rankings.fetch(force)
    results.fetch(force)
    players.fetch(force)
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
