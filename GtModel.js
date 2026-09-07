.pragma library

.import "SportsTime.js" as SportsTime
.import "SportsModel.js" as SportsModel

// 2026 GT World Challenge, all SRO continents. Session clocks are UTC
// estimates from published timetables where known; otherwise date-only.
var SEED_EVENTS = [
  { id: "aus-phillip-island", name: "Phillip Island", series: "GT World Challenge Australia", continent: "Australia", locality: "Phillip Island", country: "Australia", cup: "sprint", start: "2026-03-27T01:00:00Z", end: "2026-03-29T08:00:00Z" },
  { id: "ame-sonoma", name: "Sonoma Raceway", series: "GT World Challenge America", continent: "America", locality: "Sonoma", country: "United States", cup: "sprint", start: "2026-03-27T16:00:00Z", end: "2026-03-29T23:00:00Z" },
  { id: "asia-sepang", name: "Sepang", series: "GT World Challenge Asia", continent: "Asia", locality: "Sepang", country: "Malaysia", cup: "sprint", start: "2026-04-04T02:00:00Z", end: "2026-04-05T10:00:00Z" },
  { id: "eur-paul-ricard", name: "Paul Ricard", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Le Castellet", country: "France", cup: "endurance", start: "2026-04-11T07:00:00Z", end: "2026-04-12T16:00:00Z" },
  { id: "ame-cota", name: "Circuit of The Americas", series: "GT World Challenge America", continent: "America", locality: "Austin", country: "United States", cup: "sprint", start: "2026-04-24T14:00:00Z", end: "2026-04-26T22:00:00Z" },
  { id: "eur-brands-hatch", name: "Brands Hatch", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Kent", country: "United Kingdom", cup: "sprint", start: "2026-05-02T08:00:00Z", end: "2026-05-03T16:00:00Z" },
  { id: "asia-mandalika", name: "Mandalika", series: "GT World Challenge Asia", continent: "Asia", locality: "Lombok", country: "Indonesia", cup: "sprint", start: "2026-05-02T02:00:00Z", end: "2026-05-03T10:00:00Z" },
  { id: "aus-the-bend", name: "The Bend", series: "GT World Challenge Australia", continent: "Australia", locality: "Tailem Bend", country: "Australia", cup: "sprint", start: "2026-05-08T01:00:00Z", end: "2026-05-10T08:00:00Z" },
  { id: "ame-sebring", name: "Sebring", series: "GT World Challenge America", continent: "America", locality: "Sebring", country: "United States", cup: "sprint", start: "2026-05-15T14:00:00Z", end: "2026-05-17T22:00:00Z" },
  { id: "eur-monza", name: "Monza", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Monza", country: "Italy", cup: "endurance", start: "2026-05-30T07:00:00Z", end: "2026-05-31T16:00:00Z" },
  { id: "asia-shanghai", name: "Shanghai", series: "GT World Challenge Asia", continent: "Asia", locality: "Shanghai", country: "China", cup: "sprint", start: "2026-06-05T02:00:00Z", end: "2026-06-06T10:00:00Z" },
  { id: "aus-queensland", name: "Queensland Raceway", series: "GT World Challenge Australia", continent: "Australia", locality: "Ipswich", country: "Australia", cup: "sprint", start: "2026-06-12T01:00:00Z", end: "2026-06-14T08:00:00Z" },
  { id: "eur-spa-24h", name: "CrowdStrike 24 Hours of Spa", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Spa-Francorchamps", country: "Belgium", cup: "endurance", start: "2026-06-25T07:00:00Z", end: "2026-06-28T16:00:00Z" },
  { id: "asia-fuji", name: "Fuji", series: "GT World Challenge Asia", continent: "Asia", locality: "Oyama", country: "Japan", cup: "sprint", start: "2026-07-11T01:00:00Z", end: "2026-07-12T09:00:00Z" },
  { id: "eur-misano", name: "Misano", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Misano", country: "Italy", cup: "sprint", start: "2026-07-18T07:00:00Z", end: "2026-07-19T16:00:00Z" },
  { id: "aus-hidden-valley", name: "Hidden Valley", series: "GT World Challenge Australia", continent: "Australia", locality: "Darwin", country: "Australia", cup: "sprint", start: "2026-07-24T01:00:00Z", end: "2026-07-26T08:00:00Z" },
  { id: "eur-magny-cours", name: "Magny-Cours", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Magny-Cours", country: "France", cup: "sprint", start: "2026-07-31T07:00:00Z", end: "2026-08-02T16:00:00Z" },
  { id: "asia-okayama", name: "Okayama", series: "GT World Challenge Asia", continent: "Asia", locality: "Okayama", country: "Japan", cup: "sprint", start: "2026-08-28T01:00:00Z", end: "2026-08-30T09:00:00Z" },
  { id: "eur-nurburgring", name: "Nürburgring", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Nürburg", country: "Germany", cup: "endurance", start: "2026-08-28T07:00:00Z", end: "2026-08-30T16:00:00Z" },
  { id: "ame-road-america", name: "Road America", series: "GT World Challenge America", continent: "America", locality: "Elkhart Lake", country: "United States", cup: "sprint", start: "2026-08-28T14:00:00Z", end: "2026-08-30T22:00:00Z" },
  { id: "aus-sydney", name: "Sydney Motorsport Park", series: "GT World Challenge Australia", continent: "Australia", locality: "Eastern Creek", country: "Australia", cup: "sprint", start: "2026-09-18T01:00:00Z", end: "2026-09-20T08:00:00Z" },
  { id: "eur-zandvoort", name: "Zandvoort", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Zandvoort", country: "Netherlands", cup: "sprint", start: "2026-09-18T07:00:00Z", end: "2026-09-20T16:00:00Z",
    sessions: [
      { key: "fp1", short: "FP1", name: "Practice 1", group: "Practice", at: "2026-09-18T07:00:00Z", durationMin: 90 },
      { key: "fp2", short: "FP2", name: "Practice 2", group: "Practice", at: "2026-09-18T11:50:00Z", durationMin: 90 },
      { key: "q1", short: "Q1", name: "Qualifying 1", group: "Qualifying", at: "2026-09-19T07:50:00Z", durationMin: 20 },
      { key: "r1", short: "R1", name: "Race 1", group: "Race", at: "2026-09-19T12:45:00Z", durationMin: 60 },
      { key: "q2", short: "Q2", name: "Qualifying 2", group: "Qualifying", at: "2026-09-20T08:35:00Z", durationMin: 20 },
      { key: "r2", short: "R2", name: "Race 2", group: "Race", at: "2026-09-20T12:15:00Z", durationMin: 60 }
    ]
  },
  { id: "ame-barber", name: "Barber Motorsports Park", series: "GT World Challenge America", continent: "America", locality: "Birmingham", country: "United States", cup: "sprint", start: "2026-09-25T14:00:00Z", end: "2026-09-27T22:00:00Z" },
  { id: "eur-barcelona", name: "Barcelona", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Montmeló", country: "Spain", cup: "sprint", start: "2026-10-02T07:00:00Z", end: "2026-10-04T16:00:00Z" },
  { id: "asia-beijing", name: "Beijing Street Circuit", series: "GT World Challenge Asia", continent: "Asia", locality: "Beijing", country: "China", cup: "sprint", start: "2026-10-02T02:00:00Z", end: "2026-10-04T10:00:00Z" },
  { id: "ame-indianapolis", name: "Indianapolis", series: "GT World Challenge America", continent: "America", locality: "Indianapolis", country: "United States", cup: "endurance", start: "2026-10-08T14:00:00Z", end: "2026-10-10T22:00:00Z" },
  { id: "eur-portimao", name: "Portimão", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Portimão", country: "Portugal", cup: "sprint", start: "2026-10-16T08:00:00Z", end: "2026-10-18T16:00:00Z" },
  { id: "aus-adelaide", name: "Adelaide Street Circuit", series: "GT World Challenge Australia", continent: "Australia", locality: "Adelaide", country: "Australia", cup: "sprint", start: "2026-11-26T01:00:00Z", end: "2026-11-29T08:00:00Z" }
]

function defaultSessions(row, startAt, endAt) {
  if (row.cup === "endurance") {
    return [
      SportsModel.makeSession({ key: "fp1", short: "FP1", name: "Practice 1", group: "Practice", durationMin: 90 }, startAt, startAt + 90 * SportsTime.MINUTE, false),
      SportsModel.makeSession({ key: "quali", short: "QUAL", name: "Qualifying", group: "Qualifying", durationMin: 30 }, startAt + SportsTime.DAY, startAt + SportsTime.DAY + 30 * SportsTime.MINUTE, false),
      SportsModel.makeSession({ key: "race", short: "RACE", name: row.id === "eur-spa-24h" ? "24 Hours" : "Race", group: "Race", durationMin: row.id === "eur-spa-24h" ? 1440 : 180 }, endAt - (row.id === "eur-spa-24h" ? 24 : 3) * SportsTime.HOUR, endAt, false)
    ]
  }
  var race1 = startAt + SportsTime.DAY + 5 * SportsTime.HOUR
  var race2 = startAt + 2 * SportsTime.DAY + 5 * SportsTime.HOUR
  return [
    SportsModel.makeSession({ key: "fp1", short: "FP1", name: "Practice 1", group: "Practice", durationMin: 90 }, startAt, startAt + 90 * SportsTime.MINUTE, false),
    SportsModel.makeSession({ key: "q1", short: "Q1", name: "Qualifying 1", group: "Qualifying", durationMin: 20 }, race1 - 4 * SportsTime.HOUR, race1 - 4 * SportsTime.HOUR + 20 * SportsTime.MINUTE, false),
    SportsModel.makeSession({ key: "r1", short: "R1", name: "Race 1", group: "Race", durationMin: 60 }, race1, race1 + SportsTime.HOUR, false),
    SportsModel.makeSession({ key: "q2", short: "Q2", name: "Qualifying 2", group: "Qualifying", durationMin: 20 }, race2 - 4 * SportsTime.HOUR, race2 - 4 * SportsTime.HOUR + 20 * SportsTime.MINUTE, false),
    SportsModel.makeSession({ key: "r2", short: "R2", name: "Race 2", group: "Race", durationMin: 60 }, race2, race2 + SportsTime.HOUR, false)
  ]
}

function seedEvent(row) {
  var startAt = SportsTime.parseIso(row.start)
  var endAt = SportsTime.parseIso(row.end)
  if (!SportsTime.isInstant(startAt) || !SportsTime.isInstant(endAt)) return null
  var sessions
  if (Array.isArray(row.sessions) && row.sessions.length > 0) {
    sessions = []
    for (var i = 0; i < row.sessions.length; i++) {
      var s = row.sessions[i]
      var at = SportsTime.parseIso(s.at)
      if (!SportsTime.isInstant(at)) continue
      sessions.push(SportsModel.makeSession(s, at, at + (s.durationMin || 60) * SportsTime.MINUTE, false))
    }
  } else {
    sessions = defaultSessions(row, startAt, endAt)
  }
  return {
    id: row.id,
    sport: "gt",
    name: row.name,
    series: row.series,
    venue: row.name,
    locality: row.locality,
    country: row.country,
    continent: row.continent,
    cup: row.cup,
    startAt: startAt,
    endAt: endAt,
    weekendStartAt: sessions.length ? sessions[0].startAt : startAt,
    weekendEndAt: sessions.length ? sessions[sessions.length - 1].endAt : endAt,
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
  out.sort(function(a, b) { return a.weekendStartAt - b.weekendStartAt })
  for (var r = 0; r < out.length; r++) out[r].round = r + 1
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    SEED_EVENTS: SEED_EVENTS,
    seedCalendar: seedCalendar,
    seedEvent: seedEvent
  }
}
