pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui
import "UsageLogic.js" as UsageLogic

// Token details + model breakdown, extracted from the Costs tab so they can
// live on their own Tokens tab. Property names mirror UsageCosts.
Column {
  id: root

  property var payload: ({})
  property string metric: "cost"
  property color foreground: Commons.Color.foreground
  property color urgent: Commons.Color.urgent
  property string fontFamily: Style.font.family


  readonly property var topModels: {
    return root.models.slice().sort(function(a, b) {
      return (Number(b.totalTokens) || 0) - (Number(a.totalTokens) || 0)
    })
  }
  readonly property real maxModelTokens: topModels.length > 0 ? Number(topModels[0].totalTokens) || 0 : 0

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property var totals: payload && payload.totals ? payload.totals : ({})
  readonly property var providers: payload ? UsageLogic.listOrEmpty(payload.providers) : []
  readonly property var models: payload ? UsageLogic.listOrEmpty(payload.models) : []
  readonly property var periods: payload ? UsageLogic.listOrEmpty(payload.periods) : []
  readonly property bool hasResult: !!(payload && payload.generatedAt && periods.length > 0)

  spacing: Style.spacing.xxl

  function alpha(color, opacity) {
    return Qt.rgba(color.r, color.g, color.b, opacity)
  }

  function priceCoverage(row) {
    if (!row || Number(row.records) <= 0) return 1
    return Math.max(0, Math.min(1, Number(row.pricedRecords || 0) / Number(row.records)))
  }

  function primaryValue(row) {
    if (row && (row.status === "missing" || row.status === "failed" || row.historyStatus === "unavailable")) return "—"
    return metric === "tokens" ? UsageLogic.formatTokens(row ? row.totalTokens : 0)
      : UsageLogic.formatUsd(row ? row.costUsd : null)
  }

  function providerMetaText(row) {
    if (!row) return ""
    if (row.status === "missing" || row.status === "failed")
      return String(row.message || "Usage coverage unavailable")
    if (row.historyStatus === "unavailable") return "History unavailable"
    return UsageLogic.formatTokens(row.totalTokens) + " tokens"
      + (Number(row.records || 0) > 0
        ? " · " + pricingPercent(row) + " of responses priced" : "")
  }

  function pricingPercent(row) {
    return Math.min(Number(row.unpricedRecords || 0) > 0 ? 99 : 100,
      Math.floor(priceCoverage(row) * 100)) + "%"
  }

    Column {
      visible: root.hasResult
      width: parent.width
      spacing: Style.spacing.lg

      Ui.PanelSectionHeader {
        text: "SUMMARY"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      UsageSummary {
        width: parent.width
        totals: root.totals
        periods: root.periods
        foreground: root.foreground
        fontFamily: root.fontFamily
      }
    }
    Column {
      id: modelList
      visible: root.hasResult && root.models.length > 0
      width: parent.width
      spacing: Style.spacing.md

      Item {
        width: parent.width
        implicitHeight: Math.max(modelHead.implicitHeight, modelCount.implicitHeight)

        Text {
          id: modelHead
          text: "TOKENS BY MODEL"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.weight: Font.DemiBold
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: modelCount
          text: root.models.length + (root.models.length === 1 ? " model" : " models")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Repeater {
        model: root.topModels

        delegate: Item {
          required property var modelData
          required property int index
          objectName: "costModel-" + index
          width: modelList.width
          implicitHeight: modelRowLabel.implicitHeight + Style.spacing.sm

          Rectangle {
            anchors.fill: parent
            radius: 2
            color: root.alpha(root.foreground, 0.05)
          }

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 2
            width: root.maxModelTokens > 0
              ? parent.width * (Number(modelData.totalTokens) || 0) / root.maxModelTokens : 0
            color: root.alpha(root.foreground, 0.14)
          }

          Text {
            id: modelRowLabel
            text: String(modelData.model || "Unknown model")
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            anchors.left: parent.left
            anchors.leftMargin: Style.spacing.md
            anchors.right: modelRowValue.left
            anchors.rightMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: modelRowValue
            text: UsageLogic.formatTokens(modelData.totalTokens)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            anchors.right: parent.right
            anchors.rightMargin: Style.spacing.md
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
}
