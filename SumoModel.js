.pragma library

.import "SportsTime.js" as SportsTime
.import "SportsModel.js" as SportsModel

// Grand Sumo honbasho, Makuuchi only. Six odd-month basho.
var BASHO = [
  { month: 1, name: "Hatsu Basho", short: "HATSU", locality: "Tokyo", venue: "Ryogoku Kokugikan" },
  { month: 3, name: "Haru Basho", short: "HARU", locality: "Osaka", venue: "Edion Arena Osaka" },
  { month: 5, name: "Natsu Basho", short: "NATSU", locality: "Tokyo", venue: "Ryogoku Kokugikan" },
  { month: 7, name: "Nagoya Basho", short: "NAGOYA", locality: "Nagoya", venue: "Dolphins Arena" },
  { month: 9, name: "Aki Basho", short: "AKI", locality: "Tokyo", venue: "Ryogoku Kokugikan" },
  { month: 11, name: "Kyushu Basho", short: "KYUSHU", locality: "Fukuoka", venue: "Fukuoka Kokusai Center" }
]

function bashoId(year, month) {
  return String(year) + (month < 10 ? "0" + month : String(month))
}

function bashoMeta(id) {
  var s = SportsModel.str(id)
  var year = SportsModel.int(s.slice(0, 4), 0)
  var month = SportsModel.int(s.slice(4, 6), 0)
  for (var i = 0; i < BASHO.length; i++) {
    if (BASHO[i].month === month)
      return { year: year, month: month, name: BASHO[i].name, short: BASHO[i].short, locality: BASHO[i].locality, venue: BASHO[i].venue, country: "Japan" }
  }
  return { year: year, month: month, name: "Honbasho", short: "SUMO", locality: "Japan", venue: "", country: "Japan" }
}

function nearbyBashoIds(nowMs) {
  var d = new Date(nowMs)
  var year = d.getUTCFullYear()
  var ids = []
  for (var y = year - 1; y <= year + 1; y++) {
    for (var i = 0; i < BASHO.length; i++) ids.push(bashoId(y, BASHO[i].month))
  }
  return ids
}

function parseBasho(raw, id) {
  var data = SportsModel.safeParse(raw)
  if (!data) return null
  var startAt = SportsTime.parseIso(data.startDate)
  var endAt = SportsTime.parseIso(data.endDate)
  if (!SportsTime.isInstant(startAt) || !SportsTime.isInstant(endAt)) return null
  if (new Date(startAt).getUTCFullYear() < 2000) return null
  var meta = bashoMeta(data.date || id)
  var sessions = []
  for (var day = 1; day <= 15; day++) {
    var dayUtc = startAt + (day - 1) * SportsTime.DAY
    sessions.push(SportsModel.makeSession({
      key: "day" + day,
      short: "D" + day,
      name: day === 15 ? "Senshuraku" : "Day " + day,
      group: "Makuuchi",
      durationMin: 1440
    }, dayUtc, dayUtc + SportsTime.DAY, true))
  }
  return {
    id: SportsModel.str(data.date || id),
    sport: "sumo",
    name: meta.name,
    series: "Grand Sumo",
    short: meta.short,
    venue: meta.venue,
    locality: meta.locality,
    country: meta.country,
    continent: "Asia",
    startAt: startAt,
    endAt: startAt + 15 * SportsTime.DAY,
    weekendStartAt: startAt,
    weekendEndAt: startAt + 15 * SportsTime.DAY,
    sessions: sessions,
    dateOnly: true,
    round: meta.month,
    season: String(meta.year),
    yusho: SportsModel.arrayOf(data.yusho)
  }
}

function remainingDays(event, nowMs) {
  if (!event || !event.sessions) return 0
  var left = 0
  for (var i = 0; i < event.sessions.length; i++) {
    if (SportsModel.sessionState(event.sessions[i], nowMs) !== "done") left += 1
  }
  return left
}

function yushoRace(rikishi, daysLeft) {
  var list = SportsModel.arrayOf(rikishi)
  if (list.length === 0) return []
  var lead = 0
  for (var i = 0; i < list.length; i++) {
    if ((list[i].wins || 0) > lead) lead = list[i].wins
  }
  var out = []
  for (var j = 0; j < list.length; j++) {
    var row = list[j]
    if ((row.wins || 0) + daysLeft >= lead) out.push(row)
  }
  return out
}

function visibleDays(event, nowMs, limit) {
  var sessions = event && event.sessions ? event.sessions : []
  var out = []
  for (var i = 0; i < sessions.length; i++) {
    if (SportsModel.sessionState(sessions[i], nowMs) === "done") continue
    out.push(sessions[i])
    if (out.length >= (limit || 3)) break
  }
  return out
}

function parseBanzuke(raw) {
  var data = SportsModel.safeParse(raw)
  if (!data) return []
  var rows = SportsModel.arrayOf(data.east).concat(SportsModel.arrayOf(data.west))
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var wins = SportsModel.int(row.wins, 0)
    var losses = SportsModel.int(row.losses, 0)
    out.push({
      id: SportsModel.int(row.rikishiID, i),
      position: i + 1,
      name: SportsModel.str(row.shikonaEn),
      shikona: SportsModel.str(row.shikonaEn),
      code: SportsModel.str(row.shikonaEn).slice(0, 4).toUpperCase(),
      teamName: SportsModel.str(row.rank),
      heya: "",
      rank: SportsModel.str(row.rank),
      rankValue: SportsModel.int(row.rankValue, i + 1),
      side: SportsModel.str(row.side),
      points: wins,
      wins: wins,
      losses: losses,
      absences: SportsModel.int(row.absences, 0),
      record: wins + "-" + losses
    })
  }
  var live = false
  for (var w = 0; w < out.length; w++) {
    if ((out[w].wins || 0) > 0) { live = true; break }
  }
  out.sort(function(a, b) {
    if (live) {
      if (b.wins !== a.wins) return b.wins - a.wins
      if (a.losses !== b.losses) return a.losses - b.losses
    }
    if (a.rankValue !== b.rankValue) return a.rankValue - b.rankValue
    var as = SportsModel.str(a.side).toLowerCase() === "west" ? 1 : 0
    var bs = SportsModel.str(b.side).toLowerCase() === "west" ? 1 : 0
    return as - bs
  })
  for (var p = 0; p < out.length; p++) out[p].position = p + 1
  return out
}

function parseTorikumi(raw) {
  var data = SportsModel.safeParse(raw)
  var rows = data ? SportsModel.arrayOf(data.torikumi) : []
  var out = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row) continue
    var done = SportsModel.int(row.winnerId, 0) > 0
    out.push({
      position: SportsModel.int(row.matchNo, i + 1),
      acronym: done ? SportsModel.str(row.winnerEn).slice(0, 4).toUpperCase() : "—",
      name: SportsModel.str(row.eastShikona) + " vs " + SportsModel.str(row.westShikona),
      teamName: SportsModel.str(row.eastRank) + " · " + SportsModel.str(row.westRank),
      gap: done ? SportsModel.str(row.winnerEn) : "pending",
      leaderGap: done ? SportsModel.str(row.kimarite) : "",
      pits: 0,
      east: SportsModel.str(row.eastShikona),
      west: SportsModel.str(row.westShikona),
      eastRank: SportsModel.str(row.eastRank),
      westRank: SportsModel.str(row.westRank),
      winner: SportsModel.str(row.winnerEn),
      kimarite: SportsModel.str(row.kimarite),
      finished: done
    })
  }
  out.sort(function(a, b) { return a.position - b.position })
  return out
}

function parseRikishiList(raw) {
  var data = SportsModel.safeParse(raw)
  var rows = data ? SportsModel.arrayOf(data.records) : SportsModel.arrayOf(data)
  var map = {}
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row || row.id === undefined) continue
    map[String(row.id)] = {
      id: SportsModel.int(row.id),
      name: SportsModel.str(row.shikonaEn),
      heya: SportsModel.str(row.heya),
      rank: SportsModel.str(row.currentRank)
    }
  }
  return map
}

function applyHeya(rikishi, heyaMap) {
  var list = SportsModel.arrayOf(rikishi)
  var out = []
  for (var i = 0; i < list.length; i++) {
    var row = {}
    for (var k in list[i]) row[k] = list[i][k]
    var extra = heyaMap && heyaMap[String(row.id)]
    if (extra && extra.heya) {
      row.heya = extra.heya
      row.teamName = extra.heya
    }
    out.push(row)
  }
  return out
}

function heyaStandings(rikishi) {
  var groups = {}
  var list = SportsModel.arrayOf(rikishi)
  for (var i = 0; i < list.length; i++) {
    var family = SportsModel.str(list[i].heya) || SportsModel.str(list[i].rank).replace(/\s+\d.*$/, "") || "Makuuchi"
    if (!groups[family]) groups[family] = { id: family, name: family, teamName: family, heya: family, points: 0, wins: 0 }
    groups[family].wins += list[i].wins || 0
    groups[family].points += list[i].wins || 0
  }
  var out = []
  for (var key in groups) out.push(groups[key])
  out.sort(function(a, b) { return b.points - a.points })
  for (var p = 0; p < out.length; p++) out[p].position = p + 1
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    BASHO: BASHO,
    bashoId: bashoId,
    bashoMeta: bashoMeta,
    nearbyBashoIds: nearbyBashoIds,
    parseBasho: parseBasho,
    remainingDays: remainingDays,
    yushoRace: yushoRace,
    visibleDays: visibleDays,
    parseBanzuke: parseBanzuke,
    parseTorikumi: parseTorikumi,
    parseRikishiList: parseRikishiList,
    applyHeya: applyHeya,
    heyaStandings: heyaStandings
  }
}
