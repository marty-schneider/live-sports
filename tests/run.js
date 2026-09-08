const fs = require("fs")
const path = require("path")
const { execFileSync, spawnSync } = require("child_process")

if (process.env.TZ !== "UTC") {
  const child = spawnSync(process.execPath, [__filename, ...process.argv.slice(2)], {
    stdio: "inherit",
    env: { ...process.env, TZ: "UTC" }
  })
  process.exit(child.status === null ? 1 : child.status)
}

const ROOT = path.join(__dirname, "..")
const FIXTURES = path.join(__dirname, "fixtures")
let failed = 0
let passed = 0

function load(file, deps = {}) {
  const src = fs
    .readFileSync(path.join(ROOT, file), "utf8")
    .split("\n")
    .filter((line) => !/^\s*\.(pragma|import)\b/.test(line))
    .join("\n")
  const module = { exports: {} }
  const names = Object.keys(deps)
  const fn = new Function("module", "exports", ...names, src)
  fn(module, module.exports, ...names.map((n) => deps[n]))
  return module.exports
}

const SportsTime = load("SportsTime.js")
const SportsModel = load("SportsModel.js", { SportsTime })
const CsModel = load("CsModel.js", { SportsTime, SportsModel })
const SumoModel = load("SumoModel.js", { SportsTime, SportsModel })
const GtModel = load("GtModel.js", { SportsTime, SportsModel })
const LeagueModel = load("LeagueModel.js", { SportsTime, SportsModel })

const SOURCES = {
  "cs-rankings.json": "https://api.csapi.de/rankings/",
  "cs-matches.json": "https://api.csapi.de/matches/latest?limit=20",
  "cs-players.json": "https://api.csapi.de/players/stats",
  "sumo-basho.json": "https://sumo-api.com/api/basho/202609",
  "sumo-banzuke.json": "https://sumo-api.com/api/basho/202609/banzuke/Makuuchi",
  "sumo-torikumi.json": "https://sumo-api.com/api/basho/202507/torikumi/Makuuchi/15"
}

if (process.argv.includes("--refresh")) {
  fs.mkdirSync(FIXTURES, { recursive: true })
  for (const [name, url] of Object.entries(SOURCES)) {
    process.stdout.write(`fetching ${name} … `)
    const body = execFileSync("curl", ["-fsS", "--max-time", "30", "-A", "omarchy-sports-tracker/0.1", url], { maxBuffer: 1 << 24 })
    fs.writeFileSync(path.join(FIXTURES, name), body)
    console.log(`${body.length} bytes`)
  }
}

function fixture(name) {
  return fs.readFileSync(path.join(FIXTURES, name), "utf8")
}

function assert(name, cond) {
  if (cond) {
    passed += 1
    console.log("ok  " + name)
  } else {
    failed += 1
    console.log("FAIL  " + name)
  }
}

assert("countdown is instant arithmetic", SportsTime.shortCountdown(60 * 1000, 0) === "01:00")
assert("iso parse", SportsTime.parseIso("2026-09-13T00:00:00Z") === Date.parse("2026-09-13T00:00:00Z"))

assert("CS BLAST Open is tier 1", CsModel.isTier1("BLAST Open Porto 2026") === true)
assert("CS CCT is not tier 1", CsModel.isTier1("CCT Europe Series #10") === false)
assert("CS IEM is tier 1", CsModel.isTier1("IEM Beijing 2026") === true)
assert("CS major is tier 1", CsModel.isTier1("PGL Singapore Major 2026") === true)
assert("CS qualifier excluded", CsModel.isTier1("IEM Beijing Open Qualifier") === false)
assert("CS RMR included", CsModel.isTier1("Europe RMR 2026") === true)

const csCal = CsModel.seedCalendar()
assert("CS seed has remaining 2026 events", csCal.length >= 4)
assert("CS seed is sorted", csCal.every((e, i) => i === 0 || e.startAt >= csCal[i - 1].startAt))

const gtCal = GtModel.seedCalendar()
assert("GT calendar covers four continents", new Set(gtCal.map((e) => e.continent)).size === 4)
assert("GT has Zandvoort sessions", gtCal.some((e) => e.id === "eur-zandvoort" && e.sessions.length >= 6))
assert("GT Spa has no invented sessions", gtCal.some((e) => e.id === "eur-spa-24h" && e.dateOnly === true && e.sessions.length === 0))
assert("CS seed has no invented sessions", csCal.every((e) => e.sessions.length === 0 && e.dateOnly === true))
assert("auto-sport prefers live", SportsModel.pickAutoSport([
  { id: "cs", live: false, nextAt: 100 },
  { id: "sumo", live: true, nextAt: 500 },
  { id: "gt", live: false, nextAt: 50 }
], 0) === "sumo")
assert("auto-sport picks soonest", SportsModel.pickAutoSport([
  { id: "cs", live: false, nextAt: 200 },
  { id: "sumo", live: false, nextAt: 80 },
  { id: "gt", live: false, nextAt: 500 }
], 0) === "sumo")
assert("followed empty means all", SportsModel.normalizeFollowed([], ["cs", "nfl", "sumo"]).join(",") === "cs,nfl,sumo")
assert("followed keeps catalog order", SportsModel.normalizeFollowed(["sumo", "cs"], ["cs", "nfl", "sumo"]).join(",") === "cs,sumo")
assert("followed unknown falls back to all", SportsModel.normalizeFollowed(["nope"], ["cs", "nfl"]).join(",") === "cs,nfl")
assert("cannot unfollow the last sport", SportsModel.toggleFollowed(["cs"], "cs", ["cs", "nfl"]).join(",") === "cs")
assert("unfollow one of many", SportsModel.toggleFollowed(["cs", "nfl"], "cs", ["cs", "nfl", "sumo"]).join(",") === "nfl")
assert("follow adds back in catalog order", SportsModel.toggleFollowed(["nfl"], "cs", ["cs", "nfl", "sumo"]).join(",") === "cs,nfl")
assert("auto-sport prefers favorite live", SportsModel.pickAutoSport([
  { id: "nfl", live: true, nextAt: 50 },
  { id: "mlb", live: true, favoriteLive: true, nextAt: 80 }
], 0) === "mlb")
assert("favorite toggle adds and removes", (function() {
  var one = SportsModel.toggleFavorite({}, "nfl", "Buffalo Bills")
  var two = SportsModel.toggleFavorite(one, "nfl", "Kansas City Chiefs")
  var back = SportsModel.toggleFavorite(two, "nfl", "Buffalo Bills")
  return SportsModel.favoritesOf(two, "nfl").join(",") === "Buffalo Bills,Kansas City Chiefs"
    && SportsModel.favoritesOf(back, "nfl").join(",") === "Kansas City Chiefs"
})())
assert("involvesTeam matches home or away", SportsModel.involvesTeam({
  name: "Patriots at Seahawks", team1Name: "New England Patriots", team2Name: "Seattle Seahawks"
}, ["Seattle Seahawks"]) === true)
assert("involvesTeam ignores bystanders", SportsModel.involvesTeam({
  name: "Patriots at Seahawks", team1Name: "New England Patriots", team2Name: "Seattle Seahawks"
}, ["Buffalo Bills"]) === false)
assert("tracked event prefers the favorite", SportsModel.pickTrackedEvent([
  { id: "a", name: "A at B", team1Name: "A", team2Name: "B", startAt: 100, endAt: 200 },
  { id: "b", name: "Yanks at Sox", team1Name: "Yankees", team2Name: "Red Sox", startAt: 300, endAt: 400 }
], ["Yankees"], 0).id === "b")
const favTable = SportsModel.standingsWithFavorites([
  { id: 1, name: "A", points: 10, position: 1 },
  { id: 2, name: "B", points: 9, position: 2 },
  { id: 3, name: "C", points: 8, position: 3 },
  { id: 4, name: "D", points: 7, position: 4 },
  { id: 5, name: "E", points: 6, position: 5 },
  { id: 6, name: "Spirit", points: 4, position: 8 }
], 5, ["Spirit"])
assert("favorite outside top 5 is an extra row", favTable.extras.length === 1 && favTable.extras[0].name === "Spirit")
assert("seed favorites from old pins", SportsModel.favoritesOf(SportsModel.seedFavorites({}, [{ sport: "cs", name: "Spirit" }]), "cs").join(",") === "Spirit")
assert("day countdown today", SportsTime.dayCountdown(0, 0, SportsTime.defaultContext()) === "today")
assert("day countdown future", SportsTime.dayCountdown(3 * SportsTime.DAY, 0, SportsTime.defaultContext()) === "3d")

const pin = SportsModel.standingsWithPin(
  [
    { id: 1, name: "A", points: 10, position: 1 },
    { id: 2, name: "B", points: 9, position: 2 },
    { id: 3, name: "C", points: 8, position: 3 },
    { id: 4, name: "D", points: 7, position: 4 },
    { id: 5, name: "E", points: 6, position: 5 },
    { id: 6, name: "F", points: 5, position: 6 },
    { id: 7, name: "Spirit", points: 4, position: 8 }
  ],
  5,
  "Spirit"
)
assert("pin appears when outside top 5", pin.pin && pin.pin.name === "Spirit")
assert("gap to leader", pin.gap === 6)

if (fs.existsSync(path.join(FIXTURES, "cs-rankings.json"))) {
  const ranks = CsModel.parseRankings(fixture("cs-rankings.json"))
  assert("CS rankings parse", ranks.length >= 5 && ranks[0].name)
  const matches = CsModel.parseMatches(fixture("cs-matches.json"))
  assert("CS matches filter to tier 1", matches.every((m) => CsModel.isTier1(m.event)))
  assert("CS matches do not invent kickoff times", matches.every((m) => m.dateOnly === true))
  const players = CsModel.parsePlayerStats(fixture("cs-players.json"))
  assert("CS players parse", players.length >= 5)
}

if (fs.existsSync(path.join(FIXTURES, "sumo-basho.json"))) {
  const basho = SumoModel.parseBasho(fixture("sumo-basho.json"), "202609")
  assert("Sumo basho has 15 days", basho && basho.sessions.length === 15)
  assert("Sumo days are date-only", basho.sessions.every((s) => s.dateOnly === true))
  assert("Sumo Aki is Tokyo", basho.locality === "Tokyo")
  assert("Sumo short is AKI", basho.short === "AKI")
  assert("yusho race includes anyone who can catch the leader", SumoModel.yushoRace([
    { name: "A", wins: 10 }, { name: "B", wins: 8 }, { name: "C", wins: 2 }
  ], 2).map((r) => r.name).join(",") === "A,B")
}

if (fs.existsSync(path.join(FIXTURES, "sumo-banzuke.json"))) {
  const banzuke = SumoModel.parseBanzuke(fixture("sumo-banzuke.json"))
  assert("Sumo banzuke has yokozuna", banzuke.some((r) => /Yokozuna/i.test(r.rank)))
  assert("Sumo banzuke keeps Aonishiki in sanyaku order", banzuke.findIndex((r) => r.name === "Aonishiki") >= 0 && banzuke.findIndex((r) => r.name === "Aonishiki") <= 6)
  assert("Sumo pre-basho lists yokozuna first", banzuke[0] && /Yokozuna/i.test(banzuke[0].rank))
}

if (fs.existsSync(path.join(FIXTURES, "sumo-torikumi.json"))) {
  const bouts = SumoModel.parseTorikumi(fixture("sumo-torikumi.json"))
  assert("Sumo torikumi has bouts", bouts.length >= 10)
  assert("Sumo bout names east vs west", bouts[bouts.length - 1].name.indexOf(" vs ") !== -1)
}

assert("notificationArg strips dashes", SportsModel.notificationArg("--hint=bad", "x") === "hint=bad")
assert("invalid sumo basho rejected", SumoModel.parseBasho(JSON.stringify({
  date: "", startDate: "0001-01-01T00:00:00Z", endDate: "0001-01-01T00:00:00Z"
}), "202611") === null)

const heyaMap = { "8850": { id: 8850, name: "Onosato", heya: "Nishonoseki", rank: "Yokozuna" } }
const withHeya = SumoModel.applyHeya([{ id: 8850, name: "Onosato", wins: 3, rank: "Yokozuna 1 East" }], heyaMap)
assert("heya joined onto banzuke", withHeya[0].heya === "Nishonoseki")
assert("heya standings use stables", SumoModel.heyaStandings(withHeya)[0].name === "Nishonoseki")

assert("live matches are unfinished today", CsModel.liveMatches([
  { date: CsModel.utcDateString(Date.now()), finished: false, event: "BLAST Open" },
  { date: CsModel.utcDateString(Date.now()), finished: true, event: "BLAST Open" }
], Date.now()).length === 1)

assert("closed qualifier is not tier 1", CsModel.isTier1("IEM Beijing 2026 Closed Qualifier") === false)

const espnBoard = LeagueModel.parseEspnScoreboard(fs.readFileSync(path.join(FIXTURES, "espn-board.json"), "utf8"), { title: "NFL", short: "NFL", id: "nfl" })
assert("ESPN board parses two games", espnBoard.length === 2)
assert("ESPN uses kickoff from feed", espnBoard[0].dateOnly === false && espnBoard[0].startAt === Date.parse("2026-09-10T00:20:00Z"))
assert("ESPN finished game has a winner", espnBoard[1].finished === true && espnBoard[1].winnerName === "Buffalo Bills")
const espnSplit = LeagueModel.splitMatches(espnBoard, Date.parse("2026-09-08T00:00:00Z"))
assert("ESPN upcoming vs recent", espnSplit.upcoming.length === 1 && espnSplit.recent.length === 1)
const espnTable = LeagueModel.parseEspnStandings(fs.readFileSync(path.join(FIXTURES, "espn-standings.json"), "utf8"))
assert("ESPN standings order by wins", espnTable[0].name === "Buffalo Bills" && espnTable[0].note === "1-0")
const dbKick = LeagueModel.parseSportsDbTimestamp({ strTimestamp: "2026-09-12T14:00:00", dateEvent: "2026-09-12" })
assert("SportsDB timestamp treated as UTC", dbKick.dateOnly === false && dbKick.at === Date.parse("2026-09-12T14:00:00Z"))
const dbDay = LeagueModel.parseSportsDbTimestamp({ dateEvent: "2026-09-12" })
assert("SportsDB date-only stays date-only", dbDay.dateOnly === true)

const tba = LeagueModel.parseEspnScoreboard(JSON.stringify({
  events: [{
    id: "tba",
    date: "2026-09-20T17:00Z",
    name: "TBD at Host",
    status: { type: { state: "pre" } },
    competitions: [{
      timeValid: false,
      competitors: [
        { homeAway: "home", score: "0", team: { displayName: "Host" } },
        { homeAway: "away", score: "0", team: { displayName: "TBD" } }
      ]
    }]
  }]
}), { title: "NFL", short: "NFL", id: "nfl" })
assert("ESPN timeValid false stays date-only", tba.length === 1 && tba[0].dateOnly === true)
const tbaEvent = LeagueModel.matchToEvent(tba[0], { title: "NFL", short: "NFL", id: "nfl", durationMin: 210 })
assert("date-only match has no invented session", tbaEvent && tbaEvent.sessions.length === 0 && tbaEvent.dateOnly === true)

const dbEvents = LeagueModel.parseSportsDbEvents(JSON.stringify({
  events: [{
    idEvent: "123",
    strEvent: "Bournemouth vs Brentford",
    strHomeTeam: "Bournemouth",
    strAwayTeam: "Brentford",
    strTimestamp: "2026-09-12T14:00:00",
    dateEvent: "2026-09-12",
    strStatus: "NS",
    strVenue: "Vitality Stadium"
  }]
}), { title: "Premier League", short: "EPL", id: "epl" })
assert("SportsDB next fixture keeps kickoff", dbEvents.length === 1 && dbEvents[0].dateOnly === false && dbEvents[0].startAt === Date.parse("2026-09-12T14:00:00Z"))
assert("SportsDB uses feed name", dbEvents[0].name === "Bournemouth vs Brentford")

const merged = LeagueModel.mergeMatchLists(espnBoard, [{
  date: "2026-09-10",
  team1: { name: "New England Patriots" },
  team2: { name: "Seattle Seahawks" },
  startAt: Date.parse("2026-09-10T00:20:00Z"),
  name: "Seattle Seahawks vs New England Patriots"
}, {
  date: "2026-09-12",
  team1: { name: "Brentford" },
  team2: { name: "Bournemouth" },
  startAt: Date.parse("2026-09-12T14:00:00Z"),
  name: "Bournemouth vs Brentford"
}])
assert("merge keeps ESPN game once", merged.filter((m) => m.date === "2026-09-10").length === 1)
assert("merge adds the extra fixture", merged.some((m) => m.name === "Bournemouth vs Brentford"))

const soccerTable = LeagueModel.parseEspnStandings(JSON.stringify({
  children: [{
    standings: {
      entries: [
        { team: { displayName: "Manchester City" }, stats: [{ name: "points", abbreviation: "P", value: 9, displayValue: "9" }, { name: "wins", abbreviation: "W", value: 3, displayValue: "3" }] },
        { team: { displayName: "Arsenal" }, stats: [{ name: "points", abbreviation: "P", value: 7, displayValue: "7" }, { name: "wins", abbreviation: "W", value: 2, displayValue: "2" }] }
      ]
    }
  }]
}))
assert("soccer table ranks by points", soccerTable[0].name === "Manchester City" && soccerTable[0].points === 9)
const wdl = LeagueModel.parseEspnStandings(JSON.stringify({
  children: [{
    standings: {
      entries: [{
        team: { displayName: "Arsenal" },
        stats: [
          { name: "wins", abbreviation: "W", value: 2, displayValue: "2" },
          { name: "ties", abbreviation: "D", value: 1, displayValue: "1" },
          { name: "losses", abbreviation: "L", value: 0, displayValue: "0" },
          { name: "points", abbreviation: "P", value: 7, displayValue: "7" }
        ]
      }]
    }
  }]
}))
assert("soccer record is W-D-L", wdl[0].note === "2-1-0")

const postOnly = LeagueModel.parseEspnScoreboard(JSON.stringify({
  events: [{
    id: "old",
    date: "2026-09-06T15:30Z",
    name: "Chelsea at Arsenal",
    status: { type: { state: "post", completed: true } },
    competitions: [{
      timeValid: true,
      competitors: [
        { homeAway: "home", score: "2", team: { displayName: "Arsenal" } },
        { homeAway: "away", score: "1", team: { displayName: "Chelsea" } }
      ]
    }]
  }]
}), { title: "Premier League", short: "EPL", id: "epl" })
const filled = LeagueModel.mergeMatchLists(postOnly, dbEvents)
const filledSplit = LeagueModel.splitMatches(filled, Date.parse("2026-09-07T12:00:00Z"))
const filledEvents = LeagueModel.eventsFromMatches(filledSplit, { title: "Premier League", short: "EPL", id: "epl", durationMin: 120 }, Date.parse("2026-09-07T12:00:00Z"))
assert("finished board still yields next fixture", filledSplit.recent.length === 1 && filledEvents.length === 1 && filledEvents[0].name === "Bournemouth vs Brentford")

console.log(passed + " passed, " + failed + " failed")
process.exit(failed === 0 ? 0 : 1)
