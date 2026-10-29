pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

Item {
  id: root
  property var pluginApi
  property var screen
  property bool active
  property string density: "full"
  property real s: 1
  property real widthBudget: 428

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property real pad: 12 * root.s
  readonly property real contentW: Math.max(200 * root.s, (root.widthBudget > 0 ? root.widthBudget : 428 * root.s) - root.pad * 2)
  property real customGrams: 4
  property bool quickAddExpanded: false
  property bool equivalentsExpanded: false
  property real equivalentWhiteGrams: 4
  readonly property real brownSugarRatio: {
    var value = Number(root.pluginApi?.pluginSettings?.brownSugarRatio ?? 100)
    return isFinite(value) && value > 0 ? Math.max(10, Math.min(400, value)) : 100
  }
  readonly property real steviaSweetness: {
    var value = Number(root.pluginApi?.pluginSettings?.steviaSweetness ?? 200)
    return isFinite(value) && value > 0 ? Math.max(1, Math.min(500, value)) : 200
  }
  readonly property real equivalentBrownGrams: Math.max(0, equivalentWhiteGrams) * brownSugarRatio / 100
  readonly property real equivalentSteviaGrams: steviaSweetness > 0 ? Math.max(0, equivalentWhiteGrams) / steviaSweetness : 0
  implicitWidth: root.contentW + root.pad * 2
  implicitHeight: body.implicitHeight

  function gramsText(value) {
    var grams = Number(value)
    if (!isFinite(grams) || grams <= 0) return "0 g"
    if (grams >= 10) return (Math.round(grams * 10) / 10) + " g"
    if (grams >= 1) return (Math.round(grams * 100) / 100) + " g"
    return (Math.round(grams * 1000) / 1000) + " g"
  }

  Component.onCompleted: {
    var white = Number(root.pluginApi?.pluginSettings?.whiteSugarGrams ?? 4)
    root.equivalentWhiteGrams = isFinite(white) && white > 0 ? white : 4
  }

  Column {
    id: body
    x: root.pad
    width: root.contentW
    spacing: 12 * root.s

    // ── today's total and the goal ────────────────────────────────────────
    Item {
      width: parent.width
      height: Math.max(totalColumn.implicitHeight, goalColumn.implicitHeight)

      Column {
        id: totalColumn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.55
        spacing: 3 * root.s
        MicroLabel { label: qsTr("SWEETENER TODAY"); s: root.s }
        Text {
          width: parent.width
          text: root.service ? root.service.todayGrams + " g" : "—"
          color: root.service?.overGoal ? "#fa3b30" : Theme.cream
          font.family: Theme.font
          font.pixelSize: 28 * root.s
          font.bold: true
        }
      }

      Column {
        id: goalColumn
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: parent.width * 0.38
        spacing: 3 * root.s
        MicroLabel { label: qsTr("DAILY GOAL"); s: root.s }
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignRight
          text: root.service ? root.service.dailyGoal + " g" : "25 g"
          color: Theme.subtle
          font.family: Theme.font
          font.pixelSize: 15 * root.s
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 5 * root.s
      radius: 3 * root.s
      color: Theme.tileBg
      Rectangle {
        width: parent.width * Math.min(1, root.service && root.service.dailyGoal > 0 ? root.service.todayGrams / root.service.dailyGoal : 0)
        height: parent.height
        radius: parent.radius
        color: root.service?.overGoal ? "#fa3b30" : Theme.cream
      }
    }

    // ── quick add ─────────────────────────────────────────────────────────
    Item {
      width: parent.width
      height: 42 * root.s
      Rectangle {
        anchors.fill: parent
        radius: Motion.rSmall * root.s
        color: quickTap.containsMouse ? Theme.brand : Theme.tileBg
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
      }
      Text {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Quick add")
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.bold: true
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.quickAddExpanded ? "−" : "+"
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 18 * root.s
        font.bold: true
      }
      MouseArea {
        id: quickTap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.quickAddExpanded = !root.quickAddExpanded
      }
    }

    Column {
      width: parent.width
      spacing: 8 * root.s
      visible: root.quickAddExpanded

      Repeater {
        model: [
          { label: qsTr("Sugar (white)"), grams: Number(root.pluginApi?.pluginSettings?.whiteSugarGrams ?? 4) },
          { label: qsTr("Brown sugar"), grams: Number(root.pluginApi?.pluginSettings?.brownSugarGrams ?? 4) },
          { label: qsTr("Stevia"), grams: Number(root.pluginApi?.pluginSettings?.steviaGrams ?? 1) },
        ]
        delegate: Item {
          required property var modelData
          width: body.width
          height: 38 * root.s
          Rectangle {
            anchors.fill: parent
            radius: Motion.rSmall * root.s
            color: addRowTap.containsMouse ? Theme.brand : Theme.tileBg
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.fast } }
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: "+" + modelData.grams + " g"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.bold: true
          }
          MouseArea {
            id: addRowTap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service?.addSugar(modelData.grams, modelData.label)
          }
        }
      }

      // custom amount
      Item {
        width: body.width
        height: 38 * root.s
        Rectangle {
          x: 0
          width: parent.width - 100 * root.s - 8 * root.s
          height: parent.height
          radius: Motion.rSmall * root.s
          color: Theme.tileBg
          border.width: 1
          border.color: Theme.border
          TextInput {
            id: customField
            anchors.fill: parent
            anchors.leftMargin: 10 * root.s
            anchors.rightMargin: 10 * root.s
            verticalAlignment: TextInput.AlignVCenter
            text: String(root.customGrams)
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 13 * root.s
            inputMethodHints: Qt.ImhDigitsOnly
            validator: DoubleValidator { bottom: 0.1; top: 200; decimals: 1 }
            onTextChanged: {
              var amount = Number(text)
              if (isFinite(amount) && amount > 0 && amount <= 200) root.customGrams = amount
            }
          }
        }
        Item {
          x: parent.width - 100 * root.s
          width: 100 * root.s
          height: parent.height
          Rectangle {
            anchors.fill: parent
            radius: Motion.rSmall * root.s
            color: customTap.containsMouse ? Theme.brand : "transparent"
            border.width: 1
            border.color: Theme.brand
          }
          Text {
            anchors.centerIn: parent
            text: qsTr("Add " + root.gramsText(root.customGrams))
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.bold: true
          }
          MouseArea {
            id: customTap
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service?.addSugar(root.customGrams, qsTr("Custom sugar"))
          }
        }
      }
    }

    // ── sugar equivalents ────────────────────────────────────────────────
    Item {
      width: parent.width
      height: 42 * root.s
      Rectangle {
        anchors.fill: parent
        radius: Motion.rSmall * root.s
        color: equivalentsTap.containsMouse ? Theme.brand : Theme.tileBg
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
      }
      Text {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Sugar equivalents")
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.bold: true
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 34 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.gramsText(root.equivalentWhiteGrams) + " white"
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 11 * root.s
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.equivalentsExpanded ? "−" : "+"
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 18 * root.s
        font.bold: true
      }
      MouseArea {
        id: equivalentsTap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.equivalentsExpanded = !root.equivalentsExpanded
      }
    }

    Column {
      width: parent.width
      spacing: 8 * root.s
      visible: root.equivalentsExpanded

      Item {
        width: body.width
        height: 34 * root.s
        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: qsTr("White sugar grams")
          color: Theme.subtle
          font.family: Theme.font
          font.pixelSize: 11 * root.s
        }
        Rectangle {
          anchors.right: parent.right
          width: 110 * root.s
          height: parent.height
          radius: Motion.rSmall * root.s
          color: Theme.tileBg
          border.width: 1
          border.color: Theme.border
          TextInput {
            id: equivalentField
            anchors.fill: parent
            anchors.leftMargin: 10 * root.s
            anchors.rightMargin: 10 * root.s
            verticalAlignment: TextInput.AlignVCenter
            text: String(root.equivalentWhiteGrams)
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator { bottom: 0; top: 500; decimals: 2 }
            onTextChanged: {
              var amount = Number(text)
              if (isFinite(amount) && amount >= 0 && amount <= 500) root.equivalentWhiteGrams = amount
            }
          }
        }
      }

      Repeater {
        model: [
          { label: qsTr("Brown sugar"), grams: root.equivalentBrownGrams },
          { label: qsTr("Stevia"), grams: root.equivalentSteviaGrams },
        ]
        delegate: Item {
          required property var modelData
          width: body.width
          height: 34 * root.s
          Rectangle {
            anchors.fill: parent
            radius: Motion.rSmall * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: Theme.border
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: "≈ " + root.gramsText(modelData.grams)
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.bold: true
          }
        }
      }

      Text {
        width: body.width
        text: qsTr("Brown sugar at " + root.brownSugarRatio + "% and stevia at " + root.steviaSweetness + "× the sweetness of white sugar. Change both in Ryoku Settings.")
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 10 * root.s
        wrapMode: Text.WordWrap
      }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ── today's log ───────────────────────────────────────────────────────
    Item {
      width: parent.width
      height: 16 * root.s
      MicroLabel { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; label: qsTr("TODAY'S LOG"); s: root.s }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Clear")
        color: root.service?.todayEntries.length > 0 ? Theme.brand : Theme.border
        font.family: Theme.font
        font.pixelSize: 11 * root.s
        MouseArea {
          anchors.fill: parent
          enabled: root.service?.todayEntries.length > 0
          cursorShape: Qt.PointingHandCursor
          onClicked: root.service?.clearToday()
        }
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 44 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Undo")
        color: root.service?.todayEntries.length > 0 ? Theme.subtle : Theme.border
        font.family: Theme.font
        font.pixelSize: 11 * root.s
        MouseArea {
          anchors.fill: parent
          enabled: root.service?.todayEntries.length > 0
          cursorShape: Qt.PointingHandCursor
          onClicked: root.service?.undoLast()
        }
      }
    }

    Text {
      width: parent.width
      visible: !root.service || root.service.todayEntries.length === 0
      text: qsTr("Nothing logged today.")
      color: Theme.subtle
      font.family: Theme.font
      font.pixelSize: 12 * root.s
    }

    Column {
      width: parent.width
      spacing: 6 * root.s
      Repeater {
        model: {
          var rows = root.service ? root.service.todayEntries.slice() : []
          rows.reverse()
          return rows.slice(0, 8)
        }
        delegate: Item {
          required property var modelData
          width: body.width
          height: 18 * root.s
          Text {
            anchors.left: parent.left
            anchors.right: gramsTextItem.left
            anchors.rightMargin: 8 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(modelData.t), "hh:mm") + "  ·  " + modelData.name
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            elide: Text.ElideRight
          }
          Text {
            id: gramsTextItem
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.grams + " g"
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 12 * root.s
          }
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    Column {
      width: parent.width
      spacing: 4 * root.s
      MicroLabel { label: qsTr("DAILY SWEETENER GOAL · GRAMS"); s: root.s }
      Text {
        width: parent.width
        text: root.service
          ? (root.service.todayGrams <= root.service.dailyGoal
            ? (root.service.dailyGoal - root.service.todayGrams).toFixed(1) + " g remaining"
            : (root.service.todayGrams - root.service.dailyGoal).toFixed(1) + " g over goal")
          : ""
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 12 * root.s
      }
      Text {
        width: parent.width
        text: qsTr("Set your daily target, tap amounts and conversions in Ryoku Settings → Plugins → Sugar Tracker.")
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 10 * root.s
        wrapMode: Text.WordWrap
      }
    }
  }
}
