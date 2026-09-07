import QtQuick
import "SportsTime.js" as SportsTime
import "SportsModel.js" as SportsModel
import "SumoModel.js" as SumoModel

QtObject {
  id: root

  property double now: Date.now()
  property int refreshMinutes: 15
  property string highlightPlayer: ""
  property string highlightTeam: ""

  property var events: []
  property var rikishi: []
  property var heyaRows: []
  property var torikumi: []

  readonly property string bashoId: {
    var d = new Date(now)
    var year = d.getUTCFullYear()
    var month = d.getUTCMonth() + 1
    var months = [1, 3, 5, 7, 9, 11]
    var pick = 1
    for (var i = 0; i < months.length; i++) {
      if (month <= months[i]) { pick = months[i]; break }
      pick = months[i]
    }
    if (month > 11) return SumoModel.bashoId(year + 1, 1)
    return SumoModel.bashoId(year, pick)
  }

  readonly property int currentIndex: SportsModel.currentEventIndex(events, now)
  readonly property var event: currentIndex >= 0 ? events[currentIndex] : null
  readonly property var upcoming: SportsModel.upcomingEvents(events, currentIndex, 3)
  readonly property var weekend: SportsModel.weekendState(event, now, "SUMO")
  readonly property var liveSession: event ? SportsModel.liveSession(event, now) : null
  readonly property var playerStandings: SportsModel.standingsWithPin(rikishi, 5, highlightPlayer)
  readonly property var teamStandings: SportsModel.standingsWithPin(heyaRows, 5, highlightTeam)
  readonly property var recent: []
  readonly property bool offSeason: events.length > 0 && currentIndex < 0
  readonly property bool loaded: events.length > 0
  readonly property bool stale: basho.isStale || banzuke.isStale
  readonly property bool failed: !loaded && basho.status === "empty"
  readonly property double lastUpdatedAt: Math.max(basho.lastSuccessAt, banzuke.lastSuccessAt)

  readonly property int liveDay: {
    if (!event || !event.sessions) return 1
    for (var i = 0; i < event.sessions.length; i++) {
      var s = event.sessions[i]
      if (now < s.endAt + SportsTime.HOUR) return i + 1
    }
    return 15
  }

  function refresh(force) {
    basho.fetch(force)
    nextBasho.fetch(force)
    banzuke.fetch(force)
    bouts.fetch(force)
  }

  function absorbBasho(text, id) {
    var parsed = SumoModel.parseBasho(text, id)
    if (!parsed) return
    var next = []
    var seen = false
    for (var i = 0; i < events.length; i++) {
      if (events[i].id === parsed.id) { next.push(parsed); seen = true }
      else next.push(events[i])
    }
    if (!seen) next.push(parsed)
    next.sort(function(a, b) { return a.startAt - b.startAt })
    root.events = next
  }

  property CachedFetch basho: CachedFetch {
    id: basho
    name: "sumo-basho-" + root.bashoId
    url: "https://sumo-api.com/api/basho/" + root.bashoId
    ttlSeconds: 6 * 3600
    onPayload: function(text) { root.absorbBasho(text, root.bashoId) }
  }

  readonly property string nextBashoId: {
    var d = new Date(now)
    var year = d.getUTCFullYear()
    var month = SportsModel.int(root.bashoId.slice(4, 6), 9)
    if (month >= 11) return SumoModel.bashoId(year + 1, 1)
    return SumoModel.bashoId(year, month + 2)
  }

  property CachedFetch nextBasho: CachedFetch {
    id: nextBasho
    name: "sumo-basho-" + root.nextBashoId
    url: "https://sumo-api.com/api/basho/" + root.nextBashoId
    ttlSeconds: 12 * 3600
    onPayload: function(text) { root.absorbBasho(text, root.nextBashoId) }
  }

  property CachedFetch banzuke: CachedFetch {
    id: banzuke
    name: "sumo-banzuke-" + root.bashoId
    url: "https://sumo-api.com/api/basho/" + root.bashoId + "/banzuke/Makuuchi"
    ttlSeconds: Math.max(300, root.refreshMinutes * 60)
    onPayload: function(text) {
      var parsed = SumoModel.parseBanzuke(text)
      if (parsed.length > 0) {
        root.rikishi = parsed
        root.heyaRows = SumoModel.heyaStandings(parsed)
      }
    }
  }

  property CachedFetch bouts: CachedFetch {
    id: bouts
    name: "sumo-torikumi-" + root.bashoId + "-" + root.liveDay
    url: "https://sumo-api.com/api/basho/" + root.bashoId + "/torikumi/Makuuchi/" + root.liveDay
    ttlSeconds: 180
    onPayload: function(text) {
      root.torikumi = SumoModel.parseTorikumi(text)
    }
  }

  Component.onCompleted: refresh(false)
}
