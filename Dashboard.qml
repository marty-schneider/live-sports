import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "SportsTime.js" as SportsTime
import "SportsModel.js" as SportsModel
import "CsColors.js" as CsColors
import "GtColors.js" as GtColors

Panel {
  id: root
  moduleName: "io.github.marty-schneider.sports-tracker"
  ipcTarget: "io.github.marty-schneider.sports-tracker"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var settings: ({})
  readonly property var barIdentity: hostWidget || root

  function setting(key, fallback) {
    if (root.settings && root.settings[key] !== undefined && root.settings[key] !== null && String(root.settings[key]) !== "")
      return root.settings[key]
    return fallback
  }

  readonly property bool hour12: String(setting("timeFormat", "24-hour")) === "12-hour"
  readonly property bool autoLive: setting("autoLive", true) === true
  readonly property int liveRefreshSec: Math.max(5, Math.min(120, parseInt(setting("liveRefreshSec", 12), 10) || 12))
  readonly property int refreshMinutes: Math.max(5, parseInt(setting("refreshMinutes", 15), 10) || 15)
  readonly property bool notificationsEnabled: setting("notifications", true) === true
  readonly property string notifyLeadMinutes: String(setting("notifyLeadMinutes", "30,15"))
  readonly property string defaultSport: String(setting("defaultSport", "auto"))
  property string csPinPlayer: String(setting("csHighlightPlayer", "donk"))
  property string csPinTeam: String(setting("csHighlightTeam", "Spirit"))
  property string sumoPinPlayer: String(setting("sumoHighlightPlayer", "Onosato"))
  property string sumoPinTeam: String(setting("sumoHighlightTeam", "Nishonoseki"))
  property string gtPinPlayer: String(setting("gtHighlightPlayer", ""))
  property string gtPinTeam: String(setting("gtHighlightTeam", "Mercedes"))

  property string sportLock: "auto"
  property string gtContinent: "all"
  property var pins: ({})
  property var followed: []
  property bool settingsOpen: false
  readonly property var sportIds: ["cs", "nfl", "nba", "mlb", "nhl", "epl", "seriea", "ligue1", "laliga", "sumo", "gt"]
  readonly property var sports: sportIds
  readonly property var sportCatalog: [
    { id: "cs", label: "CS2" },
    { id: "nfl", label: "NFL" },
    { id: "nba", label: "NBA" },
    { id: "mlb", label: "MLB" },
    { id: "nhl", label: "NHL" },
    { id: "epl", label: "EPL" },
    { id: "seriea", label: "SERIE A" },
    { id: "ligue1", label: "LIGUE 1" },
    { id: "laliga", label: "LA LIGA" },
    { id: "sumo", label: "SUMO" },
    { id: "gt", label: "GT" }
  ]
  readonly property var sportChips: [{ id: "auto", label: "AUTO" }].concat(sportCatalog)
  readonly property var followedIds: SportsModel.normalizeFollowed(followed, sportIds)
  readonly property var visibleChips: {
    var out = [{ id: "auto", label: "AUTO" }]
    for (var i = 0; i < sportCatalog.length; i++) {
      if (followedIds.indexOf(sportCatalog[i].id) >= 0) out.push(sportCatalog[i])
    }
    return out
  }

  readonly property double now: timeSvc.now
  readonly property var timeCtx: timeSvc.context

  function fmtTime(at) { return SportsTime.formatTime(at, timeCtx) }
  function fmtDate(at) { return SportsTime.formatDate(at, timeCtx) }
  function fmtDateLong(at) { return SportsTime.formatDateLong(at, timeCtx) }
  function fmtDay(at) { return SportsTime.formatDayShort(at, timeCtx) }
  function fmtDayTime(at) { return SportsTime.formatDayTime(at, timeCtx) }
  function fmtRange(from, to) { return SportsTime.formatDateRange(from, to, timeCtx) }
  function countdownTo(at) { return SportsTime.countdown(at, now) }
  function shortCountdownTo(at) { return SportsTime.shortCountdown(at, now) }
  function dayCountdownTo(at) { return SportsTime.dayCountdown(at, now, timeCtx) }
  function agoOf(at) { return SportsTime.agoText(at, now) }
  function stateOf(session) { return SportsModel.sessionState(session, now) }
  function hasClock(session) { return SportsModel.hasClock(session) }

  property TimeService timeSvc: TimeService {
    hour12: root.hour12
    fastTick: root.opened || root.liveMode
  }

  property CsService cs: CsService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.csPinPlayer
    highlightTeam: root.csPinTeam
  }
  property SumoService sumo: SumoService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.sumoPinPlayer
    highlightTeam: root.sumoPinTeam
  }
  property GtService gt: GtService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.gtPinPlayer
    highlightTeam: root.gtPinTeam
    continentFilter: root.gtContinent
  }

  property LeagueService nfl: LeagueService {
    sportId: "nfl"; title: "NFL"; shortName: "NFL"; durationMin: 210
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("nfl", "team"); highlightPlayer: root.pinOf("nfl", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/football/nfl/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4391"
  }
  property LeagueService nba: LeagueService {
    sportId: "nba"; title: "NBA"; shortName: "NBA"; durationMin: 150
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("nba", "team"); highlightPlayer: root.pinOf("nba", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/basketball/nba/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4387"
  }
  property LeagueService mlb: LeagueService {
    sportId: "mlb"; title: "MLB"; shortName: "MLB"; durationMin: 210
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("mlb", "team"); highlightPlayer: root.pinOf("mlb", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/baseball/mlb/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4424"
  }
  property LeagueService nhl: LeagueService {
    sportId: "nhl"; title: "NHL"; shortName: "NHL"; durationMin: 150
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("nhl", "team"); highlightPlayer: root.pinOf("nhl", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/hockey/nhl/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4380"
  }
  property LeagueService epl: LeagueService {
    sportId: "epl"; title: "Premier League"; shortName: "EPL"; durationMin: 120
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("epl", "team"); highlightPlayer: root.pinOf("epl", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/soccer/eng.1/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4328"
  }
  property LeagueService seriea: LeagueService {
    sportId: "seriea"; title: "Serie A"; shortName: "SERIE A"; durationMin: 120
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("seriea", "team"); highlightPlayer: root.pinOf("seriea", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/soccer/ita.1/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4332"
  }
  property LeagueService ligue1: LeagueService {
    sportId: "ligue1"; title: "Ligue 1"; shortName: "LIGUE 1"; durationMin: 120
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("ligue1", "team"); highlightPlayer: root.pinOf("ligue1", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/soccer/fra.1/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/soccer/fra.1/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4334"
  }
  property LeagueService laliga: LeagueService {
    sportId: "laliga"; title: "La Liga"; shortName: "LA LIGA"; durationMin: 120
    now: root.now; refreshMinutes: root.refreshMinutes
    highlightTeam: root.pinOf("laliga", "team"); highlightPlayer: root.pinOf("laliga", "player")
    scoreboardUrl: "https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/scoreboard"
    standingsUrl: "https://site.api.espn.com/apis/v2/sports/soccer/esp.1/standings"
    nextUrl: "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4335"
  }

  function sportService(id) {
    if (id === "nfl") return nfl
    if (id === "nba") return nba
    if (id === "mlb") return mlb
    if (id === "nhl") return nhl
    if (id === "epl") return epl
    if (id === "seriea") return seriea
    if (id === "ligue1") return ligue1
    if (id === "laliga") return laliga
    if (id === "sumo") return sumo
    if (id === "gt") return gt
    return cs
  }

  function pinOf(id, role) {
    if (id === "cs") return role === "player" ? csPinPlayer : csPinTeam
    if (id === "sumo") return role === "player" ? sumoPinPlayer : sumoPinTeam
    if (id === "gt") return role === "player" ? gtPinPlayer : gtPinTeam
    var p = pins[id]
    return p && p[role] ? p[role] : ""
  }

  function chipLabel(id) {
    for (var i = 0; i < sportChips.length; i++) {
      if (sportChips[i].id === id) return sportChips[i].label
    }
    return id.toUpperCase()
  }

  function standingValue(row) {
    if (!row) return ""
    if (viewedSport === "cs") return String(row.points) + " pts"
    if (row.note) return row.note
    return String(row.points) + " pts"
  }

  function isFollowed(id) {
    return followedIds.indexOf(id) >= 0
  }

  function toggleFollow(id) {
    var next = SportsModel.toggleFollowed(followedIds, id, sportIds)
    followed = next
    if (sportLock !== "auto" && next.indexOf(sportLock) < 0) sportLock = "auto"
    persistUi()
  }

  function followAll() {
    followed = sportIds.slice()
    persistUi()
  }

  readonly property var autoCandidates: {
    var all = [
      { id: "cs", live: root.cs.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.cs.event, root.now) },
      { id: "nfl", live: root.nfl.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.nfl.event, root.now) },
      { id: "nba", live: root.nba.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.nba.event, root.now) },
      { id: "mlb", live: root.mlb.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.mlb.event, root.now) },
      { id: "nhl", live: root.nhl.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.nhl.event, root.now) },
      { id: "epl", live: root.epl.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.epl.event, root.now) },
      { id: "seriea", live: root.seriea.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.seriea.event, root.now) },
      { id: "ligue1", live: root.ligue1.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.ligue1.event, root.now) },
      { id: "laliga", live: root.laliga.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.laliga.event, root.now) },
      { id: "sumo", live: root.sumo.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.sumo.event, root.now) },
      { id: "gt", live: root.gt.liveMatches.length > 0, nextAt: SportsModel.nextAt(root.gt.event, root.now) }
    ]
    var out = []
    for (var i = 0; i < all.length; i++) {
      if (followedIds.indexOf(all[i].id) >= 0) out.push(all[i])
    }
    return out
  }
  readonly property string autoSportId: SportsModel.pickAutoSport(autoCandidates, root.now)

  readonly property string viewedSport: followedIds.indexOf(sportLock) >= 0 ? sportLock : autoSportId
  readonly property var sport: sportService(viewedSport)
  readonly property string sportLabel: chipLabel(viewedSport)
  readonly property string sportTitle: sport && sport.title ? sport.title : chipLabel(viewedSport)

  property CsLiveService csLive: CsLiveService {
    now: root.now
    enabled: root.liveMode && root.viewedSport === "cs"
    refreshSeconds: root.liveRefreshSec
    scheduledSession: root.viewedSport === "cs" ? root.sport.liveSession : null
    matches: root.cs.matches
  }
  property SumoLiveService sumoLive: SumoLiveService {
    now: root.now
    enabled: root.liveMode && root.viewedSport === "sumo"
    scheduledSession: root.viewedSport === "sumo" ? root.sport.liveSession : null
    bouts: root.sumo.torikumi
  }
  property GtLiveService gtLive: GtLiveService {
    now: root.now
    enabled: root.liveMode && root.viewedSport === "gt"
    refreshSeconds: root.liveRefreshSec
    scheduledSession: root.viewedSport === "gt" ? root.sport.liveSession : null
  }

  readonly property var live: viewedSport === "sumo" ? sumoLive : viewedSport === "gt" ? gtLive : csLive
  readonly property bool hasLiveContent: !!(sport && sport.liveMatches && sport.liveMatches.length > 0)

  property Notifier notifier: Notifier {
    now: root.now
    enabled: root.notificationsEnabled
    events: (cs.event ? [cs.event] : []).concat(nfl.event ? [nfl.event] : []).concat(nba.event ? [nba.event] : []).concat(mlb.event ? [mlb.event] : []).concat(nhl.event ? [nhl.event] : []).concat(epl.event ? [epl.event] : []).concat(seriea.event ? [seriea.event] : []).concat(ligue1.event ? [ligue1.event] : []).concat(laliga.event ? [laliga.event] : []).concat(sumo.event ? [sumo.event] : []).concat(gt.event ? [gt.event] : [])
    timeContext: root.timeCtx
    leadMinutes: root.notifyLeadMinutes
    followedSport: root.viewedSport
    pinQueries: [
      { sport: "cs", value: root.csPinTeam },
      { sport: "cs", value: root.csPinPlayer },
      { sport: "sumo", value: root.sumoPinPlayer },
      { sport: "sumo", value: root.sumoPinTeam },
      { sport: "gt", value: root.gtPinPlayer },
      { sport: "gt", value: root.gtPinTeam },
      { sport: "nfl", value: root.pinOf("nfl", "team") },
      { sport: "nba", value: root.pinOf("nba", "team") },
      { sport: "mlb", value: root.pinOf("mlb", "team") },
      { sport: "nhl", value: root.pinOf("nhl", "team") },
      { sport: "epl", value: root.pinOf("epl", "team") },
      { sport: "seriea", value: root.pinOf("seriea", "team") },
      { sport: "ligue1", value: root.pinOf("ligue1", "team") },
      { sport: "laliga", value: root.pinOf("laliga", "team") }
    ]
  }

  property string liveOverride: ""
  readonly property bool autoLiveActive: autoLive && hasLiveContent
  readonly property bool liveMode: !hasLiveContent ? false
    : liveOverride === "on" ? true
    : liveOverride === "off" ? false
    : autoLiveActive

  function toggleLive() {
    if (!hasLiveContent) return
    liveOverride = liveMode ? "off" : "on"
  }
  onAutoLiveActiveChanged: liveOverride = ""
  onViewedSportChanged: liveOverride = ""

  function selectSport(id) {
    if (id === "auto") sportLock = "auto"
    else if (followedIds.indexOf(id) >= 0) sportLock = id
    persistUi()
  }

  function cycleSport(delta) {
    var order = ["auto"].concat(followedIds)
    var i = order.indexOf(sportLock)
    if (i < 0) i = 0
    selectSport(order[(i + delta + order.length) % order.length])
  }

  function pinValue(kind, name) {
    setPin(viewedSport, kind.indexOf("Team") >= 0 || kind === "team" ? "team" : "player", name)
  }

  function setPin(id, role, name) {
    var value = String(name || "")
    if (id === "cs" && role === "player") csPinPlayer = csPinPlayer === value ? "" : value
    else if (id === "cs" && role === "team") csPinTeam = csPinTeam === value ? "" : value
    else if (id === "sumo" && role === "player") sumoPinPlayer = sumoPinPlayer === value ? "" : value
    else if (id === "sumo" && role === "team") sumoPinTeam = sumoPinTeam === value ? "" : value
    else if (id === "gt" && role === "player") gtPinPlayer = gtPinPlayer === value ? "" : value
    else if (id === "gt" && role === "team") gtPinTeam = gtPinTeam === value ? "" : value
    else {
      var next = {}
      for (var k in pins) next[k] = pins[k]
      var cur = next[id] || {}
      var row = { player: cur.player || "", team: cur.team || "" }
      row[role] = row[role] === value ? "" : value
      next[id] = row
      pins = next
    }
    persistUi()
  }

  function persistUi() {
    uiFile.setText(JSON.stringify({
      sportLock: sportLock,
      gtContinent: gtContinent,
      followed: followedIds,
      pins: {
        csPlayer: csPinPlayer, csTeam: csPinTeam,
        sumoPlayer: sumoPinPlayer, sumoTeam: sumoPinTeam,
        gtPlayer: gtPinPlayer, gtTeam: gtPinTeam,
        leagues: pins
      }
    }) + "\n")
  }

  function loadUi(raw) {
    var parsed = SportsModel.safeParse(raw)
    if (!parsed) {
      if (defaultSport === "auto" || sports.indexOf(defaultSport) >= 0) sportLock = defaultSport
      return
    }
    if (parsed.sportLock === "auto" || sports.indexOf(parsed.sportLock) >= 0) sportLock = parsed.sportLock
    else if (parsed.sportId === "auto" || sports.indexOf(parsed.sportId) >= 0) sportLock = parsed.sportId
    if (parsed.gtContinent) gtContinent = parsed.gtContinent
    if (Array.isArray(parsed.followed)) followed = parsed.followed
    var pins = parsed.pins || {}
    if (pins.csPlayer !== undefined) csPinPlayer = pins.csPlayer
    if (pins.csTeam !== undefined) csPinTeam = pins.csTeam
    if (pins.sumoPlayer !== undefined) sumoPinPlayer = pins.sumoPlayer
    if (pins.sumoTeam !== undefined) sumoPinTeam = pins.sumoTeam
    if (pins.gtPlayer !== undefined) gtPinPlayer = pins.gtPlayer
    if (pins.gtTeam !== undefined) gtPinTeam = pins.gtTeam
    if (pins.leagues && typeof pins.leagues === "object") root.pins = pins.leagues
  }

  property FileView uiFile: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/sports-tracker/ui.json"
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadUi(text())
    onLoadFailed: root.loadUi("")
  }

  readonly property string label: {
    var ev = sport.event
    var short = (ev && ev.short) ? ev.short : sportLabel
    if (!sport.loaded) return short + (sport.failed ? " —" : " ⋯")
    if (sport.offSeason) return short + " OFF"
    if (hasLiveContent) return short + " LIVE"
    var at = SportsModel.nextAt(ev, now)
    if (!SportsTime.isInstant(at)) return short + " —"
    if (SportsModel.eventIsDateOnly(ev)) return short + " " + dayCountdownTo(at)
    return short + " " + shortCountdownTo(at)
  }

  readonly property string tooltipText: {
    if (!sport.loaded) return sportTitle + " — loading"
    if (sport.offSeason) return sportTitle + " — off season"
    if (hasLiveContent && sport.event)
      return sport.event.name + " is on"
    var ev = sport.event
    if (!ev) return sportTitle
    var next = SportsModel.nextSession(ev, now)
    var at = SportsModel.nextAt(ev, now)
    var when = next && hasClock(next) ? fmtDayTime(next.startAt) : fmtDate(at)
    return ev.name + (when ? " · " + when : "")
  }

  readonly property bool sessionLive: hasLiveContent

  property bool openedFromHotkey: false

  function open() {
    openedFromHotkey = false
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    onOpened()
  }
  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    onOpened()
    Qt.callLater(function() { if (root.opened) setCenterHoverRevealSuppressed(true) })
  }
  function onOpened() {
    timeSvc.refreshZone()
    sport.refresh(false)
  }
  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }
  function toggle() { if (root.opened) close(); else openFromHotkey() }
  function refresh() {
    cs.refresh(true)
    nfl.refresh(true)
    nba.refresh(true)
    mlb.refresh(true)
    nhl.refresh(true)
    epl.refresh(true)
    seriea.refresh(true)
    ligue1.refresh(true)
    laliga.refresh(true)
    sumo.refresh(true)
    gt.refresh(true)
    if (live.refreshNow) live.refreshNow()
  }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }
  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function sport(id: string): string {
      if (id === "auto" || root.followedIds.indexOf(id) >= 0) root.selectSport(id)
      else if (id === "next") root.cycleSport(1)
      else if (id === "prev") root.cycleSport(-1)
      return root.viewedSport
    }
    function live(mode: string): string {
      if (mode === "on" || mode === "off") root.liveOverride = mode
      else if (mode === "auto") root.liveOverride = ""
      else root.toggleLive()
      return root.liveMode ? "on" : "off"
    }
    function settings(): string {
      root.settingsOpen = !root.settingsOpen
      return root.settingsOpen ? "on" : "off"
    }
    function status(): string { return root.tooltipText }
  }

  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property color dim: Qt.darker(fg, 1.6)
  readonly property color dimmer: Qt.darker(fg, 2.0)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(640))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: {
        if (root.settingsOpen) root.settingsOpen = false
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: { if (root.hasLiveContent) root.toggleLive() }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.cycleSport(dx)
        if (dy === 0) return
        scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, scroll.contentY + dy * Style.space(48)))
      }
      onTextKey: function(text) {
        if (text === "r") root.refresh()
        else if (text === "s") root.settingsOpen = !root.settingsOpen
        else if (text === "0") root.selectSport("auto")
        else if (text === "1") root.selectSport("cs")
        else if (text === "2") root.selectSport("sumo")
        else if (text === "3") root.selectSport("gt")
        else if (text === "g") scroll.contentY = 0
        else if (text === "G") scroll.contentY = Math.max(0, scroll.contentHeight - scroll.height)
      }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: column
          width: scroll.width
          spacing: Style.space(12)

          Item {
            width: parent.width
            height: Math.max(switcher.implicitHeight, headerActions.implicitHeight)

            Flow {
              id: switcher
              anchors.left: parent.left
              anchors.right: headerActions.left
              anchors.rightMargin: Style.space(8)
              anchors.leftMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(6)

              Repeater {
                model: root.visibleChips
                Rectangle {
                  required property var modelData
                  readonly property bool selected: root.sportLock === modelData.id
                  implicitWidth: chipText.implicitWidth + Style.space(16)
                  implicitHeight: chipText.implicitHeight + Style.space(8)
                  radius: Math.max(2, Style.cornerRadius)
                  color: selected ? Util.alpha(Color.accent, 0.18) : Util.alpha(root.fg, 0.05)
                  border.width: selected ? 1 : 0
                  border.color: Util.alpha(Color.accent, 0.5)
                  Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData.label
                    color: selected ? Color.accent : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: selected
                    font.letterSpacing: 0.8
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectSport(modelData.id)
                  }
                  Accessible.role: Accessible.Button
                  Accessible.name: modelData.label
                  Accessible.checkable: true
                  Accessible.checked: selected
                }
              }
            }

            Row {
              id: headerActions
              anchors.right: parent.right
              anchors.rightMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(6)

              PanelActionButton {
                iconText: "󰒓"
                tooltipText: root.settingsOpen ? "Close follow list" : "Choose sports to follow"
                foreground: root.settingsOpen ? Color.accent : root.dim
                hoverColor: Color.accent
                fontFamily: root.fontFamily
                bordered: root.settingsOpen
                onClicked: root.settingsOpen = !root.settingsOpen
                Accessible.role: Accessible.Button
                Accessible.name: "Followed sports"
              }

              Rectangle {
                id: liveToggle
                visible: root.hasLiveContent && !root.settingsOpen
                implicitWidth: toggleLabel.implicitWidth + Style.space(20)
                implicitHeight: toggleLabel.implicitHeight + Style.space(9)
                radius: Math.max(2, Style.cornerRadius)
                color: root.liveMode ? Util.alpha(Color.urgent, 0.18) : Util.alpha(root.fg, 0.05)
                border.width: 1
                border.color: root.liveMode ? Util.alpha(Color.urgent, 0.55) : Util.alpha(root.fg, 0.16)
                Text {
                  id: toggleLabel
                  anchors.centerIn: parent
                  text: root.liveMode ? "LIVE · ON" : "LIVE · OFF"
                  color: root.liveMode ? Color.urgent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: root.liveMode
                  font.letterSpacing: 0.8
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleLive()
                }
              }
            }
          }

          Row {
            leftPadding: Style.space(4)
            spacing: Style.space(10)
            visible: !root.settingsOpen
            StatusChip {
              text: root.liveMode ? "LIVE" : (root.sport.weekend ? root.sport.weekend.label : root.sportTitle.toUpperCase())
              tone: root.liveMode || (root.sport.weekend && root.sport.weekend.kind === "live") ? "live"
                : root.sport.weekend && root.sport.weekend.kind === "soon" ? "soon" : "accent"
              foreground: root.fg
              fontFamily: root.fontFamily
              filled: true
            }
            Text {
              visible: root.sport.event !== null
              anchors.verticalCenter: parent.verticalCenter
              text: root.sport.event ? root.sport.event.series : ""
              color: root.dimmer
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: !root.settingsOpen && !root.sport.loaded
            Text {
              text: root.sport.failed ? "Could not reach the " + root.sportTitle + " data service." : "Loading " + root.sportTitle + "…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              leftPadding: Style.space(4)
            }
          }

          Text {
            width: parent.width
            visible: !root.settingsOpen && root.sport.loaded && root.sport.offSeason
            text: "Nothing scheduled. Waiting for the next " + root.sportTitle + " event."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            leftPadding: Style.space(4)
            wrapMode: Text.WordWrap
          }

          Loader {
            width: parent.width
            active: !root.settingsOpen && root.liveMode && root.sport.loaded
            visible: active
            sourceComponent: liveView
          }

          Loader {
            width: parent.width
            active: !root.settingsOpen && !root.liveMode && root.sport.loaded && !root.sport.offSeason
            visible: active
            sourceComponent: overview
          }

          Loader {
            width: parent.width
            active: root.settingsOpen
            visible: active
            sourceComponent: followSettings
          }

          PanelSeparator { width: parent.width; visible: root.sport.loaded || root.settingsOpen }

          Item {
            width: parent.width
            height: footerLeft.implicitHeight
            visible: root.sport.loaded || root.settingsOpen
            Column {
              id: footerLeft
              visible: !root.settingsOpen
              anchors.left: parent.left
              anchors.leftMargin: Style.space(4)
              spacing: Style.space(2)
              Text {
                text: "All times in " + root.timeSvc.zoneLabel
                color: root.dimmer
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              Text {
                text: root.sport.stale
                  ? "Offline — cached " + root.agoOf(root.sport.lastUpdatedAt)
                  : "Updated " + root.agoOf(root.sport.lastUpdatedAt)
                color: root.sport.stale ? Color.urgent : root.dimmer
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
            Text {
              anchors.right: parent.right
              anchors.rightMargin: Style.space(4)
              anchors.bottom: parent.bottom
              text: root.settingsOpen
                ? "toggle sports to follow · s or esc back"
                : "0 auto · gear follows · click to pin · r refresh · esc close"
              color: root.dimmer
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }

  Component {
    id: followSettings
    Column {
      width: parent ? parent.width : 0
      spacing: Style.space(8)

      Item {
        width: parent.width
        height: followHead.implicitHeight
        PanelSectionHeader {
          id: followHead
          text: "FOLLOW · " + root.followedIds.length
          foreground: root.fg
          fontFamily: root.fontFamily
          leftPadding: Style.space(4)
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(4)
          anchors.verticalCenter: parent.verticalCenter
          visible: root.followedIds.length < root.sportIds.length
          text: "ALL"
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 0.8
          MouseArea {
            anchors.fill: parent
            anchors.margins: -Style.space(6)
            cursorShape: Qt.PointingHandCursor
            onClicked: root.followAll()
          }
          Accessible.role: Accessible.Button
          Accessible.name: "Follow all sports"
        }
      }

      Text {
        width: parent.width
        leftPadding: Style.space(4)
        rightPadding: Style.space(4)
        wrapMode: Text.WordWrap
        text: "Chips and AUTO only include sports you follow. Keep at least one on."
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Column {
        width: parent.width
        spacing: Style.space(4)
        Repeater {
          model: root.sportCatalog
          Toggle {
            required property var modelData
            width: parent.width
            label: modelData.label
            description: {
              var svc = root.sportService(modelData.id)
              return svc && svc.title ? svc.title : modelData.label
            }
            checked: root.isFollowed(modelData.id)
            foreground: root.fg
            fontFamily: root.fontFamily
            onClicked: root.toggleFollow(modelData.id)
          }
        }
      }
    }
  }

  Component {
    id: overview
    Column {
      spacing: Style.space(12)
      readonly property var event: root.sport.event

      Column {
        width: parent.width
        leftPadding: Style.space(4)
        spacing: Style.space(4)
        Text {
          width: parent.width - Style.space(8)
          text: event ? event.name : ""
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          font.bold: true
          wrapMode: Text.WordWrap
        }
        Text {
          text: event ? [event.venue, event.locality, event.country].filter(function(s) { return s && s !== event.name }).join(" · ") : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.space(16)
          Column {
            spacing: Style.space(2)
            Text {
              text: root.viewedSport === "sumo" ? "NEXT SESSION" : root.viewedSport === "gt" ? "GREEN FLAG" : "NEXT GAME"
              color: root.dimmer
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
            }
            Text {
              text: event ? root.fmtDateLong(event.weekendStartAt || event.startAt) : ""
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              visible: {
                var next = event ? SportsModel.nextSession(event, root.now) : null
                return next && root.hasClock(next)
              }
              text: {
                var next = event ? SportsModel.nextSession(event, root.now) : null
                return next && root.hasClock(next) ? root.fmtTime(next.startAt) + " your time" : ""
              }
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
          Text {
            text: {
              var at = SportsModel.nextAt(event, root.now)
              if (!SportsTime.isInstant(at)) return ""
              return SportsModel.eventIsDateOnly(event) ? root.dayCountdownTo(at) : root.countdownTo(at)
            }
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
        }

        Row {
          visible: root.viewedSport === "gt"
          spacing: Style.space(6)
          Repeater {
            model: [
              { id: "all", label: "ALL" },
              { id: "Europe", label: "EU" },
              { id: "America", label: "AM" },
              { id: "Asia", label: "AS" },
              { id: "Australia", label: "AU" }
            ]
            Rectangle {
              required property var modelData
              implicitWidth: cLab.implicitWidth + Style.space(12)
              implicitHeight: cLab.implicitHeight + Style.space(6)
              radius: Math.max(2, Style.cornerRadius)
              color: root.gtContinent === modelData.id ? Util.alpha(Color.accent, 0.18) : Util.alpha(root.fg, 0.05)
              border.width: root.gtContinent === modelData.id ? 1 : 0
              border.color: Util.alpha(Color.accent, 0.5)
              Text {
                id: cLab
                anchors.centerIn: parent
                text: modelData.label
                color: root.gtContinent === modelData.id ? Color.accent : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: root.gtContinent === modelData.id
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.gtContinent = modelData.id
                  root.persistUi()
                }
              }
            }
          }
        }
      }

      PanelSeparator {
        width: parent.width
        visible: (root.viewedSport === "sumo" ? root.sumo.schedule : (root.viewedSport === "gt" && event && event.sessions ? event.sessions : [])).length > 0
      }
      PanelSectionHeader {
        visible: (root.viewedSport === "sumo" ? root.sumo.schedule : (root.viewedSport === "gt" && event && event.sessions ? event.sessions : [])).length > 0
        text: root.viewedSport === "sumo"
          ? "DAYS · " + root.sumo.daysLeft + " left"
          : "SCHEDULE · " + (event ? root.fmtRange(event.weekendStartAt, event.weekendEndAt) : "")
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        spacing: Style.space(1)
        visible: (root.viewedSport === "sumo" ? root.sumo.schedule : (root.viewedSport === "gt" && event && event.sessions ? event.sessions : [])).length > 0
        Repeater {
          model: root.viewedSport === "sumo" ? root.sumo.schedule : (root.viewedSport === "gt" && event && event.sessions ? event.sessions : [])
          SessionRow {
            required property var modelData
            width: parent.width
            session: modelData
            state: root.stateOf(modelData)
            dayText: root.fmtDay(modelData.startAt)
            timeText: root.hasClock(modelData) ? root.fmtTime(modelData.startAt) : "—"
            countdownText: modelData.dateOnly ? root.dayCountdownTo(modelData.startAt) : root.shortCountdownTo(modelData.startAt)
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
      }

      PanelSeparator { width: parent.width; visible: root.sport.upcoming.length > 0 }
      PanelSectionHeader {
        visible: root.sport.upcoming.length > 0
        text: "UPCOMING"
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.sport.upcoming.length > 0
        Repeater {
          model: root.sport.upcoming
          EventCard {
            required property var modelData
            width: parent.width
            title: modelData.name
            subtitle: (modelData.series || "") + (modelData.continent ? " · " + modelData.continent : "")
            meta: modelData.locality + " · " + root.fmtDate(modelData.weekendStartAt || modelData.startAt)
            countdown: SportsModel.eventIsDateOnly(modelData)
              ? root.dayCountdownTo(modelData.weekendStartAt || modelData.startAt)
              : root.shortCountdownTo(modelData.weekendStartAt || modelData.startAt)
            chipText: modelData.continent || modelData.series || ""
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
      }

      PanelSeparator { width: parent.width; visible: root.sport.recent && root.sport.recent.length > 0 }
      PanelSectionHeader {
        visible: root.sport.recent && root.sport.recent.length > 0
        text: root.viewedSport === "cs" ? "RECENT TIER 1" : "RECENT"
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.sport.recent && root.sport.recent.length > 0
        Repeater {
          model: root.sport.recent || []
          MatchRow {
            required property var modelData
            width: parent.width
            match: modelData
            live: !modelData.finished
            teamColor: CsColors.colorFor(modelData.winnerName || modelData.team1.name)
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
      }

      PanelSeparator {
        width: parent.width
        visible: root.viewedSport === "sumo" && root.sumo.event && root.now >= root.sumo.event.weekendStartAt && root.sumo.yusho.length > 0
      }
      PanelSectionHeader {
        visible: root.viewedSport === "sumo" && root.sumo.event && root.now >= root.sumo.event.weekendStartAt && root.sumo.yusho.length > 0
        text: "YUSHO RACE · " + root.sumo.daysLeft + " days left"
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        visible: root.viewedSport === "sumo" && root.sumo.event && root.now >= root.sumo.event.weekendStartAt && root.sumo.yusho.length > 0
        Repeater {
          model: root.sumo.yusho.slice(0, 8)
          StandingRow {
            required property var modelData
            width: parent.width
            position: modelData.position
            name: modelData.name
            teamName: modelData.heya || modelData.rank || ""
            valueText: modelData.record
            clickable: true
            pinned: SportsModel.matchPin(modelData, root.sumoPinPlayer)
            onClicked: root.setPin("sumo", "player", modelData.name)
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
      }

      PanelSeparator { width: parent.width; visible: root.sport.playerStandings.top.length > 0 }
      PanelSectionHeader {
        visible: root.sport.playerStandings.top.length > 0
        text: root.viewedSport === "cs" ? "PLAYERS" : root.viewedSport === "sumo" ? "MAKUUCHI" : "DRIVERS"
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        visible: root.sport.playerStandings.top.length > 0
        Repeater {
          model: root.sport.playerStandings.top
          StandingRow {
            required property var modelData
            width: parent.width
            position: modelData.position
            name: modelData.name
            code: modelData.code || ""
            teamName: modelData.teamName || modelData.rank || ""
            teamColor: root.viewedSport === "gt" ? GtColors.colorFor(modelData.teamName) : CsColors.colorFor(modelData.teamName || modelData.name)
            valueText: root.viewedSport === "sumo" ? modelData.record
              : root.viewedSport === "cs" ? Number(modelData.points).toFixed(2)
              : String(modelData.points) + " pts"
            noteText: root.viewedSport === "cs" && modelData.adr ? Math.round(modelData.adr) + " ADR" : (modelData.rank || "")
            clickable: true
            pinned: SportsModel.matchPin(modelData, root.pinOf(root.viewedSport, "player"))
            onClicked: root.setPin(root.viewedSport, "player", modelData.name)
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
        StandingRow {
          visible: root.sport.playerStandings.pin !== null
          width: parent.width
          position: root.sport.playerStandings.pin ? root.sport.playerStandings.pin.position : 0
          name: root.sport.playerStandings.pin ? root.sport.playerStandings.pin.name : ""
          teamName: root.sport.playerStandings.pin ? (root.sport.playerStandings.pin.teamName || "") : ""
          valueText: root.sport.playerStandings.pin ? String(root.sport.playerStandings.pin.points) : ""
          noteText: root.sport.playerStandings.gap !== null ? root.sport.playerStandings.gap + " behind leader" : "PINNED"
          pinned: true
          foreground: root.fg
          fontFamily: root.fontFamily
        }
      }

      PanelSeparator { width: parent.width; visible: root.sport.teamStandings.top.length > 0 }
      PanelSectionHeader {
        visible: root.sport.teamStandings.top.length > 0
        text: root.viewedSport === "sumo" ? "HEYA" : "TEAMS"
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        visible: root.sport.teamStandings.top.length > 0
        Repeater {
          model: root.sport.teamStandings.top
          StandingRow {
            required property var modelData
            width: parent.width
            position: modelData.position
            name: modelData.name
            teamName: ""
            showTeam: false
            teamColor: CsColors.colorFor(modelData.name)
            valueText: root.standingValue(modelData)
            noteText: root.viewedSport === "cs" ? (modelData.note || "") : ""
            clickable: true
            pinned: SportsModel.matchPin(modelData, root.pinOf(root.viewedSport, "team"))
            onClicked: root.setPin(root.viewedSport, "team", modelData.name)
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
        StandingRow {
          visible: root.sport.teamStandings.pin !== null
          width: parent.width
          position: root.sport.teamStandings.pin ? root.sport.teamStandings.pin.position : 0
          name: root.sport.teamStandings.pin ? root.sport.teamStandings.pin.name : ""
          showTeam: false
          valueText: root.standingValue(root.sport.teamStandings.pin)
          noteText: root.sport.teamStandings.gap !== null ? root.sport.teamStandings.gap + " behind leader" : "PINNED"
          pinned: true
          foreground: root.fg
          fontFamily: root.fontFamily
        }
      }
    }
  }

  Component {
    id: liveView
    Column {
      spacing: Style.space(10)
      width: parent ? parent.width : 0

      readonly property bool empty: !(root.sport && root.sport.liveMatches && root.sport.liveMatches.length > 0)
        && (root.viewedSport !== "gt" || !root.live.hasData)

      Column {
        width: parent.width
        visible: empty
        spacing: Style.space(8)
        Text {
          width: parent.width
          leftPadding: Style.space(4)
          text: "No " + root.sportTitle + " session is live."
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
        }
        Text {
          width: parent.width
          leftPadding: Style.space(4)
          wrapMode: Text.WordWrap
          text: {
            if (!root.sport.event) return "Nothing is on the calendar."
            var next = SportsModel.nextSession(root.sport.event, root.now)
            if (!next) return root.sport.event.name + " has finished."
            return root.sport.event.name + " · " + next.name + " starts "
              + root.fmtDayTime(next.startAt) + " — in " + root.countdownTo(next.startAt) + "."
          }
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          leftPadding: Style.space(4)
          visible: root.live.liveReason && root.live.liveReason !== ""
          wrapMode: Text.WordWrap
          text: root.live.liveReason
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width
          leftPadding: Style.space(4)
          text: "Turn live mode off to return to the overview."
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Column {
        width: parent.width
        visible: !empty
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: liveTitle.implicitHeight
          Text {
            id: liveTitle
            anchors.left: parent.left
            anchors.leftMargin: Style.space(4)
            text: root.live.sessionName !== "" ? root.live.sessionName : root.sport.event ? root.sport.event.name : "Live"
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          StatusChip {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            text: root.live.statusLabel || "LIVE"
            tone: "live"
            foreground: root.fg
            fontFamily: root.fontFamily
            filled: true
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.viewedSport !== "sumo" && root.viewedSport !== "gt"
          Repeater {
            model: root.sport && root.sport.liveMatches ? root.sport.liveMatches : []
            MatchRow {
              required property var modelData
              width: parent.width
              match: modelData
              live: true
              teamColor: CsColors.colorFor(modelData.team1.name)
              foreground: root.fg
              fontFamily: root.fontFamily
            }
          }
        }

        Column {
          width: parent.width
          visible: root.viewedSport === "sumo"
          Repeater {
            model: root.sumo.torikumi
            BoutRow {
              required property var modelData
              width: parent.width
              bout: modelData
              foreground: root.fg
              fontFamily: root.fontFamily
            }
          }
        }

        Column {
          width: parent.width
          visible: root.viewedSport === "gt"
          Repeater {
            model: root.live.grid
            LiveRow {
              required property var modelData
              width: parent.width
              entry: modelData
              teamColor: GtColors.colorFor(modelData.teamName)
              foreground: root.fg
              fontFamily: root.fontFamily
            }
          }
        }
      }
    }
  }
}
