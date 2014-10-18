
requestAnimationFrame = require("raf")

GAME = require './src/game'


# var lsb = require('lsb')
# var Convert = require('voxel-critter/lib/convert.js')
# var ndarray = require('ndarray')
# var ndarrayFill = require('ndarray-fill')


Input = require './src/editor/input-manager'
SceneManager = require './src/editor/scene-manager'

ColorUtils = require './src/editor/color-utils'
ColorManager = require './src/editor/color-manager'
AxisCamera = require './src/editor/axis-camera'
MainCamera = require './src/main-camera'
HashManager = require './src/editor/hash-manager'
Interactions = require './src/editor/interactions'

KeyMouse = require './src/editor/key-mouse-handlers'

PaletteManager = require './src/voxels/palette-manager'
VoxelFactory = require './src/voxels/voxel-factory'
IconMaker = require './src/editor/icon-maker'
TextureCube = require './src/voxels/texture-cube'

exportGeometry = require './export-geometry'

LevelLoader = require './src/loaders/level'


window.startEditor = ->
  container = null


  if window.location.hash
    levelPromise = LevelLoader.loadHash('/data/palette-nature.json')
  else
    levelPromise = LevelLoader.load('/data/level-lighthouse.json')

  levelPromise.then (level) ->
    VoxelFactory.load(level)
    alreadyCreatedGame = false

    $('.preview-level').on 'click', ->
      if not alreadyCreatedGame
        $preview = $('.preview-level')
        $preview.text('Loading...')
        $preview.addClass('disabled')
        $preview.attr('alt', 'This may take a minute')
        HashManager.disableUpdateHash()
        window.CURRENT_LEVEL = level # Game uses this instead of parsing the hash
        fn = ->
          exportGeometry(SceneManager)
          GAME(SceneManager)
          alreadyCreatedGame = true
          $preview.text('Loaded')
        setTimeout(fn, 10)

    window.exportGeometry = -> exportGeometry(SceneManager)
    window.exportLevelMap = ->
      console.warn 'You have to refresh the page if you have made edits'
      foo = []
      level.getMap().forEach (x, y, z, color, orientation) ->
        ret = [x, y, z, color]
        ret.push(orientation) if orientation
        foo.push(ret)
      console.log(JSON.stringify(foo))


    window.exportImage = ->
      iconMaker = new IconMaker(SceneManager)
      for color in [0..level.getPalette().size-1]
        image = new Image()
        image.src = iconMaker.renderVoxel(VoxelFactory.freshVoxel(color, false))
        $img = $(image)
        $img.attr('data-color', ''+color)
        $img.addClass('color')

        $color = $("i.color[data-color=#{color}]")
        if $color[0]
          $color.replaceWith($img)
        else
          addColorToPalette(color)
          $("i.color[data-color=#{color}]").replaceWith($img)

      iconMaker.dispose()





    # exportImage()
    # return



    cameraHandlers = (id, cameraManager) ->

      updateLabel = ->
        {theta, phi} = cameraManager.getRotation()
        theta = Math.round(theta / 180).mod(4)
        label = switch theta
          when 0 then 'X'
          when 1 then 'Z'
          when 2 then '-X'
          when 3 then '-Z'
          else '??'
        $("##{id} .axis-label").text(label)

      updateLabel()
      setInterval updateLabel, 1000

      $("##{id} .axis-label").on 'click', ->
        {theta, phi} = cameraManager.getRotation()
        theta += 360
        theta -= 720 if theta >= 720
        cameraManager.rotateCameraTo(theta, phi)
        updateLabel()

      $("##{id} .rotate-left").on 'click', ->
        {theta, phi} = cameraManager.getRotation()
        theta -= 180
        theta += 720 if theta < 0
        cameraManager.rotateCameraTo(theta, phi)
        updateLabel()

      $("##{id} .rotate-right").on 'click', ->
        {theta, phi} = cameraManager.getRotation()
        theta += 180
        theta -= 720 if theta >= 720
        cameraManager.rotateCameraTo(theta, phi)
        updateLabel()

      $("##{id} .zoom-in").on 'click', ->
        cameraManager.zoom(100)

      $("##{id} .zoom-out").on 'click', ->
        cameraManager.zoom(-100)

    cameraHandlers('axis-camera-controls', AxisCamera)
    cameraHandlers('main-camera-controls', MainCamera)

    $('#axis-camera-controls .rotate-main').on 'click', ->
      {theta, phi} = AxisCamera.getRotation()
      MainCamera.rotateCameraTo(theta, phi)



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
      foo = ColorManager.colors[idx] or [0,0,0]
      colorBox.parent().attr "data-color", "#" + ColorUtils.rgb2hex(foo)
      colorBox.css "background", "#" + ColorUtils.rgb2hex(foo)
      SceneManager.brush.children[0].material.color.setRGB foo[0], foo[1], foo[2]  if ColorManager.currentColor is idx and SceneManager.brush
      return


    initEditor = ->
      bindEventsAndPlugins()
      container = document.getElementById("editor-area")
      SceneManager.prepare(container)
      # build all the pallette pngs
      exportImage()
      SceneManager.init(container)
      container.appendChild(SceneManager.renderer.domElement)
      KeyMouse.attachEvents()
      level.getMap().forEach (x, y, z, color, orientation) ->

        # Center the voxels since they are 1x1x1
        x = x * (16/16) + (16/16)/2
        y = y * (16/16) + (16/16)/2
        z = z * (16/16) + (16/16)/2

        SceneManager.addVoxel(x, y, z, color, orientation)

      HashManager.updateHash()
      return

    setTimeout(initEditor, 2000) # Wait for all the textures to load first TODO: HACK
    requestAnimationFrame(window).on "data", (args...) -> SceneManager.render(args...)




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

      # HashManager.buildFromHash()
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
    SceneManager.brush.children[0].material.color.setRGB(ColorManager.colors[idx][0], ColorManager.colors[idx][1], ColorManager.colors[idx][2])
    if Input.startPosition and Input.endPosition
      # Fill in with voxels
      sort = (a, b) ->
        return [a, b] if a < b
        return [b, a]
      {x:x1, y:y1, z:z1} = Input.startPosition
      {x:x2, y:y2, z:z2} = Input.endPosition
      Input.startPosition = null
      Input.endPosition = null
      Interactions.removeRectangle()

      [x1, x2] = sort(x1, x2)
      [y1, y2] = sort(y1, y2)
      [z1, z2] = sort(z1, z2)
      for x in [x1..x2] by (16/16)
        for y in [y1..y2] by (16/16)
          for z in [z1..z2] by (16/16)
            SceneManager.addVoxel(x, y, z, idx)
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



  showWelcome = ->
    seenWelcome = localStorage.getItem("seenWelcome")
    return $("#welcome").modal()  if seenWelcome
    localStorage.setItem "seenWelcome", true
    return


  showWelcome()



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
      x: (v.position.x - 8) / (16/16)
      y: (v.position.y - 8) / (16/16)
      z: (v.position.z - 8) / (16/16)
      c: v.wireMesh.material.color.getHexString()
    )
    console.log exportFunction(voxelsReal)
    return

  return
