import QtQuick
import qs.Commons

// One CS match: two teams, map score, event. Colour is decoration only.
Rectangle {
  id: root

  property var match: null
  property color teamColor: Color.accent
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool live: false

  readonly property string mapsText: {
    if (!match || !match.maps || match.maps.length === 0) return ""
    var parts = []
    for (var i = 0; i < match.maps.length; i++) {
      var m = match.maps[i]
      if (!m) continue
      parts.push(String(m.name || "Map") + " " + String(m.team1_score) + "–" + String(m.team2_score))
    }
    return parts.join(" · ")
  }

  implicitHeight: col.implicitHeight + Style.space(12)
  radius: Math.max(2, Style.cornerRadius)
  color: live ? Util.alpha(Color.urgent, 0.10) : Util.alpha(foreground, 0.03)

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Style.space(3)
    radius: width / 2
    color: root.teamColor
  }

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(3)

    Item {
      width: parent.width
      height: Math.max(t1.implicitHeight, s1.implicitHeight)

      Text {
        id: t1
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - s1.implicitWidth - Style.space(12)
        text: root.match && root.match.team1 ? root.match.team1.name : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.match && root.match.winnerName === (root.match.team1 && root.match.team1.name)
        elide: Text.ElideRight
      }
      Text {
        id: s1
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.match && root.match.team1 ? String(root.match.team1.score) : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }

    Item {
      width: parent.width
      height: Math.max(t2.implicitHeight, s2.implicitHeight)

      Text {
        id: t2
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - s2.implicitWidth - Style.space(12)
        text: root.match && root.match.team2 ? root.match.team2.name : ""
        color: Qt.darker(root.foreground, 1.15)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.match && root.match.winnerName === (root.match.team2 && root.match.team2.name)
        elide: Text.ElideRight
      }
      Text {
        id: s2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.match && root.match.team2 ? String(root.match.team2.score) : ""
        color: Qt.darker(root.foreground, 1.15)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }

    Text {
      width: parent.width
      visible: root.mapsText !== ""
      text: root.mapsText
      color: Qt.darker(root.foreground, 1.8)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: {
        if (!root.match) return ""
        var bits = []
        if (root.live) bits.push("LIVE")
        if (root.match.event) bits.push(root.match.event)
        if (root.match.bestOf > 1) bits.push("BO" + root.match.bestOf)
        return bits.join(" · ")
      }
      color: root.live ? Color.urgent : Qt.darker(root.foreground, 1.9)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  Accessible.role: Accessible.ListItem
  Accessible.name: {
    if (!root.match || !root.match.team1) return "Match"
    return root.match.team1.name + " " + root.match.team1.score + " to "
      + root.match.team2.score + " " + root.match.team2.name
      + (root.match.event ? ", " + root.match.event : "")
  }
}
