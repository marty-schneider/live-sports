.pragma library

.import "SportsTime.js" as SportsTime
.import "SportsModel.js" as SportsModel

// 2026 GT World Challenge weekends from the published SRO calendars.
// Only Zandvoort has a sourced UTC timetable. Everything else is a date range.
var SEED_EVENTS = [
  { id: "aus-phillip-island", name: "Phillip Island", short: "PHIL", series: "GT World Challenge Australia", continent: "Australia", locality: "Phillip Island", country: "Australia", cup: "sprint", start: "2026-03-27", end: "2026-03-29" },
  { id: "ame-sonoma", name: "Sonoma Raceway", short: "SONO", series: "GT World Challenge America", continent: "America", locality: "Sonoma", country: "United States", cup: "sprint", start: "2026-03-27", end: "2026-03-29" },
  { id: "asia-sepang", name: "Sepang", short: "SEPA", series: "GT World Challenge Asia", continent: "Asia", locality: "Sepang", country: "Malaysia", cup: "sprint", start: "2026-04-04", end: "2026-04-05" },
  { id: "eur-paul-ricard", name: "Paul Ricard", short: "RICARD", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Le Castellet", country: "France", cup: "endurance", start: "2026-04-11", end: "2026-04-12" },
  { id: "ame-cota", name: "Circuit of The Americas", short: "COTA", series: "GT World Challenge America", continent: "America", locality: "Austin", country: "United States", cup: "sprint", start: "2026-04-24", end: "2026-04-26" },
  { id: "eur-brands-hatch", name: "Brands Hatch", short: "BRANDS", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Kent", country: "United Kingdom", cup: "sprint", start: "2026-05-02", end: "2026-05-03" },
  { id: "asia-mandalika", name: "Mandalika", short: "MAND", series: "GT World Challenge Asia", continent: "Asia", locality: "Lombok", country: "Indonesia", cup: "sprint", start: "2026-05-02", end: "2026-05-03" },
  { id: "aus-the-bend", name: "The Bend", short: "BEND", series: "GT World Challenge Australia", continent: "Australia", locality: "Tailem Bend", country: "Australia", cup: "sprint", start: "2026-05-08", end: "2026-05-10" },
  { id: "ame-sebring", name: "Sebring", short: "SEBR", series: "GT World Challenge America", continent: "America", locality: "Sebring", country: "United States", cup: "sprint", start: "2026-05-15", end: "2026-05-17" },
  { id: "eur-monza", name: "Monza", short: "MONZA", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Monza", country: "Italy", cup: "endurance", start: "2026-05-30", end: "2026-05-31" },
  { id: "asia-shanghai", name: "Shanghai", short: "SHANG", series: "GT World Challenge Asia", continent: "Asia", locality: "Shanghai", country: "China", cup: "sprint", start: "2026-06-05", end: "2026-06-06" },
  { id: "aus-queensland", name: "Queensland Raceway", short: "QLD", series: "GT World Challenge Australia", continent: "Australia", locality: "Ipswich", country: "Australia", cup: "sprint", start: "2026-06-12", end: "2026-06-14" },
  { id: "eur-spa-24h", name: "CrowdStrike 24 Hours of Spa", short: "SPA", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Spa-Francorchamps", country: "Belgium", cup: "endurance", start: "2026-06-25", end: "2026-06-28" },
  { id: "asia-fuji", name: "Fuji", short: "FUJI", series: "GT World Challenge Asia", continent: "Asia", locality: "Oyama", country: "Japan", cup: "sprint", start: "2026-07-11", end: "2026-07-12" },
  { id: "eur-misano", name: "Misano", short: "MISA", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Misano", country: "Italy", cup: "sprint", start: "2026-07-18", end: "2026-07-19" },
  { id: "aus-hidden-valley", name: "Hidden Valley", short: "HV", series: "GT World Challenge Australia", continent: "Australia", locality: "Darwin", country: "Australia", cup: "sprint", start: "2026-07-24", end: "2026-07-26" },
  { id: "eur-magny-cours", name: "Magny-Cours", short: "MAGNY", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Magny-Cours", country: "France", cup: "sprint", start: "2026-07-31", end: "2026-08-02" },
  { id: "asia-okayama", name: "Okayama", short: "OKAY", series: "GT World Challenge Asia", continent: "Asia", locality: "Okayama", country: "Japan", cup: "sprint", start: "2026-08-28", end: "2026-08-30" },
  { id: "eur-nurburgring", name: "Nürburgring", short: "NURB", series: "GT World Challenge Europe Endurance", continent: "Europe", locality: "Nürburg", country: "Germany", cup: "endurance", start: "2026-08-28", end: "2026-08-30" },
  { id: "ame-road-america", name: "Road America", short: "ROAD", series: "GT World Challenge America", continent: "America", locality: "Elkhart Lake", country: "United States", cup: "sprint", start: "2026-08-28", end: "2026-08-30" },
  { id: "aus-sydney", name: "Sydney Motorsport Park", short: "SYD", series: "GT World Challenge Australia", continent: "Australia", locality: "Eastern Creek", country: "Australia", cup: "sprint", start: "2026-09-18", end: "2026-09-20" },
  { id: "eur-zandvoort", name: "Zandvoort", short: "ZAND", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Zandvoort", country: "Netherlands", cup: "sprint", start: "2026-09-18", end: "2026-09-20",
    sessions: [
      { key: "fp1", short: "FP1", name: "Practice 1", group: "Practice", at: "2026-09-18T07:00:00Z", durationMin: 90 },
      { key: "fp2", short: "FP2", name: "Practice 2", group: "Practice", at: "2026-09-18T11:50:00Z", durationMin: 90 },
      { key: "q1", short: "Q1", name: "Qualifying 1", group: "Qualifying", at: "2026-09-19T07:50:00Z", durationMin: 20 },
      { key: "r1", short: "R1", name: "Race 1", group: "Race", at: "2026-09-19T12:45:00Z", durationMin: 60 },
      { key: "q2", short: "Q2", name: "Qualifying 2", group: "Qualifying", at: "2026-09-20T08:35:00Z", durationMin: 20 },
      { key: "r2", short: "R2", name: "Race 2", group: "Race", at: "2026-09-20T12:15:00Z", durationMin: 60 }
    ]
  },
  { id: "ame-barber", name: "Barber Motorsports Park", short: "BARB", series: "GT World Challenge America", continent: "America", locality: "Birmingham", country: "United States", cup: "sprint", start: "2026-09-25", end: "2026-09-27" },
  { id: "eur-barcelona", name: "Barcelona", short: "BCN", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Montmeló", country: "Spain", cup: "sprint", start: "2026-10-02", end: "2026-10-04" },
  { id: "asia-beijing", name: "Beijing Street Circuit", short: "BEIJ", series: "GT World Challenge Asia", continent: "Asia", locality: "Beijing", country: "China", cup: "sprint", start: "2026-10-02", end: "2026-10-04" },
  { id: "ame-indianapolis", name: "Indianapolis", short: "INDY", series: "GT World Challenge America", continent: "America", locality: "Indianapolis", country: "United States", cup: "endurance", start: "2026-10-08", end: "2026-10-10" },
  { id: "eur-portimao", name: "Portimão", short: "PORT", series: "GT World Challenge Europe Sprint", continent: "Europe", locality: "Portimão", country: "Portugal", cup: "sprint", start: "2026-10-16", end: "2026-10-18" },
  { id: "aus-adelaide", name: "Adelaide Street Circuit", short: "ADEL", series: "GT World Challenge Australia", continent: "Australia", locality: "Adelaide", country: "Australia", cup: "sprint", start: "2026-11-26", end: "2026-11-29" }
]

function parseDay(value) {
  var s = String(value || "")
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return SportsTime.parseIso(s + "T00:00:00Z")
  return SportsTime.parseIso(s)
}

function seedEvent(row) {
  var startAt = parseDay(row.start)
  var endAt = parseDay(row.end)
  if (!SportsTime.isInstant(startAt) || !SportsTime.isInstant(endAt)) return null
  var sessions = []
  if (Array.isArray(row.sessions)) {
    for (var i = 0; i < row.sessions.length; i++) {
      var s = row.sessions[i]
      var at = SportsTime.parseIso(s.at)
      if (!SportsTime.isInstant(at)) continue
      sessions.push(SportsModel.makeSession(s, at, at + (s.durationMin || 60) * SportsTime.MINUTE, false))
    }
  }
  return {
    id: row.id,
    sport: "gt",
    name: row.name,
    series: row.series,
    short: row.short || row.name.slice(0, 4).toUpperCase(),
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
    dateOnly: sessions.length === 0,
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
