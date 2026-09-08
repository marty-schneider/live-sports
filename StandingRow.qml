import QtQuick
import qs.Commons

// The shared row for every ranked list on the panel: driver standings,
// constructor standings, the qualifying grid, and the latest race result.
//
// One component for all four keeps the columns aligned across sections, so the
// eye can move down the panel without re-learning a layout each time.
//
// The team livery appears as a bar at the row's leading edge, and the team's
// name is always printed next to it. Colour is decoration; the text is the
// information.
Rectangle {
  id: root

  property int position: 0
  property string positionPrefix: "P"
  property string code: ""
  property string name: ""
  property string teamName: ""
  property color teamColor: Color.accent
  property string valueText: ""
  property string noteText: ""
  property bool pinned: false
  property bool showTeam: true
  property bool clickable: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  signal clicked()

  implicitHeight: body.height + Style.space(9)
  radius: Math.max(2, Style.cornerRadius)
  color: pinned ? Util.alpha(Color.accent, 0.10) : "transparent"
  border.width: pinned ? Math.max(1, Style.normalBorderWidth) : 0
  border.color: Util.alpha(Color.accent, 0.35)

  Item {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    height: Math.max(leftCol.implicitHeight, values.implicitHeight)

    Row {
      id: leftCol
      anchors.left: parent.left
      anchors.right: values.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(10)

      Text {
        width: Style.space(28)
        anchors.verticalCenter: parent.verticalCenter
        text: root.positionPrefix === "" ? "" : root.positionPrefix + root.position
        color: root.position === 1 ? root.foreground : Qt.darker(root.foreground, 1.7)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.position === 1
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(3)
        height: Style.space(16)
        radius: width / 2
        color: root.teamColor
        visible: root.showTeam
      }

      Column {
        width: Math.max(0, leftCol.width - Style.space(28) - (root.showTeam ? Style.space(13) : 0) - leftCol.spacing * (root.showTeam ? 2 : 1))
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
          width: parent.width
          text: root.name + (root.code !== "" ? "  " + root.code : "")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: root.showTeam && root.teamName !== ""
          text: root.teamName
          color: Qt.darker(root.foreground, 1.7)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }

    Column {
      id: values
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Text {
        anchors.right: parent.right
        text: root.valueText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: root.pinned || root.position === 1
      }

      Text {
        anchors.right: parent.right
        visible: root.noteText !== ""
        text: root.noteText
        color: root.pinned ? Color.accent : Qt.darker(root.foreground, 1.8)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.clickable
    hoverEnabled: root.clickable
    cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }

  Accessible.role: Accessible.ListItem
  Accessible.name: root.positionPrefix + root.position + ", " + root.name
    + (root.teamName !== "" ? ", " + root.teamName : "")
    + ", " + root.valueText
    + (root.noteText !== "" ? ", " + root.noteText : "")
}
