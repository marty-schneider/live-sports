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
  readonly property string defaultSport: String(setting("defaultSport", "cs"))
  readonly property string csHighlightPlayer: String(setting("csHighlightPlayer", "donk"))
  readonly property string csHighlightTeam: String(setting("csHighlightTeam", "Spirit"))
  readonly property string sumoHighlightPlayer: String(setting("sumoHighlightPlayer", "Onosato"))
  readonly property string sumoHighlightTeam: String(setting("sumoHighlightTeam", "Yokozuna"))
  readonly property string gtHighlightPlayer: String(setting("gtHighlightPlayer", ""))
  readonly property string gtHighlightTeam: String(setting("gtHighlightTeam", "Mercedes"))

  property string sportId: "cs"
  property string gtContinent: "all"
  readonly property var sports: ["cs", "sumo", "gt"]

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
  function agoOf(at) { return SportsTime.agoText(at, now) }
  function stateOf(session) { return SportsModel.sessionState(session, now) }

  property TimeService timeSvc: TimeService {
    hour12: root.hour12
    fastTick: root.opened || root.liveMode
  }

  property CsService cs: CsService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.csHighlightPlayer
    highlightTeam: root.csHighlightTeam
  }
  property SumoService sumo: SumoService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.sumoHighlightPlayer
    highlightTeam: root.sumoHighlightTeam
  }
  property GtService gt: GtService {
    now: root.now
    refreshMinutes: root.refreshMinutes
    highlightPlayer: root.gtHighlightPlayer
    highlightTeam: root.gtHighlightTeam
    continentFilter: root.gtContinent
  }

  readonly property var sport: sportId === "sumo" ? sumo : sportId === "gt" ? gt : cs
  readonly property string sportLabel: sportId === "sumo" ? "SUMO" : sportId === "gt" ? "GT" : "CS"
  readonly property string sportTitle: sportId === "sumo" ? "Grand Sumo" : sportId === "gt" ? "GT World Challenge" : "Counter-Strike"

  property CsLiveService csLive: CsLiveService {
    now: root.now
    enabled: root.liveMode && root.sportId === "cs"
    refreshSeconds: root.liveRefreshSec
    scheduledSession: root.sportId === "cs" ? root.sport.liveSession : null
    matches: root.cs.matches
  }
  property SumoLiveService sumoLive: SumoLiveService {
    now: root.now
    enabled: root.liveMode && root.sportId === "sumo"
    scheduledSession: root.sportId === "sumo" ? root.sport.liveSession : null
    bouts: root.sumo.torikumi
  }
  property GtLiveService gtLive: GtLiveService {
    now: root.now
    enabled: root.liveMode && root.sportId === "gt"
    refreshSeconds: root.liveRefreshSec
    scheduledSession: root.sportId === "gt" ? root.sport.liveSession : null
  }

  readonly property var live: sportId === "sumo" ? sumoLive : sportId === "gt" ? gtLive : csLive

  property Notifier notifier: Notifier {
    now: root.now
    enabled: root.notificationsEnabled
    events: (cs.event ? [cs.event] : []).concat(sumo.event ? [sumo.event] : []).concat(gt.event ? [gt.event] : [])
    timeContext: root.timeCtx
    leadMinutes: root.notifyLeadMinutes
  }

  property string liveOverride: ""
  readonly property bool autoLiveActive: autoLive && sport.liveSession !== null
  readonly property bool liveMode: liveOverride === "on" ? true : liveOverride === "off" ? false : autoLiveActive

  function toggleLive() { liveOverride = liveMode ? "off" : "on" }
  onAutoLiveActiveChanged: liveOverride = ""
  onSportIdChanged: liveOverride = ""

  function selectSport(id) {
    if (sports.indexOf(id) < 0) return
    sportId = id
    persistUi()
  }

  function cycleSport(delta) {
    var i = sports.indexOf(sportId)
    if (i < 0) i = 0
    selectSport(sports[(i + delta + sports.length) % sports.length])
  }

  function persistUi() {
    uiFile.setText(JSON.stringify({ sportId: sportId, gtContinent: gtContinent }) + "\n")
  }

  function loadUi(raw) {
    var parsed = SportsModel.safeParse(raw)
    if (parsed && sports.indexOf(parsed.sportId) >= 0) sportId = parsed.sportId
    else if (sports.indexOf(defaultSport) >= 0) sportId = defaultSport
    if (parsed && parsed.gtContinent) gtContinent = parsed.gtContinent
  }

  property FileView uiFile: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/sports-tracker/ui.json"
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadUi(text())
    onLoadFailed: root.loadUi("")
  }

  readonly property string label: {
    if (!sport.loaded) return sport.failed ? sportLabel + " —" : sportLabel + " ⋯"
    if (sport.offSeason) return sportLabel + " OFF"
    if (sport.liveSession) return sportLabel + " LIVE"
    var next = sport.event ? SportsModel.nextSession(sport.event, now) : null
    if (!next) return sportLabel + " —"
    return sportLabel + " " + shortCountdownTo(next.startAt)
  }

  readonly property string tooltipText: {
    if (!sport.loaded) return sportTitle + " — loading"
    if (sport.offSeason) return sportTitle + " — off season"
    if (sport.liveSession && sport.event)
      return sport.liveSession.name + " is live — " + sport.event.name
    var next = sport.event ? SportsModel.nextSession(sport.event, now) : null
    if (!next || !sport.event) return sportTitle
    return sport.event.name + " · " + next.name + " " + fmtDayTime(next.startAt)
  }

  readonly property bool sessionLive: sport.liveSession !== null

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
      if (id === "cs" || id === "sumo" || id === "gt") root.selectSport(id)
      else if (id === "next") root.cycleSport(1)
      else if (id === "prev") root.cycleSport(-1)
      return root.sportId
    }
    function live(mode: string): string {
      if (mode === "on" || mode === "off") root.liveOverride = mode
      else if (mode === "auto") root.liveOverride = ""
      else root.toggleLive()
      return root.liveMode ? "on" : "off"
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
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.toggleLive()
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.cycleSport(dx)
        if (dy === 0) return
        scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, scroll.contentY + dy * Style.space(48)))
      }
      onTextKey: function(text) {
        if (text === "r") root.refresh()
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
            height: Math.max(switcher.implicitHeight, liveToggle.implicitHeight)

            Row {
              id: switcher
              anchors.left: parent.left
              anchors.leftMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(6)

              Repeater {
                model: [
                  { id: "cs", label: "CS2" },
                  { id: "sumo", label: "SUMO" },
                  { id: "gt", label: "GT" }
                ]
                Rectangle {
                  required property var modelData
                  implicitWidth: chipLabel.implicitWidth + Style.space(16)
                  implicitHeight: chipLabel.implicitHeight + Style.space(8)
                  radius: Math.max(2, Style.cornerRadius)
                  color: root.sportId === modelData.id ? Util.alpha(Color.accent, 0.18) : Util.alpha(root.fg, 0.05)
                  border.width: root.sportId === modelData.id ? 1 : 0
                  border.color: Util.alpha(Color.accent, 0.5)
                  Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    color: root.sportId === modelData.id ? Color.accent : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: root.sportId === modelData.id
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
                  Accessible.checked: root.sportId === modelData.id
                }
              }
            }

            Rectangle {
              id: liveToggle
              anchors.right: parent.right
              anchors.rightMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
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

          Row {
            leftPadding: Style.space(4)
            spacing: Style.space(10)
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
            visible: !root.sport.loaded
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
            visible: root.sport.loaded && root.sport.offSeason
            text: "Nothing scheduled. Waiting for the next " + root.sportTitle + " event."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            leftPadding: Style.space(4)
            wrapMode: Text.WordWrap
          }

          Loader {
            width: parent.width
            active: root.liveMode && root.sport.loaded
            visible: active
            sourceComponent: liveView
          }

          Loader {
            width: parent.width
            active: !root.liveMode && root.sport.loaded && !root.sport.offSeason
            visible: active
            sourceComponent: overview
          }

          PanelSeparator { width: parent.width; visible: root.sport.loaded }

          Item {
            width: parent.width
            height: footerLeft.implicitHeight
            visible: root.sport.loaded
            Column {
              id: footerLeft
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
              text: "1 2 3 sports · enter live · r refresh · esc close"
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
              text: root.sportId === "sumo" ? "NEXT SESSION" : root.sportId === "cs" ? "NEXT MATCH WINDOW" : "GREEN FLAG"
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
              text: {
                var next = event ? SportsModel.nextSession(event, root.now) : null
                if (next) return root.fmtTime(next.startAt) + " your time"
                return event ? root.fmtTime(event.startAt) + " your time" : ""
              }
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
          Text {
            text: {
              var next = event ? SportsModel.nextSession(event, root.now) : null
              var at = next ? next.startAt : (event ? event.weekendStartAt : null)
              return root.countdownTo(at)
            }
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
        }

        Row {
          visible: root.sportId === "gt"
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

      PanelSeparator { width: parent.width }
      PanelSectionHeader {
        text: "SCHEDULE · " + (event ? root.fmtRange(event.weekendStartAt, event.weekendEndAt) : "")
        foreground: root.fg
        fontFamily: root.fontFamily
        leftPadding: Style.space(4)
      }
      Column {
        width: parent.width
        spacing: Style.space(1)
        Repeater {
          model: event ? event.sessions : []
          SessionRow {
            required property var modelData
            width: parent.width
            session: modelData
            state: root.stateOf(modelData)
            dayText: root.fmtDay(modelData.startAt)
            timeText: modelData.dateOnly ? "—" : root.fmtTime(modelData.startAt)
            countdownText: root.shortCountdownTo(modelData.startAt)
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
            countdown: root.shortCountdownTo(modelData.weekendStartAt || modelData.startAt)
            chipText: modelData.continent || modelData.series || ""
            foreground: root.fg
            fontFamily: root.fontFamily
          }
        }
      }

      PanelSeparator { width: parent.width; visible: root.sport.recent && root.sport.recent.length > 0 }
      PanelSectionHeader {
        visible: root.sport.recent && root.sport.recent.length > 0
        text: "RECENT TIER 1"
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

      PanelSeparator { width: parent.width; visible: root.sport.playerStandings.top.length > 0 }
      PanelSectionHeader {
        visible: root.sport.playerStandings.top.length > 0
        text: root.sportId === "cs" ? "PLAYERS" : root.sportId === "sumo" ? "MAKUUCHI" : "DRIVERS"
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
            teamColor: root.sportId === "gt" ? GtColors.colorFor(modelData.teamName) : CsColors.colorFor(modelData.teamName || modelData.name)
            valueText: root.sportId === "sumo" ? modelData.record
              : root.sportId === "cs" ? Number(modelData.points).toFixed(2)
              : String(modelData.points) + " pts"
            noteText: root.sportId === "cs" && modelData.adr ? Math.round(modelData.adr) + " ADR" : (modelData.rank || "")
            pinned: SportsModel.matchPin(modelData, root.sportId === "sumo" ? root.sumoHighlightPlayer : root.sportId === "gt" ? root.gtHighlightPlayer : root.csHighlightPlayer)
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
        text: root.sportId === "sumo" ? "HEYA" : "TEAMS"
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
            valueText: root.sportId === "cs" ? String(modelData.points) + " pts" : String(modelData.points)
            noteText: modelData.note || ""
            pinned: SportsModel.matchPin(modelData, root.sportId === "sumo" ? root.sumoHighlightTeam : root.sportId === "gt" ? root.gtHighlightTeam : root.csHighlightTeam)
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
          valueText: root.sport.teamStandings.pin ? String(root.sport.teamStandings.pin.points) : ""
          noteText: root.sport.teamStandings.gap !== null ? root.sport.teamStandings.gap + " pts behind leader" : "PINNED"
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

      readonly property bool empty: {
        if (root.sportId === "cs") return root.cs.liveMatches.length === 0 && !root.live.hasData
        if (root.sportId === "sumo") return root.sumo.torikumi.length === 0
        return !root.live.hasData
      }

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
          visible: root.sportId === "cs"
          Repeater {
            model: root.cs.liveMatches.length > 0 ? root.cs.liveMatches : []
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
          visible: root.sportId === "sumo"
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
          visible: root.sportId === "gt"
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
