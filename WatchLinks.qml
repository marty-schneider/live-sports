import QtQuick
import qs.Commons

Item {
  id: root

  property var info: null
  property var broadcasts: []
  property string infoUrl: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal openUrl(string url)

  readonly property string onAir: {
    var list = Array.isArray(broadcasts) ? broadcasts : []
    var parts = []
    for (var i = 0; i < list.length; i++) {
      if (list[i]) parts.push(String(list[i]))
    }
    return parts.join(" · ")
  }
  readonly property string watchUrl: info && info.watch ? String(info.watch.url || "") : ""
  readonly property string updatesUrl: infoUrl !== "" ? infoUrl : (info && info.updates ? String(info.updates.url || "") : "")

  visible: onAir !== "" || watchUrl !== "" || updatesUrl !== ""
  implicitHeight: visible ? flow.implicitHeight : 0
  implicitWidth: parent ? parent.width : flow.implicitWidth

  property real leftPadding: 0

  Flow {
    id: flow
    x: root.leftPadding
    width: Math.max(0, root.width - root.leftPadding)
    spacing: Style.space(14)

    Text {
      visible: root.onAir !== ""
      text: "On " + root.onAir
      color: Qt.darker(root.foreground, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      visible: root.watchUrl !== ""
      text: "WHERE TO WATCH"
      color: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.6
      MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openUrl(root.watchUrl)
      }
      Accessible.role: Accessible.Button
      Accessible.name: "Where to watch"
    }

    Text {
      visible: root.updatesUrl !== ""
      text: "LIVE UPDATES"
      color: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.6
      MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openUrl(root.updatesUrl)
      }
      Accessible.role: Accessible.Button
      Accessible.name: "Live updates"
    }
  }
}
