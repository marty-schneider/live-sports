.pragma library

.import "SportsModel.js" as SportsModel

var TEAM_COLORS = {
  "mercedes": "#27f4d2",
  "mercedes-amg": "#27f4d2",
  "ferrari": "#e8002d",
  "porsche": "#d5001c",
  "lamborghini": "#b6a269",
  "audi": "#bb0a30",
  "bmw": "#1c69d4",
  "mclaren": "#ff8000",
  "aston martin": "#229971",
  "lexus": "#5b8c2a",
  "honda": "#e40521",
  "nissan": "#c3002f",
  "ford": "#003478",
  "chevrolet": "#d4a017"
}

function colorFor(name) {
  var key = SportsModel.str(name).toLowerCase()
  for (var k in TEAM_COLORS) {
    if (Object.prototype.hasOwnProperty.call(TEAM_COLORS, k) && key.indexOf(k) !== -1)
      return TEAM_COLORS[k]
  }
  return SportsModel.hashColor(key || "gt")
}

if (typeof module !== "undefined") {
  module.exports = { TEAM_COLORS: TEAM_COLORS, colorFor: colorFor }
}
