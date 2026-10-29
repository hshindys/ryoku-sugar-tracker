pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

Item {
  id: root
  property var pluginApi
  property var screen
  property bool active
  property string density: "glyph"
  property real s: 1
  property real widthBudget: 0

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property real glyphW: 22
  readonly property real glyphH: 32
  readonly property real contentW: density === "glyph" ? root.glyphW + 4 : Math.min(widthBudget > 0 ? widthBudget : 320 * s, 320 * s)
  readonly property real progress: {
    if (!service) return 0
    var goal = Number(service.dailyGoal)
    if (!isFinite(goal) || goal <= 0) return service.todayGrams > 0 ? 1 : 0
    return Math.max(0, service.todayGrams / goal)
  }
  readonly property color spoonColor: root.rampColor(root.progress)

  // White at zero, green around a third, orange approaching the goal, red at it.
  function rampColor(progress) {
    var stops = [
      { at: 0.00, color: [1.00, 1.00, 1.00] },
      { at: 0.35, color: [0.31, 0.81, 0.45] },
      { at: 0.70, color: [1.00, 0.63, 0.20] },
      { at: 1.00, color: [0.98, 0.23, 0.19] }
    ]
    var p = Math.max(0, Math.min(1, Number(progress) || 0))
    for (var i = 1; i < stops.length; i++) {
      if (p <= stops[i].at) {
        var from = stops[i - 1]
        var to = stops[i]
        var span = to.at - from.at
        var t = span > 0 ? (p - from.at) / span : 0
        return Qt.rgba(
          from.color[0] + (to.color[0] - from.color[0]) * t,
          from.color[1] + (to.color[1] - from.color[1]) * t,
          from.color[2] + (to.color[2] - from.color[2]) * t,
          1)
      }
    }
    return Qt.rgba(stops[stops.length - 1].color[0], stops[stops.length - 1].color[1], stops[stops.length - 1].color[2], 1)
  }

  implicitWidth: contentW
  implicitHeight: density === "glyph" ? root.glyphH : body.implicitHeight

  Canvas {
    id: spoonMark
    anchors.centerIn: parent
    visible: root.density === "glyph"
    width: root.glyphW
    height: root.glyphH
    onPaint: {
      var ctx = getContext("2d")
      // Design space is 22 x 32; map it onto whatever pixels the item got.
      var scale = Math.min(width / 22, height / 32)
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.clearRect(0, 0, width, height)
      ctx.save()
      ctx.translate((width - 22 * scale) / 2, (height - 32 * scale) / 2)
      ctx.scale(scale, scale)
      ctx.fillStyle = root.spoonColor

      // Oval helper: Qt's canvas ellipse(x, y, w, h) takes a bounding box, so
      // an arc plus a y-scale is the reliable way to place a bowl by centre.
      function oval(cx, cy, rx, ry) {
        ctx.save()
        ctx.translate(cx, cy)
        ctx.scale(1, ry / rx)
        ctx.beginPath()
        ctx.arc(0, 0, rx, 0, 2 * Math.PI, false)
        ctx.fill()
        ctx.restore()
      }

      // Bowl: a short oval at the top, so the handle carries the silhouette.
      oval(11.0, 6.8, 6.4, 6.8)

      // Tapered handle with a rounded tip.
      ctx.beginPath()
      ctx.moveTo(9.2, 11.6)
      ctx.bezierCurveTo(9.4, 18.0, 9.7, 25.5, 9.8, 29.4)
      ctx.quadraticCurveTo(9.9, 31.4, 11.0, 31.4)
      ctx.quadraticCurveTo(12.1, 31.4, 12.2, 29.4)
      ctx.bezierCurveTo(12.3, 25.5, 12.6, 18.0, 12.8, 11.6)
      ctx.closePath()
      ctx.fill()

      // Shaded hollow of the bowl, so the spoon still reads at small sizes.
      ctx.globalAlpha = 0.17
      ctx.fillStyle = "#000000"
      oval(11.0, 7.0, 3.4, 4.0)
      ctx.globalAlpha = 1.0
      ctx.fillStyle = root.spoonColor

      ctx.restore()
    }
    Connections {
      target: root.service
      function onTodayGramsChanged() { spoonMark.requestPaint() }
      function onDailyGoalChanged() { spoonMark.requestPaint() }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.pluginApi?.togglePanel()
  }

  Column {
    id: body
    visible: root.density !== "glyph"
    width: root.contentW
    spacing: 8 * root.s
    MicroLabel { label: qsTr("SUGAR TODAY"); s: root.s }
    Text {
      width: root.contentW
      text: root.service ? root.service.todayGrams + " / " + root.service.dailyGoal + " g" : "—"
      color: root.service?.overGoal ? "#fa3b30" : Theme.cream
      font.family: Theme.font
      font.pixelSize: 24 * root.s
      font.bold: true
    }
  }
}
