THREE = require("three")
raf = require("raf")

# var lsb = require('lsb')
# var Convert = require('voxel-critter/lib/convert.js')
# var ndarray = require('ndarray')
# var ndarrayFill = require('ndarray-fill')
ColorUtils = require './src/color-utils'
ColorManager = require './src/color-manager'
AxisCamera = require './src/axis-camera'
Input = require('./src/input-manager')(THREE)
SceneManager = require('./src/scene-manager')(THREE, Input)
HashManager = require('./src/hash-manager')(SceneManager)
Interactions = require('./src/interactions')(Input, SceneManager)

KeyMouse = require('./src/key-mouse-handlers')(SceneManager, Interactions, Input, HashManager)


window.startEditor = ->
  container = null
  shareDialog = null
  mouse3D = null


  color = 0

  fill = true

  $('#axis-camera-controls .rotate-left').on 'click', ->
    {theta, phi} = AxisCamera.getRotation()
    theta -= 180
    theta += 720 if theta < 0
    AxisCamera.rotateCameraTo(theta, phi)

  $('#axis-camera-controls .rotate-right').on 'click', ->
    {theta, phi} = AxisCamera.getRotation()
    theta += 180
    theta -= 720 if theta >= 720
    AxisCamera.rotateCameraTo(theta, phi)

  $('#axis-camera-controls .zoom-in').on 'click', ->
    AxisCamera.zoom(-100)

  $('#axis-camera-controls .zoom-out').on 'click', ->
    AxisCamera.zoom(100)


  showWelcome = ->
    seenWelcome = localStorage.getItem("seenWelcome")
    return $("#welcome").modal()  if seenWelcome
    localStorage.setItem "seenWelcome", true
    return

  # function getVoxels() {
  #   var hash = window.location.hash.substr(1)
  #   var convert = new Convert()
  #   var data = convert.toVoxels(hash)
  #   var l = data.bounds[0]
  #   var h = data.bounds[1]
  #   var d = [ h[0]-l[0] + 1, h[1]-l[1] + 1, h[2]-l[2] + 1]
  #   var len = d[0] * d[1] * d[2]
  #   var voxels = ndarray(new Int32Array(len), [d[0], d[1], d[2]])
  #
  #   var ColorManager.colors = [undefined]
  #   data.ColorManager.colors.map(function(c) {
  #     ColorManager.colors.push('#' + ColorUtils.rgb2hex(c))
  #   })
  #
  #   function generateVoxels(x, y, z) {
  #     var offset = [x + l[0], y + l[1], z + l[2]]
  #     var val = data.voxels[offset.join('|')]
  #     return data.ColorManager.colors[val] ? val + 1: 0
  #   }
  #
  #   ndarrayFill(voxels, generateVoxels)
  #   return {voxels: voxels, ColorManager.colors: colors}
  # }



  addColorToPalette = (idx) ->

    # add a button to the group
    colorBox = $("i[data-color=\"" + idx + "\"]")
    unless colorBox.length
      base = $(".colorAddButton")
      clone = base.clone()
      clone.removeClass "colorAddButton"
      clone.addClass "colorPickButton"
      colorBox = clone.find(".colorAdd")
      colorBox.removeClass "colorAdd"
      colorBox.addClass "color"
      colorBox.attr "data-color", idx
      colorBox.text ""
      base.before clone
      clone.click (e) ->
        pickColor e
        e.preventDefault()
        return

      clone.on "contextmenu", changeColor
    colorBox.parent().attr "data-color", "#" + ColorUtils.rgb2hex(ColorManager.colors[idx])
    colorBox.css "background", "#" + ColorUtils.rgb2hex(ColorManager.colors[idx])
    SceneManager.brush.children[0].material.color.setRGB ColorManager.colors[idx][0], ColorManager.colors[idx][1], ColorManager.colors[idx][2]  if ColorManager.currentColor is idx and SceneManager.brush
    return






  addColor = (e) ->

    #add new color
    ColorManager.colors.push [
      0.0
      0.0
      0.0
    ]
    idx = ColorManager.colors.length - 1
    ColorManager.currentColor = idx
    addColorToPalette idx
    HashManager.updateHash()
    updateColor idx
    return


  updateColor = (idx) ->
    ColorManager.currentColor = idx
    picker = $("i[data-color=\"" + idx + "\"]").parent().colorpicker("show")
    picker.on "changeColor", (e) ->
      ColorManager.colors[idx] = ColorUtils.hex2rgb(e.color.toHex())
      addColorToPalette idx

      # todo:  better way to update color of existing blocks
      SceneManager.scene.children.filter((el) ->
        el.isVoxel
      ).map (mesh) ->
        SceneManager.scene.remove mesh.wireMesh
        SceneManager.scene.remove mesh
        return

      HashManager.buildFromHash()
      return

    picker.on "hide", (e) ->

      # todo:  add a better remove for the colorpicker.
      picker.unbind "click.colorpicker"
      return

    return


  changeColor = (e) ->
    targetEl = $(e.currentTarget)
    idx = +targetEl.find(".color").attr("data-color")
    updateColor idx
    false # eat the event


  pickColor = (e) ->
    targetEl = $(e.currentTarget)
    idx = +targetEl.find(".color").attr("data-color")
    ColorManager.currentColor = idx
    SceneManager.brush.children[0].material.color.setRGB ColorManager.colors[idx][0], ColorManager.colors[idx][1], ColorManager.colors[idx][2]
    return


  bindEventsAndPlugins = ->
    $(window).on "hashchange", ->
      return localStorage.setItem("seenWelcome", true)  if updatingHash
      window.location.reload()
      return

    $(".colorPickButton").click pickColor
    $(".colorPickButton").on "contextmenu", changeColor
    $(".colorAddButton").click addColor
    $(".toggle input").click (e) ->

      # setTimeout ensures this fires after the input value changes
      setTimeout (->
        el = $(e.target).parent()
        state = not el.hasClass("toggle-off")
        exports[el.attr("data-action")] state
        return
      ), 0
      return

    actionsMenu = $(".actionsMenu")
    actionsMenu.dropkick change: (value, label) ->
      return  if value is "noop"
      exports[value]()  if value of exports
      setTimeout (->
        actionsMenu.dropkick "reset"
        return
      ), 0
      return


    # Init tooltips
    $("[data-toggle=tooltip]").tooltip "show"

    # Init tags input
    $("#tagsinput").tagsInput()

    # JS input/textarea placeholder
    $("input, textarea").placeholder()
    $(".btn-group").on "click", "a", ->
      $(this).siblings().removeClass "active"
      $(this).addClass "active"
      return


    # Disable link click not scroll top
    $("a[href='#']").click (e) ->
      e.preventDefault()
      return

    return



  init = ->


    bindEventsAndPlugins()
    container = document.getElementById("editor-area")
    SceneManager.init(container)
    container.appendChild(SceneManager.renderer.domElement)
    KeyMouse.attachEvents()
    HashManager.buildFromHash()  if window.location.hash
    HashManager.updateHash()
    return






  # Update the Play Level link
  exportFunction = (voxels) ->
    dimensions = getDimensions(voxels)
    voxels = voxels.map((v) ->
      [
        v.x
        v.y
        v.z
        v.c
      ]
    )
    funcString = "var voxels = " + JSON.stringify(voxels) + ";"
    funcString += "var dimensions = " + JSON.stringify(dimensions) + ";"
    funcString += "voxels.map(function(voxel) {" + "if (colorMapper(voxel[3])) { addBlock([position.x + voxel[0], position.y + voxel[1], position.z + voxel[2]], colorMapper(voxel[3])) }" + "});"
    funcString

  getDimensions = (voxels) ->
    low = [
      0
      0
      0
    ]
    high = [
      0
      0
      0
    ]
    voxels.map (voxel) ->
      low[0] = voxel.x  if voxel.x < low[0]
      high[0] = voxel.x  if voxel.x > high[0]
      low[1] = voxel.y  if voxel.y < low[1]
      high[1] = voxel.y  if voxel.y > high[1]
      low[2] = voxel.z  if voxel.z < low[2]
      high[2] = voxel.z  if voxel.z > high[2]
      return

    [
      (high[0] - low[0]) or 1
      (high[1] - low[1]) or 1
      (high[2] - low[2]) or 1
    ]





  # Init code
  c = 0
  while c < 12
    addColorToPalette c
    c++
  showWelcome()
  init()
  raf(window).on "data", -> SceneManager.render()
  exports.viewInstructions = ->
    $("#welcome").modal()
    return

  exports.reset = ->
    window.location.replace "#/"
    SceneManager.scene.children.filter((el) ->
      el.isVoxel
    ).map (mesh) ->
      SceneManager.scene.remove mesh
      return

    return

  exports.setColor = (idx) ->
    $("i[data-color=\"" + idx + "\"]").click()
    return

  exports.showGrid = (bool) ->
    SceneManager.grid.material.visible = bool
    return

  $(".play-level").attr "href", "http://philschatz.com/game/" + window.location.hash
  window.exportMap = ->
    voxels = SceneManager.scene.children.filter((el) ->
      el.isVoxel
    )
    voxelsReal = voxels.map((v) ->
      x: (v.position.x - 25) / 50
      y: (v.position.y - 25) / 50
      z: (v.position.z - 25) / 50
      c: v.wireMesh.material.color.getHexString()
    )
    console.log exportFunction(voxelsReal)
    return

  return
