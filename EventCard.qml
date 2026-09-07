import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""
  property string meta: ""
  property string countdown: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  implicitHeight: col.implicitHeight + Style.space(12)
  radius: Math.max(2, Style.cornerRadius)
  color: Util.alpha(foreground, 0.04)

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(3)

    Text {
      width: parent.width
      text: root.title
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      elide: Text.ElideRight
    }
    Text {
      width: parent.width
      visible: root.subtitle !== ""
      text: root.subtitle
      color: Qt.darker(root.foreground, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
    Row {
      width: parent.width
      spacing: Style.space(10)
      Text {
        text: root.meta
        color: Qt.darker(root.foreground, 1.8)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        visible: root.countdown !== ""
        text: root.countdown
        color: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }

  Accessible.role: Accessible.ListItem
  Accessible.name: root.title + ", " + root.subtitle + ", " + root.meta
}
