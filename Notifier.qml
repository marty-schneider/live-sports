import QtQuick
import Quickshell
import Quickshell.Io
import "SportsTime.js" as SportsTime
import "SportsModel.js" as SportsModel

QtObject {
  id: root

  property double now: Date.now()
  property bool enabled: true
  property var events: []
  property var timeContext: ({ correctionMs: 0, hour12: false })
  property string leadMinutes: "30,15"
  property var sessionGroups: ["Race", "Match", "Makuuchi", "Qualifying", "Event"]
  property string appName: "Live Sports"

  property var fired: ({})
  property bool stateLoaded: false
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/live-sports/notified.json"

  readonly property var leads: {
    var out = []
    var parts = String(leadMinutes || "").split(",")
    for (var i = 0; i < parts.length; i++) {
      var n = parseInt(String(parts[i]).replace(/^\s+|\s+$/g, ""), 10)
      if (isFinite(n) && n > 0 && out.indexOf(n) === -1) out.push(n)
    }
    out.sort(function(a, b) { return b - a })
    return out
  }

  function wantsSession(session) {
    if (!session) return false
    return sessionGroups.indexOf(session.group) !== -1
  }

  function pendingSlots() {
    var slots = []
    var list = Array.isArray(events) ? events : []
    for (var e = 0; e < list.length; e++) {
      var event = list[e]
      if (!event || !event.sessions) continue
      for (var i = 0; i < event.sessions.length; i++) {
        var session = event.sessions[i]
        if (!wantsSession(session) || session.dateOnly) continue
        var prefix = event.sport === "cs" ? "CS" : event.sport === "sumo" ? "Sumo" : "GT"
        for (var l = 0; l < leads.length; l++) {
          var lead = leads[l]
          slots.push({
            at: session.startAt - lead * SportsTime.MINUTE,
            key: event.id + "-" + session.key + "-t" + lead,
            title: prefix + " · " + session.name + " in " + lead + "m",
            body: event.name
          })
        }
        slots.push({
          at: session.startAt,
          key: event.id + "-" + session.key + "-start",
          title: prefix + " · " + session.name + " has started",
          body: event.name
        })
      }
    }
    return slots
  }

  function tick() {
    if (!enabled || !stateLoaded) return
    var slots = pendingSlots()
    var changed = false
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i]
      if (slot.key === "" || fired[slot.key]) continue
      if (now < slot.at) continue
      var overdue = now - slot.at > 15 * SportsTime.MINUTE
      if (!overdue) send(slot.title, slot.body)
      fired[slot.key] = slot.at
      changed = true
    }
    if (changed) persist()
  }

  function send(title, body) {
    notifyProc.command = ["omarchy-notification-send", "--app-name", appName,
      SportsModel.notificationArg(title, appName),
      SportsModel.notificationArg(body, "")]
    notifyProc.running = true
  }

  function persist() {
    var kept = {}
    for (var key in fired) {
      if (now - fired[key] < 14 * SportsTime.DAY) kept[key] = fired[key]
    }
    fired = kept
    stateFile.setText(JSON.stringify({ version: 1, fired: kept }) + "\n")
  }

  function loadState(raw) {
    var parsed = SportsModel.safeParse(raw)
    fired = parsed && parsed.fired && typeof parsed.fired === "object" ? parsed.fired : ({})
    stateLoaded = true
  }

  property FileView stateFile: FileView {
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
    onLoadFailed: root.loadState("")
  }

  property Process notifyProc: Process {}

  property Process mkdirProc: Process {
    running: true
    command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/omarchy/live-sports"]
    onExited: stateFile.reload()
  }

  onNowChanged: tick()
}
