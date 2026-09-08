.pragma library

.import "SportsTime.js" as SportsTime

// Shared shapes and helpers for every sport.
//
// Nothing here touches the network. Every function is total: a bad payload
// yields an empty list or null, never an exception.

function num(value, fallback) {
  var n = parseFloat(String(value))
  return isFinite(n) ? n : (fallback === undefined ? null : fallback)
}

function int(value, fallback) {
  var n = parseInt(String(value), 10)
  return isFinite(n) ? n : (fallback === undefined ? null : fallback)
}

function str(value) {
  return value === undefined || value === null ? "" : String(value)
}

function notificationArg(value, fallback) {
  var text = str(value)
    .replace(/[\u0000-\u001f\u007f]+/g, " ")
    .replace(/^[\s-]+/, "")
    .replace(/\s+$/, "")
  if (text.length > 160) text = text.slice(0, 159) + "\u2026"
  return text === "" ? str(fallback) : text
}

function safeParse(raw) {
  try {
    var parsed = JSON.parse(String(raw || ""))
    return parsed && typeof parsed === "object" ? parsed : null
  } catch (e) {
    return null
  }
}

function arrayOf(value) {
  return Array.isArray(value) ? value : []
}

function makeSession(spec, startAt, endAt, dateOnly) {
  return {
    key: spec.key,
    short: spec.short,
    name: spec.name,
    group: spec.group || "Session",
    startAt: startAt,
    endAt: SportsTime.isInstant(endAt) ? endAt : (SportsTime.isInstant(startAt) ? startAt + (spec.durationMin || 60) * SportsTime.MINUTE : null),
    dateOnly: dateOnly === true
  }
}

function sessionState(session, nowMs) {
  if (!session || !SportsTime.isInstant(session.startAt)) return "upcoming"
  if (session.dateOnly) return nowMs > session.startAt + SportsTime.DAY ? "done" : "upcoming"
  var endAt = SportsTime.isInstant(session.endAt) ? session.endAt : session.startAt + SportsTime.HOUR
  if (nowMs >= endAt) return "done"
  if (nowMs >= session.startAt) return "live"
  if (session.startAt - nowMs <= SportsTime.HOUR) return "soon"
  return "upcoming"
}

function liveSession(event, nowMs) {
  if (!event || !event.sessions) return null
  for (var i = 0; i < event.sessions.length; i++) {
    if (sessionState(event.sessions[i], nowMs) === "live") return event.sessions[i]
  }
  return null
}

function nextSession(event, nowMs) {
  if (!event || !event.sessions) return null
  for (var i = 0; i < event.sessions.length; i++) {
    if (event.sessions[i].startAt > nowMs) return event.sessions[i]
  }
  return null
}

function hasClock(session) {
  return session && session.dateOnly !== true && SportsTime.isInstant(session.startAt)
}

function eventIsDateOnly(event) {
  if (!event) return true
  if (event.dateOnly === true) return true
  var sessions = arrayOf(event.sessions)
  if (sessions.length === 0) return true
  for (var i = 0; i < sessions.length; i++) {
    if (hasClock(sessions[i])) return false
  }
  return true
}

function nextAt(event, nowMs) {
  var timed = nextSession(event, nowMs)
  if (timed && hasClock(timed)) return timed.startAt
  if (timed) return timed.startAt
  if (event && SportsTime.isInstant(event.weekendStartAt) && event.weekendStartAt > nowMs)
    return event.weekendStartAt
  return null
}

function pickAutoSport(candidates, nowMs) {
  var list = arrayOf(candidates)
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].live) return list[i].id
  }
  var bestId = null
  var bestAt = null
  for (var j = 0; j < list.length; j++) {
    var c = list[j]
    if (!c || !SportsTime.isInstant(c.nextAt)) continue
    if (bestAt === null || c.nextAt < bestAt) {
      bestAt = c.nextAt
      bestId = c.id
    }
  }
  return bestId || (list[0] ? list[0].id : "cs")
}

function normalizeFollowed(selected, allIds) {
  var all = arrayOf(allIds)
  var want = arrayOf(selected)
  if (want.length === 0) return all.slice()
  var out = []
  for (var i = 0; i < all.length; i++) {
    if (want.indexOf(all[i]) >= 0) out.push(all[i])
  }
  return out.length > 0 ? out : all.slice()
}

function toggleFollowed(selected, id, allIds) {
  var all = arrayOf(allIds)
  if (all.indexOf(id) < 0) return normalizeFollowed(selected, all)
  var current = normalizeFollowed(selected, all)
  var at = current.indexOf(id)
  if (at >= 0) {
    if (current.length === 1) return current
    var next = []
    for (var i = 0; i < current.length; i++) {
      if (i !== at) next.push(current[i])
    }
    return next
  }
  current.push(id)
  return normalizeFollowed(current, all)
}

function weekendState(event, nowMs, liveLabel) {
  if (!event) return { label: "OFF SEASON", kind: "idle" }
  var live = liveSession(event, nowMs)
  if (live) return { label: (liveLabel || live.short) + " LIVE", kind: "live", session: live }

  var last = event.sessions && event.sessions.length > 0 ? event.sessions[event.sessions.length - 1] : null
  var endAt = event.weekendEndAt || event.endAt || (last && last.endAt)
  if (SportsTime.isInstant(endAt) && nowMs >= endAt + SportsTime.DAY)
    return { label: "FINISHED", kind: "finished", session: last }

  var soon = null
  if (event.sessions) {
    for (var i = 0; i < event.sessions.length; i++) {
      if (sessionState(event.sessions[i], nowMs) === "soon") { soon = event.sessions[i]; break }
    }
  }
  if (soon) return { label: soon.short + " STARTS SOON", kind: "soon", session: soon }
  if (SportsTime.isInstant(event.weekendStartAt) && nowMs >= event.weekendStartAt)
    return { label: "UNDER WAY", kind: "weekend", session: nextSession(event, nowMs) }
  return { label: "NEXT", kind: "upcoming", session: nextSession(event, nowMs) || last }
}

function currentEventIndex(events, nowMs) {
  if (!Array.isArray(events) || events.length === 0) return -1
  for (var i = 0; i < events.length; i++) {
    var endAt = events[i].weekendEndAt || events[i].endAt || events[i].startAt
    if (SportsTime.isInstant(endAt) && nowMs < endAt + SportsTime.DAY) return i
  }
  return -1
}

function upcomingEvents(events, currentIndex, count) {
  if (!Array.isArray(events) || currentIndex < 0) return []
  return events.slice(currentIndex + 1, currentIndex + 1 + (count || 3))
}

function matchPin(row, query) {
  var q = str(query).replace(/^\s+|\s+$/g, "").toLowerCase()
  if (q === "" || !row) return false
  var fields = [row.id, row.name, row.code, row.familyName, row.fullName, row.teamName, row.teamId, row.shikona, row.heya]
  for (var i = 0; i < fields.length; i++) {
    if (str(fields[i]).toLowerCase() === q) return true
    if (q.length >= 3 && str(fields[i]).toLowerCase().indexOf(q) !== -1) return true
  }
  return false
}

function standingsWithPin(standings, topCount, pinQuery) {
  var list = Array.isArray(standings) ? standings.slice() : []
  var top = list.slice(0, topCount || 5)
  var leader = list.length > 0 ? list[0] : null
  var pin = null
  if (str(pinQuery) !== "") {
    for (var i = 0; i < list.length; i++) {
      if (matchPin(list[i], pinQuery)) { pin = list[i]; break }
    }
  }
  var pinInTop = false
  if (pin) {
    for (var t = 0; t < top.length; t++) {
      if (top[t] === pin || (top[t].id && pin.id && top[t].id === pin.id)) pinInTop = true
    }
  }
  var gap = null
  if (pin && leader) {
    var pinPts = num(pin.points, 0) || 0
    var leadPts = num(leader.points, 0) || 0
    gap = leadPts - pinPts
  }
  return {
    top: top,
    pin: pinInTop ? null : pin,
    pinInTop: pinInTop,
    leader: leader,
    gap: gap
  }
}

function hashColor(key) {
  var s = str(key)
  var h = 0
  for (var i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0
  var hue = Math.abs(h) % 360
  return "hsl(" + hue + ", 55%, 48%)"
}

if (typeof module !== "undefined") {
  module.exports = {
    num: num, int: int, str: str,
    notificationArg: notificationArg,
    safeParse: safeParse,
    arrayOf: arrayOf,
    makeSession: makeSession,
    sessionState: sessionState,
    liveSession: liveSession,
    nextSession: nextSession,
    hasClock: hasClock,
    eventIsDateOnly: eventIsDateOnly,
    nextAt: nextAt,
    pickAutoSport: pickAutoSport,
    normalizeFollowed: normalizeFollowed,
    toggleFollowed: toggleFollowed,
    weekendState: weekendState,
    currentEventIndex: currentEventIndex,
    upcomingEvents: upcomingEvents,
    matchPin: matchPin,
    standingsWithPin: standingsWithPin,
    hashColor: hashColor
  }
}
