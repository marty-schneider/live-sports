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
    const body = execFileSync("curl", ["-fsS", "--max-time", "30", "-A", "omarchy-live-sports/0.1", url], { maxBuffer: 1 << 24 })
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
assert("GT Spa is endurance-shaped", gtCal.some((e) => e.id === "eur-spa-24h" && e.sessions.some((s) => s.group === "Race")))

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
  const players = CsModel.parsePlayerStats(fixture("cs-players.json"))
  assert("CS players parse", players.length >= 5)
}

if (fs.existsSync(path.join(FIXTURES, "sumo-basho.json"))) {
  const basho = SumoModel.parseBasho(fixture("sumo-basho.json"), "202609")
  assert("Sumo basho has 15 days", basho && basho.sessions.length === 15)
  assert("Sumo Aki is Tokyo", basho.locality === "Tokyo")
}

if (fs.existsSync(path.join(FIXTURES, "sumo-banzuke.json"))) {
  const banzuke = SumoModel.parseBanzuke(fixture("sumo-banzuke.json"))
  assert("Sumo banzuke has yokozuna", banzuke.some((r) => /Yokozuna/i.test(r.rank)))
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

console.log(passed + " passed, " + failed + " failed")
process.exit(failed === 0 ? 0 : 1)
