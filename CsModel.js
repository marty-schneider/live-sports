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

// Remaining 2026 S-tier events the user asked for. Times are event windows;
// match-level clocks come from live results when available.
var SEED_EVENTS = [
  { id: "blast-open-fall-2026", name: "BLAST Open Fall 2026", series: "BLAST", locality: "Porto", country: "Portugal", start: "2026-08-26T10:00:00Z", end: "2026-09-06T20:00:00Z" },
  { id: "epl-s24", name: "ESL Pro League Season 24", series: "ESL Pro League", locality: "Katowice", country: "Poland", start: "2026-10-03T10:00:00Z", end: "2026-10-11T20:00:00Z" },
  { id: "iem-beijing-2026", name: "IEM Beijing 2026", series: "IEM", locality: "Beijing", country: "China", start: "2026-11-02T04:00:00Z", end: "2026-11-08T14:00:00Z" },
  { id: "blast-rivals-fall-2026", name: "BLAST Rivals Fall 2026", series: "BLAST", locality: "Hong Kong", country: "Hong Kong", start: "2026-11-09T04:00:00Z", end: "2026-11-15T14:00:00Z" },
  { id: "pgl-singapore-major-2026", name: "PGL Singapore Major 2026", series: "Major", locality: "Singapore", country: "Singapore", start: "2026-11-25T04:00:00Z", end: "2026-12-13T16:00:00Z" }
]

function seedEvent(row) {
  var startAt = SportsTime.parseIso(row.start)
  var endAt = SportsTime.parseIso(row.end)
  if (!SportsTime.isInstant(startAt) || !SportsTime.isInstant(endAt)) return null
  var sessions = [
    SportsModel.makeSession({ key: "open", short: "START", name: "Event start", group: "Event", durationMin: 60 }, startAt, startAt + SportsTime.HOUR, false),
    SportsModel.makeSession({ key: "final", short: "FINAL", name: "Grand final", group: "Match", durationMin: 180 }, endAt - 3 * SportsTime.HOUR, endAt, false)
  ]
  return {
    id: row.id,
    sport: "cs",
    name: row.name,
    series: row.series,
    venue: row.series,
    locality: row.locality,
    country: row.country,
    continent: "",
    startAt: startAt,
    endAt: endAt,
    weekendStartAt: startAt,
    weekendEndAt: endAt,
    sessions: sessions,
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
    var startAt = SportsTime.parseIso(SportsModel.str(row.date) + "T16:00:00Z")
    out.push({
      id: SportsModel.int(row.id, i),
      event: eventName,
      series: seriesOf(eventName),
      startAt: startAt,
      bestOf: SportsModel.int(row.best_of, 3),
      team1: { id: SportsModel.int(t1.id), name: SportsModel.str(t1.name), score: SportsModel.int(t1.score, 0), rank: SportsModel.int(t1.rank) },
      team2: { id: SportsModel.int(t2.id), name: SportsModel.str(t2.name), score: SportsModel.int(t2.score, 0), rank: SportsModel.int(t2.rank) },
      maps: SportsModel.arrayOf(row.maps),
      winnerName: row.winner && row.winner.name ? SportsModel.str(row.winner.name) : "",
      finished: !!(row.winner && row.winner.name)
    })
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
    SEED_EVENTS: SEED_EVENTS,
    seedCalendar: seedCalendar,
    parseRankings: parseRankings,
    parsePlayerStats: parsePlayerStats,
    parseMatches: parseMatches,
    parsePandaScoreRunning: parsePandaScoreRunning
  }
}
