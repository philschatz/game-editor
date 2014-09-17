THREE = require("three")
raf = require("raf")

# var lsb = require('lsb')
# var Convert = require('voxel-critter/lib/convert.js')
# var ndarray = require('ndarray')
# var ndarrayFill = require('ndarray-fill')
ColorUtils = require './src/color-utils'
Input = require('./src/input-manager')(THREE)
SceneManager = require('./src/scene-manager')(THREE, Input)

window.startEditor = ->
  container = null
  shareDialog = null
  mouse3D = objectHovered = null

  target = new THREE.Vector3( 0, 200, 0 ) # -1200, 300, 900
  color = 0

  fill = true


  colors = [
    "000000"
    "2ECC71"
    "3498DB"
    "34495E"
    "E67E22"
    "ECF0F1"
    "FFF500"
    "FF0000"
    "00FF38"
    "BD00FF"
    "08c9ff"
    "D32020"
  ].map((c) ->
    ColorUtils.hex2rgb c
  )


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
  #   var colors = [undefined]
  #   data.colors.map(function(c) {
  #     colors.push('#' + ColorUtils.rgb2hex(c))
  #   })
  #
  #   function generateVoxels(x, y, z) {
  #     var offset = [x + l[0], y + l[1], z + l[2]]
  #     var val = data.voxels[offset.join('|')]
  #     return data.colors[val] ? val + 1: 0
  #   }
  #
  #   ndarrayFill(voxels, generateVoxels)
  #   return {voxels: voxels, colors: colors}
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
    colorBox.parent().attr "data-color", "#" + ColorUtils.rgb2hex(colors[idx])
    colorBox.css "background", "#" + ColorUtils.rgb2hex(colors[idx])
    SceneManager.brush.children[0].material.color.setRGB colors[idx][0], colors[idx][1], colors[idx][2]  if color is idx and SceneManager.brush
    return

  zoom = (delta) ->
    origin =
      x: 0
      y: 0
      z: 0

    distance = SceneManager.camera.position.distanceTo(origin)
    tooFar = distance > 6000
    tooClose = Math.abs(SceneManager.camera.top) < 1000
    return  if delta > 0 and tooFar
    return  if delta < 0 and tooClose
    SceneManager.radius = distance # for mouse drag calculations to be correct
    aspect = container.clientWidth / container.clientHeight
    SceneManager.camera.top += delta / 2
    SceneManager.camera.bottom -= delta / 2
    SceneManager.camera.left -= delta * aspect / 2
    SceneManager.camera.right += delta * aspect / 2

    # SceneManager.camera.updateMatrix();
    SceneManager.camera.updateProjectionMatrix()
    SceneManager.camera.translateZ delta
    return


  setIsometricAngle = ->
    SceneManager.theta += 90
    SceneManager.camera.position.x = SceneManager.radius * Math.sin(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
    SceneManager.camera.position.y = SceneManager.radius * Math.sin(SceneManager.phi * Math.PI / 360)
    SceneManager.camera.position.z = SceneManager.radius * Math.cos(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
    SceneManager.camera.updateMatrix()
    return


  addColor = (e) ->

    #add new color
    colors.push [
      0.0
      0.0
      0.0
    ]
    idx = colors.length - 1
    color = idx
    addColorToPalette idx
    updateHash()
    updateColor idx
    return


  updateColor = (idx) ->
    color = idx
    picker = $("i[data-color=\"" + idx + "\"]").parent().colorpicker("show")
    picker.on "changeColor", (e) ->
      colors[idx] = ColorUtils.hex2rgb(e.color.toHex())
      addColorToPalette idx

      # todo:  better way to update color of existing blocks
      SceneManager.scene.children.filter((el) ->
        el.isVoxel
      ).map (mesh) ->
        SceneManager.scene.remove mesh.wireMesh
        SceneManager.scene.remove mesh
        return

      frameMask = "A"
      buildFromHash frameMask
      return

    picker.on "hide", (e) ->

      # todo:  add a better remove for the colorpicker.
      picker.unbind "click.colorpicker"
      return

    return


  changeColor = (e) ->
    target = $(e.currentTarget)
    idx = +target.find(".color").attr("data-color")
    updateColor idx
    false # eat the event


  pickColor = (e) ->
    targetEl = $(e.currentTarget)
    idx = +targetEl.find(".color").attr("data-color")
    color = idx
    SceneManager.brush.children[0].material.color.setRGB colors[idx][0], colors[idx][1], colors[idx][2]
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

    # Lights
    mousewheel = (event) ->
      # prevent zoom if a modal is open
      zoom event.wheelDeltaY or event.detail  if $(".modal").hasClass("in")

    bindEventsAndPlugins()
    container = document.getElementById("editor-area")
    SceneManager.init(container)
    container.appendChild(SceneManager.renderer.domElement)
    SceneManager.renderer.domElement.addEventListener "mousemove", onDocumentMouseMove, false
    SceneManager.renderer.domElement.addEventListener "mousedown", onDocumentMouseDown, false
    SceneManager.renderer.domElement.addEventListener "mouseup", onDocumentMouseUp, false
    document.addEventListener "keydown", onDocumentKeyDown, false
    document.addEventListener "keyup", onDocumentKeyUp, false
    window.addEventListener "DOMMouseScroll", mousewheel, false
    window.addEventListener "mousewheel", mousewheel, false
    window.addEventListener "resize", onWindowResize, false
    buildFromHash()  if window.location.hash
    updateHash()
    return


  onWindowResize = ->
    SceneManager.camera.aspect = container.clientWidth / container.clientHeight
    SceneManager.camera.updateProjectionMatrix()
    SceneManager.renderer.setSize container.clientWidth, container.clientHeight
    interact()
    return


  getIntersecting = ->
    intersectable = []
    SceneManager.scene.children.map (c) ->
      intersectable.push c  if c.isVoxel or c.isPlane
      return

    if SceneManager.raycaster
      intersections = SceneManager.raycaster.intersectObjects(intersectable)
      if intersections.length > 0
        intersect = (if intersections[0].object.isBrush then intersections[1] else intersections[0])
        intersect


  interact = ->
    return  if typeof SceneManager.raycaster is "undefined"
    if objectHovered
      objectHovered.material.opacity = 1
      objectHovered = null
    intersect = getIntersecting()
    if intersect
      updateBrush = ->
        SceneManager.brush.position.x = Math.floor(position.x / 50) * 50 + 25
        SceneManager.brush.position.y = Math.floor(position.y / 50) * 50 + 25
        SceneManager.brush.position.z = Math.floor(position.z / 50) * 50 + 25
        return
      normal = intersect.face.normal.clone()
      normal.applyMatrix4 intersect.object.matrixRotationWorld
      position = new THREE.Vector3().addVectors(intersect.point, normal)
      newCube = [
        Math.floor(position.x / 50)
        Math.floor(position.y / 50)
        Math.floor(position.z / 50)
      ]
      if Input.isAltDown
        SceneManager.brush.currentCube = newCube  unless SceneManager.brush.currentCube
        if SceneManager.brush.currentCube.join("") isnt newCube.join("")
          if Input.isShiftDown
            if intersect.object isnt SceneManager.plane
              SceneManager.scene.remove intersect.object.wireMesh
              SceneManager.scene.remove intersect.object
          else
            SceneManager.addVoxel SceneManager.brush.position.x, SceneManager.brush.position.y, SceneManager.brush.position.z, colors[color]  unless SceneManager.brush.position.y is 2000
        updateBrush()
        updateHash()
        return SceneManager.brush.currentCube = newCube
      else if Input.isShiftDown
        if intersect.object isnt SceneManager.plane
          objectHovered = intersect.object
          objectHovered.material.opacity = 0.5
          SceneManager.brush.position.y = 2000
          return
      else
        updateBrush()
        return
    SceneManager.brush.position.y = 2000
    return


  onDocumentMouseMove = (event) ->
    event.preventDefault()
    unless Input.isMouseRotating

      # change the mouse cursor to a + letting the user know they can rotate
      intersecting = getIntersecting()
      unless intersecting
        container.classList.add "rotatable"
      else
        container.classList.remove "rotatable"
    if Input.isMouseDown is 1 # left click

      # Rotate only if you clicked outside a block
      unless intersecting
        SceneManager.theta = -((event.clientX - Input.onMouseDownPosition.x) * 0.5) + Input.onMouseDownTheta
        SceneManager.phi = ((event.clientY - Input.onMouseDownPosition.y) * 0.5) + Input.onMouseDownPhi
        SceneManager.phi = Math.min(180, Math.max(0, SceneManager.phi))
        SceneManager.camera.position.x = target.x + SceneManager.radius * Math.sin(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
        SceneManager.camera.position.y = target.y + SceneManager.radius * Math.sin(SceneManager.phi * Math.PI / 360)
        SceneManager.camera.position.z = target.z + SceneManager.radius * Math.cos(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
        SceneManager.camera.updateMatrix()
    else if Input.isMouseDown is 2 # middle click
      SceneManager.theta = -((event.clientX - Input.onMouseDownPosition.x) * 0.5) + Input.onMouseDownTheta
      SceneManager.phi = ((event.clientY - Input.onMouseDownPosition.y) * 0.5) + Input.onMouseDownPhi
      SceneManager.phi = Math.min(180, Math.max(0, SceneManager.phi))
      target.x += Math.sin(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
      target.y += Math.sin(SceneManager.phi * Math.PI / 360)
      target.z += Math.cos(SceneManager.theta * Math.PI / 360) * Math.cos(SceneManager.phi * Math.PI / 360)
    Input.mouse2D.x = (event.clientX / container.clientWidth) * 2 - 1
    Input.mouse2D.y = -(event.clientY / container.clientHeight) * 2 + 1
    interact()
    return


  onDocumentMouseDown = (event) ->
    event.preventDefault()
    Input.isMouseDown = event.which
    Input.onMouseDownTheta = SceneManager.theta
    Input.onMouseDownPhi = SceneManager.phi
    Input.onMouseDownPosition.x = event.clientX
    Input.onMouseDownPosition.y = event.clientY
    Input.isMouseRotating = not getIntersecting()
    return


  onDocumentMouseUp = (event) ->
    event.preventDefault()
    Input.isMouseDown = false
    Input.isMouseRotating = false
    Input.onMouseDownPosition.x = event.clientX - Input.onMouseDownPosition.x
    Input.onMouseDownPosition.y = event.clientY - Input.onMouseDownPosition.y
    return  if Input.onMouseDownPosition.length() > 5
    intersect = getIntersecting()
    if intersect
      if Input.isShiftDown
        unless intersect.object is SceneManager.plane
          SceneManager.scene.remove intersect.object.wireMesh
          SceneManager.scene.remove intersect.object
      else
        SceneManager.addVoxel SceneManager.brush.position.x, SceneManager.brush.position.y, SceneManager.brush.position.z, colors[color]  unless SceneManager.brush.position.y is 2000
    updateHash()
    SceneManager.render(target)
    interact()
    return


  onDocumentKeyDown = (event) ->
    console.log event.keyCode
    switch event.keyCode
      when 189
        zoom 100
      when 187
        zoom -100
      when 49
        exports.setColor 0
      when 50
        exports.setColor 1
      when 51
        exports.setColor 2
      when 52
        exports.setColor 3
      when 53
        exports.setColor 4
      when 54
        exports.setColor 5
      when 55
        exports.setColor 6
      when 56
        exports.setColor 7
      when 57
        exports.setColor 8
      when 48
        exports.setColor 9
      when 16
        Input.isShiftDown = true
      when 17
        Input.isCtrlDown = true
      when 18
        Input.isAltDown = true
      when 65
        setIsometricAngle()


  onDocumentKeyUp = (event) ->
    switch event.keyCode
      when 16
        Input.isShiftDown = false
      when 17
        Input.isCtrlDown = false
      when 18
        Input.isAltDown = false

  # Array.prototype.diff = function(a) {
  #   return this.filter(function(i) {return !(a.indexOf(i) > -1);});
  # };
  buildFromHash = (hashMask) ->
    hash = window.location.hash.substr(1)
    hashChunks = hash.split(":")
    chunks = {}
    animationFrames = []
    j = 0
    n = hashChunks.length

    while j < n
      chunk = hashChunks[j].split("/")
      chunks[chunk[0]] = chunk[1]
      animationFrames.push chunk[1]  if chunk[0].charAt(0) is "A"
      j++
    if (not hashMask or hashMask is "C") and chunks["C"]

      # decode colors
      hexColors = chunks["C"]
      c = 0
      nC = hexColors.length / 6

      while c < nC
        hex = hexColors.substr(c * 6, 6)
        colors[c] = ColorUtils.hex2rgb(hex)
        addColorToPalette c
        c++
    frameMask = "A"
    if (not hashMask or hashMask is frameMask) and chunks[frameMask]

      # decode geo
      current =
        x: 0
        y: 0
        z: 0
        c: 0

      data = decode(chunks[frameMask])
      i = 0
      l = data.length
      while i < l
        code = data[i++].toString(2)
        current.x += data[i++] - 32  if code.charAt(1) is "1"
        current.y += data[i++] - 32  if code.charAt(2) is "1"
        current.z += data[i++] - 32  if code.charAt(3) is "1"
        current.c += data[i++] - 32  if code.charAt(4) is "1"
        SceneManager.addVoxel current.x * 50 + 25, current.y * 50 + 25, current.z * 50 + 25, colors[current.c]  if code.charAt(0) is "1"
    updateHash()
    return


  updateHash = ->
    currentFrame = 0
    animationFrames = []
    data = []
    voxels = []
    code = undefined
    current =
      x: 0
      y: 0
      z: 0
      c: 0

    last =
      x: 0
      y: 0
      z: 0
      c: 0

    for i of SceneManager.scene.children
      object = SceneManager.scene.children[i]
      if object.isVoxel and object isnt SceneManager.plane and object isnt SceneManager.brush
        current.x = (object.position.x - 25) / 50
        current.y = (object.position.y - 25) / 50
        current.z = (object.position.z - 25) / 50
        colorString = [
          "r"
          "g"
          "b"
        ].map((col) ->
          object.material.color[col]
        ).join("")

        # this string matching of floating point values to find an index seems a little sketchy
        i = 0

        while i < colors.length
          current.c = i  if colors[i].join("") is colorString
          i++
        voxels.push
          x: current.x
          y: current.y + 1
          z: current.z
          c: current.c + 1

        code = 0
        code += 1000  unless current.x is last.x
        code += 100  unless current.y is last.y
        code += 10  unless current.z is last.z
        code += 1  unless current.c is last.c
        code += 10000
        data.push parseInt(code, 2)
        unless current.x is last.x
          data.push current.x - last.x + 32
          last.x = current.x
        unless current.y is last.y
          data.push current.y - last.y + 32
          last.y = current.y
        unless current.z is last.z
          data.push current.z - last.z + 32
          last.z = current.z
        unless current.c is last.c
          data.push current.c - last.c + 32
          last.c = current.c
    data = encode(data)
    animationFrames[currentFrame] = data
    cData = ""

    # ignore color data
    # for (var i = 0; i < colors.length; i++){
    #   cData += ColorUtils.rgb2hex(colors[i]);
    # }
    outHash = "#" + ((if cData then ("C/" + cData) else ""))
    i = 0

    while i < animationFrames.length
      if i is 0
        outHash = outHash + ":A/" + animationFrames[i]
      else
        outHash = outHash + ":A" + i + "/" + animationFrames[i]
      i++

    # hack to ignore programmatic hash changes
    window.updatingHash = true
    window.location.replace outHash

    # Update the Play Level link
    $(".play-level").attr "href", "http://SceneManager.philschatz.com/game/" + outHash
    setTimeout (->
      window.updatingHash = false
      return
    ), 1
    voxels

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

  # https://gist.github.com/665235
  decode = (string) ->
    output = []
    string.split("").forEach (v) ->
      output.push "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(v)
      return
    output


  encode = (array) ->
    output = ""
    array.forEach (v) ->
      output += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(v)
      return
    output


  # Init code
  c = 0
  while c < 12
    addColorToPalette c
    c++
  showWelcome()
  init()
  raf(window).on "data", -> SceneManager.render(target)
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

  $(".play-level").attr "href", "http://SceneManager.philschatz.com/game/" + window.location.hash
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

# // SceneManager.camera 2
# windowWidth = container.clientWidth;
# windowHeight = container.clientHeight;
# view = {
#   left: 2/3,
#   bottom: 1/3,
#   width: 1/3,
#   height: 1/3,
#   background: new THREE.Color().setRGB( 0.7, 0.5, 0.5 )
# }
# var left   = Math.floor( windowWidth  * view.left );
# var bottom = Math.floor( windowHeight * view.bottom );
# var width  = Math.floor( windowWidth  * view.width );
# var height = Math.floor( windowHeight * view.height );
# SceneManager.renderer.setViewport( left, bottom, width, height );
# SceneManager.renderer.setScissor( left, bottom, width, height );
# SceneManager.renderer.enableScissorTest ( true );
# SceneManager.renderer.setClearColor( view.background );
#
# SceneManager.axisCamera.position.x = target.x;
# SceneManager.axisCamera.position.y = 1000;
# SceneManager.axisCamera.position.z = target.z;
# SceneManager.axisCamera.lookAt(target);
# SceneManager.renderer.render(SceneManager.scene, SceneManager.axisCamera)

# view = {
#   left: 2/3,
#   bottom: 2/3,
#   width: 1/3,
#   height: 1/3,
#   background: new THREE.Color().setRGB( 0.5, 0.7, 0.5 )
# }
# var left   = Math.floor( windowWidth  * view.left );
# var bottom = Math.floor( windowHeight * view.bottom );
# var width  = Math.floor( windowWidth  * view.width );
# var height = Math.floor( windowHeight * view.height );
# SceneManager.renderer.setViewport( left, bottom, width, height );
# SceneManager.renderer.setScissor( left, bottom, width, height );
# SceneManager.renderer.enableScissorTest ( true );
# SceneManager.renderer.setClearColor( view.background );
#
# SceneManager.axisCamera.position.x = target.x;
# SceneManager.axisCamera.position.y = target.y;
# SceneManager.axisCamera.position.z = 1000;
# SceneManager.axisCamera.lookAt(target);
#
# SceneManager.renderer.render(SceneManager.scene, SceneManager.axisCamera)
