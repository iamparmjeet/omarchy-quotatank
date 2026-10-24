import QtQuick
import Quickshell
import qs.Commons

ShellRoot {
  id: root
  property var widget: null
  property int attempts: 0
  property int phase: 0
  function check(value, message) { if (!value) throw new Error("SUMMARY TEST FAILED: " + message) }
  function find(item, name) {
    if (item.objectName === name) return item
    var children = item.children || []
    for (var i = 0; i < children.length; i++) { var child = find(children[i], name); if (child) return child }
    return null
  }
  Component.onCompleted: {
    var component = Qt.createComponent(Quickshell.env("MODEL_USAGE_REPO_URL") + "/Panel.qml")
    check(component.status === Component.Ready, component.errorString())
    widget = component.createObject(host, {bar: fakeBar, settings: {
      enabledProviders: ["claude", "codex", "kimi"], costLocalProviders: ["claude", "codex"], refreshIntervalSec: 3600
    }})
    check(widget !== null, component.errorString())
    widget.showLimits()
  }
  Timer {
    interval: 50
    running: true
    repeat: true
    onTriggered: {
      root.attempts++
      root.check(root.attempts < 160, "fixture should load")
      if (!root.widget || !root.widget.summary.available || root.widget.providers.length < 3) return
      var widget = root.widget
      if (root.phase === 0) {
        root.check(widget.selectedProviderId === "all", "All selected by default")
        root.check(widget.summary.totals.totalTokens === 5500000, "All uses combined tokens once")
        root.check(widget.providerOptions[0].value === "all", "All tile available")
        widget.selectProviderId("claude")
        root.phase++
      } else if (root.phase === 1) {
        root.check(widget.summary.totals.totalTokens === 3800000, "Claude selection filters totals")
        root.check(widget.summary.totals.sessions === 2, "Claude sessions filtered")
        var summary = widget.summaryView
        root.check(summary !== null && summary.totals.totalTokens === 3800000, "visible Summary uses filtered totals")
        root.check(root.find(summary, "summaryTotalTokens").text === "3.80M", "token row renders Claude tokens")
        widget.selectProviderId("all")
        root.phase++
      } else {
        root.check(widget.summary.totals.totalTokens === 5500000, "All restores combined tokens")
        widget.selectProviderId("kimi")
        root.check(widget.summary.available === false, "missing transcript usage not reported as zero")
        widget.close()
        console.log("Summary QML contract: passed")
        Qt.quit()
      }
    }
  }
  PanelWindow {
    id: testBarWindow
    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: fakeBar.vertical ? fakeBar.barSize : 1
    implicitHeight: fakeBar.vertical ? 1 : fakeBar.barSize
    anchors.top: fakeBar.position !== "bottom"
    anchors.bottom: fakeBar.position !== "top"
    anchors.left: fakeBar.position !== "right"
    anchors.right: fakeBar.position !== "left"
    mask: Region { width: 0; height: 0 }

    Item {
      id: host
      anchors.fill: parent
    }
  }

  QtObject {
    id: mockShell
    property var bar: fakeBar
    property var barConfig: ({ position: fakeBar.position })
    property var shellConfig: ({ version: 1, plugins: [], bar: { layout: { left: [], center: [], right: [] } } })
    function firstPartyServiceFor(id) { return null }
    function serviceFor(id) { return null }
    property bool rejectSave: false
    property int saveCount: 0
    property string savedId: ""
    property var savedSettings: ({})
    function updateEntryInline(moduleName, settings) {
      if (rejectSave) return false
      saveCount++
      savedId = moduleName
      savedSettings = JSON.parse(JSON.stringify(settings))
      return true
    }
  }

  QtObject {
    id: fakeBar
    property bool vertical: false
    property int barSize: 26
    property string position: "top"
    property string fontFamily: "monospace"
    property color foreground: "#f4f4f5"
    property color barForeground: foreground
    property color background: "#09090b"
    property color urgent: "#ef4444"
    property bool foregroundAnimationEnabled: false
    property var activePopout: null
    property var clickTargets: []
    property var shell: mockShell
    function run(command) {}
    function showTooltip(target, text) {}
    function hideTooltip(target) {}
    function requestPopout(owner) { activePopout = owner }
    function releasePopout(owner) { if (activePopout === owner) activePopout = null }
    function registerClickTarget(target) { clickTargets.push(target) }
    function unregisterClickTarget(target) {}
    function switchPanelFrom(owner, direction) { return false }
  }

}
