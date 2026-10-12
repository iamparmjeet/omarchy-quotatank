pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import "UsageLogic.js" as UsageLogic

// Six-tile summary (Tokens · Output · Est. cost / Sessions · Cache hit ·
// Active days), always visible. Totals come from the cost payload.
Grid {
  id: root

  property var totals: ({})
  property var periods: []
  property color foreground: Commons.Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  columns: 3
  columnSpacing: Style.spacing.xxl
  rowSpacing: Style.spacing.lg

  function cacheHitPercent() {
    var cached = Number(root.totals.cachedInputTokens) || 0
    var uncached = Number(root.totals.uncachedInputTokens) || 0
    var created = Number(root.totals.cacheCreationTokens) || 0
    var all = cached + uncached + created
    if (!(all > 0)) return "—"
    return Math.round(cached / all * 100) + "%"
  }

  function activeDays() {
    var days = 0
    for (var i = 0; i < root.periods.length; i++)
      if (Number(root.periods[i].totalTokens) > 0) days++
    return String(days)
  }

  function outputShare() {
    var total = Number(root.totals.totalTokens) || 0
    if (!(total > 0)) return ""
    return Math.round((Number(root.totals.outputTokens) || 0) / total * 100) + "% of tokens"
  }

  function unpricedNote() {
    var unpriced = Number(root.totals.unpricedRecords) || 0
    return unpriced > 0 ? unpriced + " unpriced" : ""
  }

  function responsesNote() {
    var records = Number(root.totals.records) || 0
    return records > 0 ? records + " responses" : ""
  }

  function periodNote() {
    return root.periods.length > 1 ? "of " + root.periods.length + " days" : ""
  }

  Repeater {
    model: [
      { label: "Tokens", value: UsageLogic.formatTokens(root.totals.totalTokens), sub: root.responsesNote() },
      { label: "Output", value: UsageLogic.formatTokens(root.totals.outputTokens), sub: root.outputShare() },
      { label: "Est. cost", value: UsageLogic.formatUsd(root.totals.costUsd), sub: root.unpricedNote() },
      { label: "Sessions", value: String(Number(root.totals.sessions) || 0), sub: root.responsesNote() },
      { label: "Cache hit", value: root.cacheHitPercent(), sub: "" },
      { label: "Active days", value: root.activeDays(), sub: root.periodNote() }
    ]

    delegate: Column {
      required property var modelData
      width: (root.width - 2 * Style.spacing.xxl) / 3
      spacing: Style.spacing.labelGap

      Text {
        text: parent.modelData.label
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        width: parent.width
      }
      Text {
        text: parent.modelData.value
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Math.round(Style.font.body * 1.45)
        font.bold: true
        elide: Text.ElideRight
        width: parent.width
      }
      Text {
        text: parent.modelData.sub !== "" ? parent.modelData.sub : " "
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        width: parent.width
      }
    }
  }
}
