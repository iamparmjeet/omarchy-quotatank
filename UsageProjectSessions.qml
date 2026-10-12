pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui
import "UsageLogic.js" as UsageLogic

// Tokens by project + top sessions, with persisted dropdowns.
Column {
  id: root

  property var projects: []
  property var sessions: []
  property bool hasResult: false
  property bool projectsOpen: false
  property bool sessionsOpen: false
  signal projectsToggled(bool open)
  signal sessionsToggled(bool open)

  property color foreground: Commons.Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  readonly property var topProjects: projects.slice(0, 5)
  readonly property real maxProjectTokens: topProjects.length > 0 ? Number(topProjects[0].totalTokens) || 0 : 0
  readonly property var topSessions: sessions.slice(0, 5)
  readonly property real maxSessionTokens: topSessions.length > 0 ? Number(topSessions[0].totalTokens) || 0 : 0

  function alpha(color, opacity) {
    return Qt.rgba(color.r, color.g, color.b, opacity)
  }

  function sessionLabel(row) {
    if (row && String(row.title || "") !== "") return String(row.title)
    return "session " + String(row.id || "").slice(0, 8)
  }

  spacing: Style.spacing.xxl

    Column {
      visible: root.hasResult && root.projects.length > 0
      width: parent.width
      spacing: Style.spacing.md

      UsageDisclosure {
        width: parent.width
        text: "TOKENS BY PROJECT"
        checked: root.projectsOpen
        foreground: root.foreground
        fontFamily: root.fontFamily
        onToggled: root.projectsToggled(checked)
      }

      Column {
        id: projectList
        visible: root.projectsOpen
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          text: "top " + Math.min(5, root.projects.length) + " of " + root.projects.length
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
        }

        Repeater {
          model: root.topProjects

          delegate: Item {
            required property var modelData
            width: projectList.width
            implicitHeight: projectLabel.implicitHeight + Style.spacing.sm

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
              width: root.maxProjectTokens > 0
                ? parent.width * (Number(modelData.totalTokens) || 0) / root.maxProjectTokens : 0
              color: root.alpha(root.foreground, 0.14)
            }

            Text {
              id: projectLabel
              text: String(modelData.name || "Unknown project")
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.md
              anchors.right: projectValue.left
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: projectValue
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

    Column {
      visible: root.hasResult && root.sessions.length > 0
      width: parent.width
      spacing: Style.spacing.md

      UsageDisclosure {
        width: parent.width
        text: "TOP SESSIONS"
        checked: root.sessionsOpen
        foreground: root.foreground
        fontFamily: root.fontFamily
        onToggled: root.sessionsToggled(checked)
      }

      Column {
        id: sessionList
        visible: root.sessionsOpen
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          text: "top " + Math.min(5, root.sessions.length) + " of " + root.sessions.length
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
        }

        Repeater {
          model: root.topSessions

          delegate: Item {
            required property var modelData
            width: sessionList.width
            implicitHeight: sessionLabel.implicitHeight + Style.spacing.sm

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
              width: root.maxSessionTokens > 0
                ? parent.width * (Number(modelData.totalTokens) || 0) / root.maxSessionTokens : 0
              color: root.alpha(root.foreground, 0.14)
            }

            Text {
              id: sessionLabel
              text: root.sessionLabel(modelData)
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              maximumLineCount: 1
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.md
              anchors.right: sessionValue.left
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: sessionValue
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
    }}
