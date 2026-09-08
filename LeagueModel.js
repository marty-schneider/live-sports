.pragma library

.import "SportsTime.js" as SportsTime
.import "SportsModel.js" as SportsModel

function competitor(list, side) {
  var rows = SportsModel.arrayOf(list)
  for (var i = 0; i < rows.length; i++) {
    if (SportsModel.str(rows[i].homeAway) === side) return rows[i]
  }
  return rows[0] || null
}

function teamBlob(row) {
  var team = row && row.team && typeof row.team === "object" ? row.team : {}
  return {
    id: SportsModel.int(team.id || (row && row.id), 0),
    name: SportsModel.str(team.displayName || team.name || team.abbreviation),
    score: SportsModel.int(row && row.score, 0),
    rank: 0
  }
}

function parseEspnScoreboard(raw, meta) {
  var data = SportsModel.safeParse(raw)
  var rows = SportsModel.arrayOf(data && data.events)
  var matches = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var comp = SportsModel.arrayOf(row.competitions)[0] || {}
    var status = (row.status && row.status.type) || (comp.status && comp.status.type) || {}
    var state = SportsModel.str(status.state)
    var startAt = SportsTime.parseIso(row.date || comp.date)
    var timeValid = comp.timeValid !== false && SportsTime.isInstant(startAt)
    var home = teamBlob(competitor(comp.competitors, "home"))
    var away = teamBlob(competitor(comp.competitors, "away"))
    var venue = comp.venue && typeof comp.venue === "object" ? SportsModel.str(comp.venue.fullName) : ""
    var finished = state === "post" || status.completed === true
    var live = state === "in"
    var winnerName = ""
    if (finished) {
      if (home.score > away.score) winnerName = home.name
      else if (away.score > home.score) winnerName = away.name
    }
    matches.push({
      id: SportsModel.str(row.id || i),
      event: SportsModel.str(meta.title),
      series: SportsModel.str(meta.title),
      date: SportsTime.isInstant(startAt) ? new Date(startAt).toISOString().slice(0, 10) : "",
      startAt: startAt,
      dateOnly: !timeValid,
      bestOf: 0,
      team1: away,
      team2: home,
      maps: [],
      winnerName: winnerName,
      finished: finished,
      live: live,
      venue: venue,
      name: SportsModel.str(row.name || row.shortName) || (away.name && home.name ? away.name + " at " + home.name : "")
    })
  }
  return matches
}

function matchToEvent(match, meta) {
  if (!match || !SportsTime.isInstant(match.startAt)) return null
  var duration = (meta.durationMin || 180) * SportsTime.MINUTE
  var sessions = []
  if (!match.dateOnly) {
    sessions.push(SportsModel.makeSession({
      key: "kick",
      short: SportsModel.str(meta.short),
      name: match.name,
      group: "Match",
      durationMin: meta.durationMin || 180
    }, match.startAt, match.startAt + duration, false))
  }
  return {
    id: SportsModel.str(meta.id) + "-" + match.id,
    sport: SportsModel.str(meta.id),
    name: match.name,
    series: SportsModel.str(meta.title),
    short: SportsModel.str(meta.short),
    venue: match.venue || "",
    locality: match.venue || "",
    country: "",
    continent: "",
    startAt: match.startAt,
    endAt: match.startAt + duration,
    weekendStartAt: match.startAt,
    weekendEndAt: match.startAt + duration,
    sessions: sessions,
    dateOnly: match.dateOnly === true,
    team1Name: SportsModel.str(match.team1 && match.team1.name),
    team2Name: SportsModel.str(match.team2 && match.team2.name),
    round: 0,
    season: ""
  }
}

function matchKey(match) {
  var a = SportsModel.str(match && match.team1 && match.team1.name).toLowerCase()
  var b = SportsModel.str(match && match.team2 && match.team2.name).toLowerCase()
  var pair = a < b ? a + "|" + b : b + "|" + a
  return SportsModel.str(match && match.date) + "|" + pair
}

function mergeMatchLists(primary, extra) {
  var seen = {}
  var out = []
  var lists = [primary, extra]
  for (var l = 0; l < lists.length; l++) {
    var rows = SportsModel.arrayOf(lists[l])
    for (var i = 0; i < rows.length; i++) {
      var m = rows[i]
      if (!m) continue
      var key = matchKey(m)
      if (seen[key]) continue
      seen[key] = true
      out.push(m)
    }
  }
  return out
}

function splitMatches(matches, nowMs) {
  var live = []
  var upcoming = []
  var recent = []
  var list = SportsModel.arrayOf(matches)
  for (var i = 0; i < list.length; i++) {
    var m = list[i]
    if (m.live) live.push(m)
    else if (m.finished) recent.push(m)
    else upcoming.push(m)
  }
  upcoming.sort(function(a, b) { return (a.startAt || 0) - (b.startAt || 0) })
  recent.sort(function(a, b) { return (b.startAt || 0) - (a.startAt || 0) })
  return { live: live, upcoming: upcoming, recent: recent }
}

function eventsFromMatches(split, meta, nowMs) {
  var out = []
  var source = split.live.concat(split.upcoming)
  for (var i = 0; i < source.length; i++) {
    var ev = matchToEvent(source[i], meta)
    if (ev) out.push(ev)
  }
  out.sort(function(a, b) { return a.startAt - b.startAt })
  return out
}

function statValue(stats, names) {
  var rows = SportsModel.arrayOf(stats)
  for (var n = 0; n < names.length; n++) {
    var want = names[n]
    for (var i = 0; i < rows.length; i++) {
      if (SportsModel.str(rows[i].name) === want || SportsModel.str(rows[i].abbreviation) === want)
        return rows[i]
    }
  }
  return null
}

function collectStandings(node, out) {
  if (!node || typeof node !== "object") return
  var kids = SportsModel.arrayOf(node.children)
  for (var i = 0; i < kids.length; i++) collectStandings(kids[i], out)
  var entries = SportsModel.arrayOf(node.standings && node.standings.entries)
  for (var e = 0; e < entries.length; e++) {
    var row = entries[e]
    if (!row) continue
    var team = row.team && typeof row.team === "object" ? row.team : {}
    var wins = statValue(row.stats, ["wins", "W"])
    var losses = statValue(row.stats, ["losses", "L"])
    var ties = statValue(row.stats, ["ties", "D", "OTL"])
    var points = statValue(row.stats, ["points", "PTS", "P"])
    var overall = statValue(row.stats, ["overall"])
    var name = SportsModel.str(team.displayName || team.name)
    var pts = points ? SportsModel.num(points.value, SportsModel.num(points.displayValue, 0)) : SportsModel.num(wins && wins.value, 0)
    var record = ""
    if (overall && overall.displayValue) record = SportsModel.str(overall.displayValue)
    else if (wins && losses && ties) record = SportsModel.str(wins.displayValue) + "-" + SportsModel.str(ties.displayValue) + "-" + SportsModel.str(losses.displayValue)
    else if (wins && losses) record = SportsModel.str(wins.displayValue) + "-" + SportsModel.str(losses.displayValue)
    out.push({
      id: SportsModel.int(team.id, out.length + 1),
      position: out.length + 1,
      name: name,
      code: SportsModel.str(team.abbreviation).slice(0, 4),
      teamName: name,
      points: pts,
      note: record
    })
  }
}

function parseEspnStandings(raw) {
  var data = SportsModel.safeParse(raw)
  var out = []
  collectStandings(data, out)
  out.sort(function(a, b) { return b.points - a.points })
  for (var i = 0; i < out.length; i++) out[i].position = i + 1
  return out
}

function parseSportsDbTimestamp(row) {
  var ts = SportsModel.str(row && row.strTimestamp)
  if (ts) {
    if (/Z$|[+-]\d{2}:?\d{2}$/.test(ts) === false) ts += "Z"
    var at = SportsTime.parseIso(ts)
    if (SportsTime.isInstant(at)) return { at: at, dateOnly: false }
  }
  var day = SportsModel.str(row && row.dateEvent)
  if (/^\d{4}-\d{2}-\d{2}$/.test(day))
    return { at: SportsTime.parseIso(day + "T00:00:00Z"), dateOnly: true }
  return { at: null, dateOnly: true }
}

function parseSportsDbEvents(raw, meta) {
  var data = SportsModel.safeParse(raw)
  var rows = SportsModel.arrayOf(data && data.events)
  var matches = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var stamp = parseSportsDbTimestamp(row)
    var home = SportsModel.str(row.strHomeTeam)
    var away = SportsModel.str(row.strAwayTeam)
    var hs = SportsModel.int(row.intHomeScore, 0)
    var as = SportsModel.int(row.intAwayScore, 0)
    var finished = row.intHomeScore !== null && row.intHomeScore !== undefined && row.intHomeScore !== ""
    matches.push({
      id: SportsModel.str(row.idEvent || i),
      event: SportsModel.str(meta.title),
      series: SportsModel.str(meta.title),
      date: SportsModel.str(row.dateEvent),
      startAt: stamp.at,
      dateOnly: stamp.dateOnly,
      bestOf: 0,
      team1: { id: SportsModel.int(row.idAwayTeam, 0), name: away, score: as, rank: 0 },
      team2: { id: SportsModel.int(row.idHomeTeam, 0), name: home, score: hs, rank: 0 },
      maps: [],
      winnerName: finished ? (hs > as ? home : as > hs ? away : "") : "",
      finished: finished,
      live: SportsModel.str(row.strStatus).toLowerCase() === "in play",
      venue: SportsModel.str(row.strVenue),
      name: SportsModel.str(row.strEvent) || (away && home ? away + " at " + home : "")
    })
  }
  return matches
}

if (typeof module !== "undefined") {
  module.exports = {
    parseEspnScoreboard: parseEspnScoreboard,
    parseEspnStandings: parseEspnStandings,
    parseSportsDbEvents: parseSportsDbEvents,
    parseSportsDbTimestamp: parseSportsDbTimestamp,
    matchToEvent: matchToEvent,
    matchKey: matchKey,
    mergeMatchLists: mergeMatchLists,
    splitMatches: splitMatches,
    eventsFromMatches: eventsFromMatches
  }
}
