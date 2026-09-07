import QtQuick
import qs.Commons

// One Makuuchi bout: East vs West, winner and kimarite when the bout is in.
Rectangle {
  id: root

  property var bout: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property bool done: bout && bout.finished === true

  implicitHeight: col.implicitHeight + Style.space(12)
  radius: Math.max(2, Style.cornerRadius)
  color: done ? "transparent" : Util.alpha(Color.accent, 0.06)

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(3)

    Text {
      text: root.bout ? "M" + root.bout.position : ""
      color: Qt.darker(root.foreground, 1.9)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 0.6
    }

    Item {
      width: parent.width
      height: eastName.implicitHeight
      Text {
        id: eastName
        anchors.left: parent.left
        width: parent.width * 0.62
        text: root.bout ? root.bout.east : ""
        color: root.done && root.bout.winner === root.bout.east ? root.foreground : Qt.darker(root.foreground, 1.25)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.done && root.bout.winner === root.bout.east
        elide: Text.ElideRight
      }
      Text {
        anchors.right: parent.right
        width: parent.width * 0.36
        horizontalAlignment: Text.AlignRight
        text: "E · " + (root.bout ? root.bout.eastRank || "" : "")
        color: Qt.darker(root.foreground, 1.8)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    Item {
      width: parent.width
      height: westName.implicitHeight
      Text {
        id: westName
        anchors.left: parent.left
        width: parent.width * 0.62
        text: root.bout ? root.bout.west : ""
        color: root.done && root.bout.winner === root.bout.west ? root.foreground : Qt.darker(root.foreground, 1.25)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.done && root.bout.winner === root.bout.west
        elide: Text.ElideRight
      }
      Text {
        anchors.right: parent.right
        width: parent.width * 0.36
        horizontalAlignment: Text.AlignRight
        text: "W · " + (root.bout ? root.bout.westRank || "" : "")
        color: Qt.darker(root.foreground, 1.8)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    Text {
      visible: root.done
      text: (root.bout ? root.bout.winner : "") + (root.bout && root.bout.kimarite ? " · " + root.bout.kimarite : "")
      color: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    Text {
      visible: !root.done
      text: "Pending"
      color: Qt.darker(root.foreground, 1.8)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Accessible.role: Accessible.ListItem
  Accessible.name: root.bout
    ? root.bout.east + " versus " + root.bout.west
      + (root.done ? ", winner " + root.bout.winner : ", pending")
    : "Bout"
}
