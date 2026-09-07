import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "SportsModel.js" as SportsModel

BarWidget {
  id: root
  moduleName: "io.github.marty-schneider.live-sports"

  readonly property string label: panelLoader.item ? panelLoader.item.label : "CS ⋯"
  readonly property bool sessionLive: panelLoader.item ? panelLoader.item.sessionLive === true : false

  readonly property var verticalLines: {
    var parts = String(label).split(" ")
    if (parts.length <= 1) return [label]
    return [parts[0], parts.slice(1).join(" ").split(" ")[0]]
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() { if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh() }
  function togglePanel() { if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle() }
  function toggleLive() { if (panelLoader.item) panelLoader.item.toggleLive() }

  function announce() {
    if (!root.bar || !panelLoader.item) return
    var text = SportsModel.notificationArg(panelLoader.item.tooltipText, "Live Sports")
    root.bar.run("omarchy-notification-send --app-name 'Live Sports' 'Live Sports' "
      + Util.shellQuote(text))
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey() }
  function close() { if (panelLoader.item && panelLoader.item.close) panelLoader.item.close() }
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Dashboard.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.marty-schneider.live-sports.widget"
    function refresh(): void { root.refresh() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "" : root.label
    labelVisible: !root.vertical
    hasVisualContent: root.vertical ? root.verticalLines.length > 0 : text !== ""
    fixedHeight: root.vertical ? root.verticalLines.length * Style.bar.iconSlot : -1
    horizontalMargin: 8.75
    verticalPadding: 8.75
    active: root.sessionLive
    tooltipText: panelLoader.item ? panelLoader.item.tooltipText : ""
    onPressed: function(b) {
      if (b === Qt.RightButton) root.announce()
      else if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }

    Column {
      visible: root.vertical
      anchors.fill: parent
      Repeater {
        model: root.verticalLines
        OpticalGlyph {
          required property string modelData
          width: button.width
          height: Style.bar.iconSlot
          text: modelData
          fontFamily: button.fontFamily
          fontSize: modelData.length > 4 ? button.fontSize * 0.85 : button.fontSize
          color: button.active ? button.activeColor : button.foreground
        }
      }
    }

    Accessible.role: Accessible.Button
    Accessible.name: "Live Sports"
    Accessible.description: panelLoader.item ? panelLoader.item.tooltipText : "Live Sports dashboard"
  }
}
