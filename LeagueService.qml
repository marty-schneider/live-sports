import QtQuick
import "SportsTime.js" as SportsTime
import "SportsModel.js" as SportsModel
import "LeagueModel.js" as LeagueModel

QtObject {
  id: root

  property double now: Date.now()
  property int refreshMinutes: 15
  property string highlightPlayer: ""
  property string highlightTeam: ""

  property string sportId: ""
  property string title: ""
  property string shortName: ""
  property int durationMin: 180
  property string scoreboardUrl: ""
  property string standingsUrl: ""
  property string nextUrl: ""

  property var matches: []
  property var extraUpcoming: []
  property var teamRows: []
  property var playerRows: []

  readonly property var meta: ({
    id: sportId,
    title: title,
    short: shortName,
    durationMin: durationMin
  })

  readonly property var allMatches: LeagueModel.mergeMatchLists(matches, extraUpcoming)
  readonly property var split: LeagueModel.splitMatches(allMatches, now)
  readonly property var liveMatches: split.live
  readonly property var recent: split.recent.slice(0, 8)
  readonly property var events: LeagueModel.eventsFromMatches(split, meta, now)
  readonly property int currentIndex: SportsModel.currentEventIndex(events, now)
  readonly property var event: currentIndex >= 0 ? events[currentIndex] : null
  readonly property var upcoming: SportsModel.upcomingEvents(events, currentIndex, 3)
  readonly property var weekend: SportsModel.weekendState(event, now, shortName)
  readonly property var liveSession: {
    if (liveMatches.length > 0) {
      var first = liveMatches[0]
      return {
        key: "live",
        short: shortName,
        name: first.name,
        group: "Match",
        startAt: first.startAt || now,
        endAt: (first.startAt || now) + (durationMin * SportsTime.MINUTE),
        dateOnly: first.dateOnly === true
      }
    }
    return event ? SportsModel.liveSession(event, now) : null
  }
  readonly property var playerStandings: SportsModel.standingsWithPin(playerRows, 5, highlightPlayer)
  readonly property var teamStandings: SportsModel.standingsWithPin(teamRows, 5, highlightTeam)
  readonly property bool waitingOnNext: nextUrl !== "" && (upcomingFetch.status === "idle" || upcomingFetch.status === "loading")
  readonly property bool offSeason: loaded && events.length === 0 && !waitingOnNext
  readonly property bool loaded: matches.length > 0 || teamRows.length > 0 || extraUpcoming.length > 0
  readonly property bool stale: board.isStale || table.isStale
  readonly property bool failed: !loaded && (board.status === "empty" || table.status === "empty")
  readonly property double lastUpdatedAt: Math.max(board.lastSuccessAt, table.lastSuccessAt, upcomingFetch.lastSuccessAt)

  function refresh(force) {
    board.fetch(force)
    table.fetch(force)
    if (nextUrl !== "") upcomingFetch.fetch(force)
  }

  property CachedFetch board: CachedFetch {
    id: board
    name: root.sportId + "-board"
    url: root.scoreboardUrl
    ttlSeconds: 120
    onPayload: function(text) {
      root.matches = LeagueModel.parseEspnScoreboard(text, root.meta)
    }
  }

  property CachedFetch table: CachedFetch {
    id: table
    name: root.sportId + "-table"
    url: root.standingsUrl
    ttlSeconds: Math.max(300, root.refreshMinutes * 60)
    onPayload: function(text) {
      var parsed = LeagueModel.parseEspnStandings(text)
      if (parsed.length > 0) root.teamRows = parsed
    }
  }

  property CachedFetch upcomingFetch: CachedFetch {
    id: upcomingFetch
    name: root.sportId + "-next"
    url: root.nextUrl
    ttlSeconds: 1800
    onPayload: function(text) {
      root.extraUpcoming = LeagueModel.parseSportsDbEvents(text, root.meta)
    }
  }

  Component.onCompleted: refresh(false)
}
