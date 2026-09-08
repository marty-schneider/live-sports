.pragma library

.import "SportsModel.js" as SportsModel

// Official pages for "where can I watch this" and live text updates.
// Rights change by country; these are the league/org hubs, not a stream.

var CATALOG = {
  cs: {
    watch: { label: "Twitch", url: "https://www.twitch.tv/directory/category/counter-strike" },
    updates: { label: "HLTV", url: "https://www.hltv.org/matches" }
  },
  nfl: {
    watch: { label: "NFL schedule", url: "https://www.nfl.com/schedules/" },
    updates: { label: "NFL scores", url: "https://www.nfl.com/scores/" }
  },
  nba: {
    watch: { label: "NBA Watch", url: "https://www.nba.com/watch" },
    updates: { label: "NBA scores", url: "https://www.nba.com/games" }
  },
  mlb: {
    watch: { label: "MLB.TV", url: "https://www.mlb.com/live-stream-games" },
    updates: { label: "MLB scores", url: "https://www.mlb.com/scores" }
  },
  nhl: {
    watch: { label: "NHL schedule", url: "https://www.nhl.com/schedule" },
    updates: { label: "NHL scores", url: "https://www.nhl.com/scores" }
  },
  epl: {
    watch: { label: "Premier League TV", url: "https://www.premierleague.com/broadcast" },
    updates: { label: "PL scores", url: "https://www.premierleague.com/matches" }
  },
  seriea: {
    watch: { label: "Serie A", url: "https://www.legaseriea.it/en" },
    updates: { label: "Serie A scores", url: "https://www.legaseriea.it/en/serie-a/fixture-and-results" }
  },
  ligue1: {
    watch: { label: "Ligue 1", url: "https://www.ligue1.com" },
    updates: { label: "Ligue 1 matches", url: "https://www.ligue1.com/calendrier-resultats" }
  },
  laliga: {
    watch: { label: "LaLiga Watch", url: "https://www.laliga.com/en-GB/watch" },
    updates: { label: "LaLiga results", url: "https://www.laliga.com/en-GB/laliga-easports/results" }
  },
  sumo: {
    watch: { label: "NHK World", url: "https://www3.nhk.or.jp/nhkworld/en/tv/sumo/" },
    updates: { label: "Nihon Sumo Kyokai", url: "https://www.sumo.or.jp/EnHonbashoSchedule/list/" }
  },
  gt: {
    watch: { label: "GT World Challenge", url: "https://www.youtube.com/@GTWorldChallengeEurope" },
    updates: { label: "SRO", url: "https://www.gt-world-challenge-europe.com/" }
  }
}

function forSport(id) {
  return CATALOG[SportsModel.str(id)] || null
}

function parseBroadcasts(comp) {
  var names = []
  var seen = {}
  function add(value) {
    var s = SportsModel.str(value)
    if (s === "" || seen[s]) return
    seen[s] = true
    names.push(s)
  }
  var rows = SportsModel.arrayOf(comp && comp.broadcasts)
  for (var i = 0; i < rows.length; i++) {
    var list = SportsModel.arrayOf(rows[i] && rows[i].names)
    if (list.length === 0) add(rows[i] && rows[i].market)
    for (var n = 0; n < list.length; n++) add(list[n])
  }
  var geo = SportsModel.arrayOf(comp && comp.geoBroadcasts)
  for (var g = 0; g < geo.length; g++) {
    var kind = SportsModel.str(geo[g] && geo[g].type && geo[g].type.shortName).toLowerCase()
    if (kind === "radio") continue
    add(geo[g] && geo[g].media && geo[g].media.shortName)
  }
  return names
}

function parseHttpsHost(href) {
  var s = SportsModel.str(href)
  if (s.indexOf("https://") !== 0) return ""
  if (/[\u0000-\u001f\u007f\\]/.test(s)) return ""
  var rest = s.slice(8)
  var cut = rest.search(/[/?#]/)
  var authority = (cut === -1 ? rest : rest.slice(0, cut)).toLowerCase()
  if (authority.indexOf("@") !== -1) return ""
  if (!/^[a-z0-9.-]+$/.test(authority)) return ""
  if (authority.indexOf("..") !== -1) return ""
  return authority
}

function hostIs(host, base) {
  return host === base || (host.length > base.length && host.slice(-(base.length + 1)) === "." + base)
}

function isFetchUrl(href) {
  var host = parseHttpsHost(href)
  if (host === "") return false
  return host === "site.api.espn.com"
    || host === "www.thesportsdb.com"
    || host === "api.csapi.de"
    || host === "sumo-api.com"
    || host === "www.sumo-api.com"
    || host === "api.pandascore.co"
}

function isOpenUrl(href) {
  var host = parseHttpsHost(href)
  if (host === "") return false
  if (hostIs(host, "espn.com")) return true
  var allowed = [
    "www.twitch.tv", "www.hltv.org", "www.nfl.com", "www.nba.com", "www.mlb.com",
    "www.nhl.com", "www.premierleague.com", "www.legaseriea.it", "www.ligue1.com",
    "www.laliga.com", "www3.nhk.or.jp", "www.sumo.or.jp", "www.youtube.com",
    "www.gt-world-challenge-europe.com"
  ]
  for (var i = 0; i < allowed.length; i++) {
    if (host === allowed[i]) return true
  }
  return false
}

function parseInfoUrl(row) {
  var links = SportsModel.arrayOf(row && row.links)
  var fallback = ""
  for (var i = 0; i < links.length; i++) {
    var rel = SportsModel.arrayOf(links[i] && links[i].rel).join(" ").toLowerCase()
    var href = SportsModel.str(links[i] && links[i].href)
    if (!isOpenUrl(href)) continue
    if (rel.indexOf("summary") !== -1) return href
    if (fallback === "") fallback = href
  }
  return fallback
}

if (typeof module !== "undefined") {
  module.exports = {
    forSport: forSport,
    parseBroadcasts: parseBroadcasts,
    parseInfoUrl: parseInfoUrl,
    parseHttpsHost: parseHttpsHost,
    isFetchUrl: isFetchUrl,
    isOpenUrl: isOpenUrl
  }
}
