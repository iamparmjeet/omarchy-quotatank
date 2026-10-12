pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui
import "UsageLogic.js" as UsageLogic

// Weekly stacked trend (by week · peak) with an agent legend, fed by the
// cost payload's per-day provider cells.
Column {
  id: root

  property var payload: ({})
  property color foreground: Commons.Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  readonly property var allPeriods: payload ? UsageLogic.listOrEmpty(payload.periods) : []
  readonly property var periods: allPeriods.slice(Math.max(0, allPeriods.length - 7))
  readonly property var names: {
    var map = {}
    var top = payload ? UsageLogic.listOrEmpty(payload.providers) : []
    for (var i = 0; i < top.length; i++)
      if (top[i] && top[i].id) map[String(top[i].id)] = String(top[i].name || top[i].id)
    return map
  }
  readonly property var agentIds: {
    var seen = {}
    var out = []
    for (var i = 0; i < periods.length; i++) {
      var cells = periods[i] ? UsageLogic.listOrEmpty(periods[i].providers) : []
      for (var j = 0; j < cells.length; j++) {
        var id = cells[j] ? String(cells[j].id || "") : ""
        if (id !== "" && !seen[id]) { seen[id] = true; out.push(id) }
      }
    }
    return out
  }
  readonly property real peak: {
    var best = 0
    for (var i = 0; i < periods.length; i++)
      best = Math.max(best, Number(periods[i].totalTokens) || 0)
    return best
  }

  function dayTotal(day) { return Number(day.totalTokens) || 0 }

  function shortDate(iso) {
    return iso.length >= 10 ? iso.substring(5).replace("-", "/") : ""
  }

  function shortName(id) {
    var name = names[id] || String(id)
    return name.split(" ")[0]
  }

  width: parent.width
  spacing: Style.spacing.md
  visible: periods.length > 0 && peak > 0

  Item {
    width: parent.width
    implicitHeight: Math.max(trendHead.implicitHeight, trendNote.implicitHeight)

    Ui.PanelSectionHeader {
      id: trendHead
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "TREND"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Text {
      text: "by week · peak " + UsageLogic.formatTokens(root.peak)
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Row {
    id: chart
    width: parent.width
    height: 110
    spacing: Style.spacing.sm

    Repeater {
      model: root.periods

      delegate: Item {
        required property var modelData
        readonly property real dayFrac: root.peak > 0 ? root.dayTotal(modelData) / root.peak : 0
        width: root.periods.length > 0
          ? (chart.width - chart.spacing * (root.periods.length - 1)) / root.periods.length : 0
        height: chart.height

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Math.max(dayFrac > 0 ? 2 : 0, chart.height * dayFrac)
          radius: 1
          color: root.foreground
        }
      }
    }
  }

  Item {
    width: parent.width
    implicitHeight: endDate.implicitHeight

    Text {
      anchors.left: parent.left
      text: root.shortDate(root.periods.length > 0 ? String(root.periods[0].start || "") : "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      id: endDate
      anchors.right: parent.right
      text: root.shortDate(root.periods.length > 0 ? String(root.periods[root.periods.length - 1].start || "") : "")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Flow {
    width: parent.width
    spacing: Style.spacing.md

    Repeater {
      model: root.agentIds

      Row {
        required property var modelData
        spacing: Style.spacing.sm

        Rectangle {
          width: Style.space(8)
          height: Style.space(8)
          radius: 2
          color: root.foreground
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.shortName(parent.modelData)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
