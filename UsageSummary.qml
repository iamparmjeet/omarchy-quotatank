pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import "UsageLogic.js" as UsageLogic

// Transcript summary for the current provider selection and date range.
Column {
  id: root

  property bool available: true
  property string scopeLabel: "All transcript providers"
  property string periodLabel: ""
  property var totals: ({})
  property var periods: []
  property color foreground: Commons.Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  spacing: Style.spacing.lg

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

  Column {
    width: parent.width
    spacing: Style.spacing.labelGap

    Text {
      text: "Total tokens · " + root.scopeLabel + (root.periodLabel ? " · " + root.periodLabel : "")
      textFormat: Text.PlainText
      width: parent.width
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    Text {
      objectName: "summaryTotalTokens"
      text: root.available ? UsageLogic.formatTokens(root.totals.totalTokens) : "—"
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.bold: true
    }
    Text {
      visible: !root.available
      text: "Transcript usage unavailable for this provider. Balance and quota are shown separately."
      textFormat: Text.PlainText
      width: parent.width
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Grid {
    visible: root.available
    width: parent.width
    columns: 3
    columnSpacing: Style.spacing.xxl
    rowSpacing: Style.spacing.lg

    Repeater {
      model: [
        { label: "Input", value: UsageLogic.formatTokens((Number(root.totals.uncachedInputTokens) || 0) + (Number(root.totals.cachedInputTokens) || 0) + (Number(root.totals.cacheCreationTokens) || 0)), sub: "including cache" },
        { label: "Output", value: UsageLogic.formatTokens(root.totals.outputTokens), sub: root.outputShare() },
        { label: "Est. cost", value: UsageLogic.formatUsd(root.totals.costUsd), sub: root.unpricedNote() },
        { label: "Sessions", value: root.totals.sessions === null || root.totals.sessions === undefined ? "—" : String(root.totals.sessions), sub: root.responsesNote() },
        { label: "Cache hit", value: root.cacheHitPercent(), sub: "" },
        { label: "Active days", value: root.activeDays(), sub: root.periodNote() }
      ]

      delegate: Column {
        required property var modelData
        width: (root.width - 2 * Style.spacing.xxl) / 3
        spacing: Style.spacing.labelGap

        Text {
          textFormat: Text.PlainText
          text: parent.modelData.label
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          width: parent.width
        }
        Text {
          textFormat: Text.PlainText
          text: parent.modelData.value
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Math.round(Style.font.body * 1.45)
          font.bold: true
          elide: Text.ElideRight
          width: parent.width
        }
        Text {
          textFormat: Text.PlainText
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
}
