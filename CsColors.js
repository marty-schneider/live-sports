.pragma library

.import "SportsModel.js" as SportsModel

var TEAM_COLORS = {
  "vitality": "#fff200",
  "spirit": "#f7a31c",
  "natus vincere": "#ffe500",
  "navi": "#ffe500",
  "falcons": "#046a38",
  "mouz": "#e10600",
  "the mongolz": "#005baa",
  "mongolz": "#005baa",
  "furia": "#000000",
  "g2": "#000000",
  "faze": "#e03c31",
  "liquid": "#0a1e3c",
  "astralis": "#ef3340",
  "heroic": "#d6001c",
  "complexity": "#1d1d1b",
  "aurora": "#7c4dff",
  "virtus.pro": "#ff6a00",
  "vp": "#ff6a00",
  "3dmax": "#00a3e0",
  "legacy": "#c4a35a",
  "mibr": "#ffcc00",
  "pain": "#e30613",
  "tyloo": "#c8102e",
  "flyquest": "#00a651"
}

function colorFor(name) {
  var key = SportsModel.str(name).toLowerCase()
  if (Object.prototype.hasOwnProperty.call(TEAM_COLORS, key)) return TEAM_COLORS[key]
  return SportsModel.hashColor(key || "cs")
}

if (typeof module !== "undefined") {
  module.exports = { TEAM_COLORS: TEAM_COLORS, colorFor: colorFor }
}
