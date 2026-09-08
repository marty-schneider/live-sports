.pragma library

.import "SportsTime.js" as SportsTime
.import "SportsModel.js" as SportsModel

// Valve Majors + RMRs, BLAST Open/Premier/Bounty/Rivals, ESL Pro League, IEM.
function isTier1(eventName) {
  var l = SportsModel.str(eventName).toLowerCase()
  if (l === "") return false
  if (/(challenger|academy|\bcct\b|esea|qualifier|qualifying|open qual)/.test(l) && !/\brmr\b/.test(l))
    return false
  if (/\bmajor\b/.test(l) || /\brmr\b/.test(l)) return true
  if (/blast/.test(l) && /(open|premier|bounty|rivals)/.test(l)) return true
  if (/esl pro league/.test(l) || /\bepl\b/.test(l)) return true
  if (/\biem\b/.test(l) || /intel extreme masters/.test(l)) return true
  return false
}

function seriesOf(eventName) {
  var l = SportsModel.str(eventName).toLowerCase()
  if (/\bmajor\b/.test(l) || /\brmr\b/.test(l)) return "Major"
  if (/blast/.test(l)) return "BLAST"
  if (/esl pro league/.test(l) || /\bepl\b/.test(l)) return "ESL Pro League"
  if (/\biem\b/.test(l) || /intel extreme/.test(l)) return "IEM"
  return "Tier 1"
}

function shortOf(eventName, series) {
  var l = SportsModel.str(eventName).toLowerCase()
  if (/\bmajor\b/.test(l)) return "MAJOR"
  if (/rivals/.test(l)) return "RIVALS"
  if (/bounty/.test(l)) return "BOUNTY"
  if (series === "ESL Pro League") return "EPL"
  if (series === "IEM") return "IEM"
  if (series === "BLAST") return "BLAST"
  return SportsModel.str(series).slice(0, 5).toUpperCase() || "CS"
}

// Published event dates only. csapi.de gives match dates, not kickoff times.
var SEED_EVENTS = [
  { id: "blast-open-fall-2026", name: "BLAST Open Fall 2026", series: "BLAST", short: "BLAST", locality: "Porto", country: "Portugal", start: "2026-08-26", end: "2026-09-06" },
  { id: "epl-s24", name: "ESL Pro League Season 24", series: "ESL Pro League", short: "EPL", locality: "Katowice", country: "Poland", start: "2026-10-03", end: "2026-10-11" },
  { id: "iem-beijing-2026", name: "IEM Beijing 2026", series: "IEM", short: "IEM", locality: "Beijing", country: "China", start: "2026-11-02", end: "2026-11-08" },
  { id: "blast-rivals-fall-2026", name: "BLAST Rivals Fall 2026", series: "BLAST", short: "RIVALS", locality: "Hong Kong", country: "Hong Kong", start: "2026-11-09", end: "2026-11-15" },
  { id: "pgl-singapore-major-2026", name: "PGL Singapore Major 2026", series: "Major", short: "MAJOR", locality: "Singapore", country: "Singapore", start: "2026-11-25", end: "2026-12-13" }
]

function parseDay(value) {
  var s = SportsModel.str(value)
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return SportsTime.parseIso(s + "T00:00:00Z")
  return SportsTime.parseIso(s)
}

function seedEvent(row) {
  var startAt = parseDay(row.start)
  var endAt = parseDay(row.end)
  if (!SportsTime.isInstant(startAt) || !SportsTime.isInstant(endAt)) return null
  return {
    id: row.id,
    sport: "cs",
    name: row.name,
    series: row.series,
    short: row.short || shortOf(row.name, row.series),
    venue: row.series,
    locality: row.locality,
    country: row.country,
    continent: "",
    startAt: startAt,
    endAt: endAt,
    weekendStartAt: startAt,
    weekendEndAt: endAt,
    sessions: [],
    dateOnly: true,
    round: 0,
    season: "2026"
  }
}

function seedCalendar() {
  var out = []
  for (var i = 0; i < SEED_EVENTS.length; i++) {
    var ev = seedEvent(SEED_EVENTS[i])
    if (ev) out.push(ev)
  }
  out.sort(function(a, b) { return a.startAt - b.startAt })
  return out
}

function parseRankings(raw) {
  var data = SportsModel.safeParse(raw)
  var rows = SportsModel.arrayOf(data && data.rankings)
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    out.push({
      id: SportsModel.int(row.id, i + 1),
      position: SportsModel.int(row.rank, i + 1),
      name: SportsModel.str(row.name),
      code: SportsModel.str(row.name).slice(0, 3).toUpperCase(),
      teamName: SportsModel.str(row.name),
      points: SportsModel.num(row.points, 0),
      note: SportsModel.int(row.rank_diff, 0) > 0 ? "+" + row.rank_diff : (SportsModel.int(row.rank_diff, 0) < 0 ? String(row.rank_diff) : "")
    })
  }
  return out
}

function parsePlayerStats(raw) {
  var rows = SportsModel.arrayOf(SportsModel.safeParse(raw))
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    out.push({
      id: SportsModel.int(row.id, i + 1),
      position: SportsModel.int(row.rank, i + 1),
      name: SportsModel.str(row.name),
      code: SportsModel.str(row.name).slice(0, 4),
      teamName: "",
      points: SportsModel.num(row.rating, 0),
      rating: SportsModel.num(row.rating, 0),
      adr: SportsModel.num(row.adr, 0)
    })
  }
  return out
}

function utcDateString(ms) {
  if (!SportsTime.isInstant(ms)) return ""
  var d = new Date(ms)
  var m = d.getUTCMonth() + 1
  var day = d.getUTCDate()
  return d.getUTCFullYear() + "-" + (m < 10 ? "0" + m : String(m)) + "-" + (day < 10 ? "0" + day : String(day))
}

function parseMatches(raw) {
  var rows = SportsModel.arrayOf(SportsModel.safeParse(raw))
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var eventName = SportsModel.str(row.event)
    if (!isTier1(eventName)) continue
    var t1 = row.team1 && typeof row.team1 === "object" ? row.team1 : {}
    var t2 = row.team2 && typeof row.team2 === "object" ? row.team2 : {}
    var date = SportsModel.str(row.date)
    var startAt = parseDay(date)
    var finished = !!(row.winner && row.winner.name)
    out.push({
      id: SportsModel.int(row.id, i),
      event: eventName,
      series: seriesOf(eventName),
      date: date,
      startAt: startAt,
      dateOnly: true,
      bestOf: SportsModel.int(row.best_of, 3),
      team1: { id: SportsModel.int(t1.id), name: SportsModel.str(t1.name), score: SportsModel.int(t1.score, 0), rank: SportsModel.int(t1.rank) },
      team2: { id: SportsModel.int(t2.id), name: SportsModel.str(t2.name), score: SportsModel.int(t2.score, 0), rank: SportsModel.int(t2.rank) },
      maps: SportsModel.arrayOf(row.maps),
      winnerName: row.winner && row.winner.name ? SportsModel.str(row.winner.name) : "",
      finished: finished
    })
  }
  return out
}

function liveMatches(matches, nowMs) {
  var today = utcDateString(nowMs)
  var list = SportsModel.arrayOf(matches)
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (list[i].date === today && !list[i].finished) out.push(list[i])
  }
  return out
}

function parsePandaScoreRunning(raw) {
  var rows = SportsModel.arrayOf(SportsModel.safeParse(raw))
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var opponents = SportsModel.arrayOf(row.opponents)
    var a = opponents[0] && opponents[0].opponent ? opponents[0].opponent : {}
    var b = opponents[1] && opponents[1].opponent ? opponents[1].opponent : {}
    var results = SportsModel.arrayOf(row.results)
    out.push({
      position: 1,
      acronym: SportsModel.str(a.acronym || a.name).slice(0, 4).toUpperCase(),
      name: SportsModel.str(a.name),
      teamName: SportsModel.str(a.name),
      gap: results[0] ? String(results[0].score) : "—",
      leaderGap: "",
      pits: 0
    })
    out.push({
      position: 2,
      acronym: SportsModel.str(b.acronym || b.name).slice(0, 4).toUpperCase(),
      name: SportsModel.str(b.name),
      teamName: SportsModel.str(b.name),
      gap: results[1] ? String(results[1].score) : "—",
      leaderGap: "",
      pits: 0
    })
  }
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    isTier1: isTier1,
    seriesOf: seriesOf,
    shortOf: shortOf,
    parseDay: parseDay,
    SEED_EVENTS: SEED_EVENTS,
    seedCalendar: seedCalendar,
    parseRankings: parseRankings,
    parsePlayerStats: parsePlayerStats,
    parseMatches: parseMatches,
    liveMatches: liveMatches,
    utcDateString: utcDateString,
    parsePandaScoreRunning: parsePandaScoreRunning
  }
}
