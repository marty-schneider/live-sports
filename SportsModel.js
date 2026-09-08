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
    if (list[i] && list[i].favoriteLive) return list[i].id
  }
  for (var j = 0; j < list.length; j++) {
    if (list[j] && list[j].live) return list[j].id
  }
  var bestId = null
  var bestAt = null
  for (var k = 0; k < list.length; k++) {
    var c = list[k]
    if (!c) continue
    var at = SportsTime.isInstant(c.favoriteNextAt) ? c.favoriteNextAt : c.nextAt
    if (!SportsTime.isInstant(at)) continue
    if (bestAt === null || at < bestAt) {
      bestAt = at
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

function nameMatches(value, query) {
  var q = str(query).replace(/^\s+|\s+$/g, "").toLowerCase()
  var v = str(value).replace(/^\s+|\s+$/g, "").toLowerCase()
  if (q === "" || v === "") return false
  if (v === q) return true
  if (q.length >= 4 && v.length >= 4 && (v.indexOf(q) !== -1 || q.indexOf(v) !== -1)) return true
  return false
}

function involvesTeam(obj, names) {
  if (!obj) return false
  var want = arrayOf(names)
  if (want.length === 0) return false
  var fields = [obj.name, obj.winnerName, obj.teamName, obj.heya, obj.team1Name, obj.team2Name]
  if (obj.team1) fields.push(obj.team1.name, obj.team1.code)
  if (obj.team2) fields.push(obj.team2.name, obj.team2.code)
  for (var i = 0; i < want.length; i++) {
    for (var f = 0; f < fields.length; f++) {
      if (nameMatches(fields[f], want[i])) return true
    }
  }
  return false
}

function favoritesOf(map, sportId) {
  if (!map || typeof map !== "object") return []
  return arrayOf(map[sportId])
}

function namedIn(row, names) {
  var want = arrayOf(names)
  if (!row) return false
  for (var i = 0; i < want.length; i++) {
    if (nameMatches(row.name, want[i]) || nameMatches(row.shikona, want[i])) return true
  }
  return false
}

function isFavorite(map, sportId, name) {
  return namedIn({ name: name }, favoritesOf(map, sportId))
}

function pruneFavorites(map, sportId, dropNames) {
  var next = {}
  var src = map && typeof map === "object" ? map : {}
  for (var k in src) next[k] = arrayOf(src[k]).slice()
  var drop = arrayOf(dropNames)
  var list = arrayOf(next[sportId])
  var kept = []
  for (var i = 0; i < list.length; i++) {
    var skip = false
    for (var d = 0; d < drop.length; d++) {
      if (str(list[i]).toLowerCase() === str(drop[d]).toLowerCase()) skip = true
    }
    if (!skip) kept.push(list[i])
  }
  next[sportId] = kept
  return next
}

function toggleFavorite(map, sportId, name) {
  var next = {}
  var src = map && typeof map === "object" ? map : {}
  for (var k in src) next[k] = arrayOf(src[k]).slice()
  var id = str(sportId)
  var value = str(name).replace(/^\s+|\s+$/g, "")
  if (id === "" || value === "") return next
  var list = arrayOf(next[id])
  var at = -1
  for (var i = 0; i < list.length; i++) {
    if (str(list[i]).toLowerCase() === value.toLowerCase()) { at = i; break }
  }
  if (at >= 0) {
    var kept = []
    for (var j = 0; j < list.length; j++) if (j !== at) kept.push(list[j])
    next[id] = kept
  } else {
    list.push(value)
    next[id] = list
  }
  return next
}

function seedFavorites(map, seeds) {
  var next = {}
  var src = map && typeof map === "object" ? map : {}
  for (var k in src) next[k] = arrayOf(src[k]).slice()
  var rows = arrayOf(seeds)
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row || !row.sport || !row.name) continue
    if (favoritesOf(next, row.sport).length > 0) continue
    next[row.sport] = [str(row.name)]
  }
  return next
}

function pickTrackedEvent(events, names, nowMs) {
  var list = arrayOf(events)
  var want = arrayOf(names)
  if (want.length === 0) return null
  var live = null
  var next = null
  for (var i = 0; i < list.length; i++) {
    var ev = list[i]
    if (!involvesTeam(ev, want)) continue
    var start = ev.startAt
    var end = ev.endAt || ev.weekendEndAt
    if (SportsTime.isInstant(start) && SportsTime.isInstant(end) && nowMs >= start && nowMs < end) {
      live = ev
      break
    }
    if (SportsTime.isInstant(start) && start > nowMs && !next) next = ev
  }
  return live || next
}

function anyFavoriteLive(matches, names) {
  var list = arrayOf(matches)
  var want = arrayOf(names)
  if (want.length === 0) return false
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].live && involvesTeam(list[i], want)) return true
  }
  return false
}

function nextFavoriteMatch(matches, names, nowMs) {
  var list = arrayOf(matches)
  var want = arrayOf(names)
  if (want.length === 0) return null
  var live = null
  var next = null
  var recent = null
  for (var i = 0; i < list.length; i++) {
    var m = list[i]
    if (!involvesTeam(m, want)) continue
    if (m.live) { live = m; break }
    if (!m.finished && SportsTime.isInstant(m.startAt) && m.startAt > nowMs) {
      if (!next || m.startAt < next.startAt) next = m
    } else if (m.finished && SportsTime.isInstant(m.startAt)) {
      if (!recent || m.startAt > recent.startAt) recent = m
    }
  }
  return live || next || recent
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

function standingsWithFavorites(standings, topCount, names) {
  var list = Array.isArray(standings) ? standings.slice() : []
  var top = list.slice(0, topCount || 5)
  var extras = []
  var want = arrayOf(names)
  for (var i = 0; i < list.length; i++) {
    if (!namedIn(list[i], want)) continue
    var inTop = false
    for (var t = 0; t < top.length; t++) {
      if (top[t] === list[i] || (top[t].id && list[i].id && top[t].id === list[i].id) || top[t].name === list[i].name)
        inTop = true
    }
    if (!inTop) extras.push(list[i])
  }
  return { top: top, extras: extras, pin: extras[0] || null, pinInTop: extras.length === 0 && want.length > 0, leader: list[0] || null, gap: null }
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
    nameMatches: nameMatches,
    involvesTeam: involvesTeam,
    favoritesOf: favoritesOf,
    isFavorite: isFavorite,
    namedIn: namedIn,
    pruneFavorites: pruneFavorites,
    toggleFavorite: toggleFavorite,
    seedFavorites: seedFavorites,
    pickTrackedEvent: pickTrackedEvent,
    anyFavoriteLive: anyFavoriteLive,
    nextFavoriteMatch: nextFavoriteMatch,
    standingsWithFavorites: standingsWithFavorites,
    standingsWithPin: standingsWithPin,
    hashColor: hashColor
  }
}
