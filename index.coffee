THREE = require("three")
raf = require("raf")

# var lsb = require('lsb')
# var Convert = require('voxel-critter/lib/convert.js')
# var ndarray = require('ndarray')
# var ndarrayFill = require('ndarray-fill')
ColorUtils = require("./src/color-utils")
window.startEditor = ->
  container = null
  camera = renderer = brush = axisCamera = null
  projector = plane = scene = grid = shareDialog = null
  mouse2D = mouse3D = raycaster = objectHovered = null

  isShiftDown = false
  isCtrlDown = false
  isMouseRotating = false
  isMouseDown = false
  isAltDown = false
  onMouseDownPosition = new THREE.Vector2()
  onMouseDownPhi = 60
  onMouseDownTheta = 45
  radius = 1600
  theta = 90
  phi = 60
  target = new THREE.Vector3( 0, 200, 0 ) # -1200, 300, 900
  color = 0
  CubeMaterial = THREE.MeshBasicMaterial
  cube = new THREE.CubeGeometry( 50, 50, 50 )
  wireframeCube = new THREE.CubeGeometry(50.5, 50.5 , 50.5)
  wireframe = true
  fill = true
  animation = false
  animating = false
  animationInterval = null
  manualAnimating = false
  wireframeOptions = { color: 0x000000, wireframe: true, wireframeLinewidth: 1, opacity: 0.8 }
  wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
  animationFrames = []
  currentFrame = 0


  # -1200, 300, 900

  #var colors = ['000000', 'FFF500', ].map(function(c) { return ColorUtils.hex2rgb(c) })
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
  addVoxel = (x, y, z, c) ->
    cubeMaterial = new CubeMaterial(
      vertexColors: THREE.VertexColors
      transparent: true
    )
    col = colors[c] or colors[0]
    cubeMaterial.color.setRGB col[0], col[1], col[2]
    wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
    wireframeMaterial.color.setRGB col[0] - 0.05, col[1] - 0.05, col[2] - 0.05
    voxel = new THREE.Mesh(cube, cubeMaterial)
    voxel.wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial)
    voxel.isVoxel = true
    voxel.position.x = x
    voxel.position.y = y
    voxel.position.z = z
    voxel.wireMesh.position.copy voxel.position
    voxel.wireMesh.visible = wireframe
    voxel.matrixAutoUpdate = false
    voxel.updateMatrix()
    voxel.name = x + "," + y + "," + z
    voxel.overdraw = true
    scene.add voxel
    scene.add voxel.wireMesh
    return
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
    brush.children[0].material.color.setRGB colors[idx][0], colors[idx][1], colors[idx][2]  if color is idx and brush
    return
  zoom = (delta) ->
    origin =
      x: 0
      y: 0
      z: 0

    distance = camera.position.distanceTo(origin)
    tooFar = distance > 6000
    tooClose = Math.abs(camera.top) < 1000
    return  if delta > 0 and tooFar
    return  if delta < 0 and tooClose
    radius = distance # for mouse drag calculations to be correct
    aspect = container.clientWidth / container.clientHeight
    camera.top += delta / 2
    camera.bottom -= delta / 2
    camera.left -= delta * aspect / 2
    camera.right += delta * aspect / 2

    # camera.updateMatrix();
    camera.updateProjectionMatrix()
    camera.translateZ delta
    return
  setIsometricAngle = ->
    theta += 90
    camera.position.x = radius * Math.sin(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
    camera.position.y = radius * Math.sin(phi * Math.PI / 360)
    camera.position.z = radius * Math.cos(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
    camera.updateMatrix()
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
      scene.children.filter((el) ->
        el.isVoxel
      ).map (mesh) ->
        scene.remove mesh.wireMesh
        scene.remove mesh
        return

      frameMask = "A"
      frameMask = "A" + currentFrame  unless currentFrame is 0
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
    target = $(e.currentTarget)
    idx = +target.find(".color").attr("data-color")
    color = idx
    brush.children[0].material.color.setRGB colors[idx][0], colors[idx][1], colors[idx][2]
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

    #camera = new THREE.PerspectiveCamera( 40, container.clientWidth / container.clientHeight, 1, 10000 )

    # Grid

    # Plane

    # Brush

    # Lights
    mousewheel = (event) ->

      # prevent zoom if a modal is open
      zoom event.wheelDeltaY or event.detail  if $(".modal").hasClass("in")
    bindEventsAndPlugins()
    container = document.getElementById("editor-area")
    camera = new THREE.OrthographicCamera(container.clientWidth / -1, container.clientWidth / 1, container.clientHeight / 1, container.clientHeight / -1, 1, 10000)
    camera.position.x = radius * Math.sin(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
    camera.position.y = radius * Math.sin(phi * Math.PI / 360)
    camera.position.z = radius * Math.cos(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
    axisCamera = new THREE.OrthographicCamera(container.clientWidth / -2, container.clientWidth / 2, container.clientHeight / 2, container.clientHeight / -2, 1, 10000)
    scene = new THREE.Scene()
    window.scene = scene
    size = 500
    step = 50
    geometry = new THREE.Geometry()
    i = -size

    while i <= size
      geometry.vertices.push new THREE.Vector3(-size, 0, i)
      geometry.vertices.push new THREE.Vector3(size, 0, i)
      geometry.vertices.push new THREE.Vector3(i, 0, -size)
      geometry.vertices.push new THREE.Vector3(i, 0, size)
      i += step
    material = new THREE.LineBasicMaterial(
      color: 0x000000
      opacity: 0.2
    )
    line = new THREE.Line(geometry, material)
    line.type = THREE.LinePieces
    grid = line
    scene.add line
    projector = new THREE.Projector()
    plane = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), new THREE.MeshBasicMaterial())
    plane.rotation.x = -Math.PI / 2
    plane.visible = false
    plane.isPlane = true
    scene.add plane
    mouse2D = new THREE.Vector3(0, 10000, 0.5)
    brushMaterials = [
      new CubeMaterial(
        vertexColors: THREE.VertexColors
        opacity: 0.5
        transparent: true
      )
      new THREE.MeshBasicMaterial(
        color: 0x000000
        wireframe: true
      )
    ]
    brushMaterials[0].color.setRGB colors[0][0], colors[0][1], colors[0][2]
    brush = THREE.SceneUtils.createMultiMaterialObject(cube, brushMaterials)
    brush.isBrush = true
    brush.position.y = 2000
    brush.overdraw = false
    scene.add brush
    ambientLight = new THREE.AmbientLight(0x606060)
    scene.add ambientLight
    directionalLight = new THREE.DirectionalLight(0xffffff)
    directionalLight.position.set(1, 0.75, 0.5).normalize()
    scene.add directionalLight
    hasWebGL = (->
      try
        return !!window.WebGLRenderingContext and !!document.createElement("canvas").getContext("experimental-webgl")
      catch e
        return false
      return
    )()
    if hasWebGL
      renderer = new THREE.WebGLRenderer(antialias: true)
    else
      renderer = new THREE.CanvasRenderer()
    renderer.setSize container.clientWidth, container.clientHeight
    container.appendChild renderer.domElement
    renderer.domElement.addEventListener "mousemove", onDocumentMouseMove, false
    renderer.domElement.addEventListener "mousedown", onDocumentMouseDown, false
    renderer.domElement.addEventListener "mouseup", onDocumentMouseUp, false
    document.addEventListener "keydown", onDocumentKeyDown, false
    document.addEventListener "keyup", onDocumentKeyUp, false
    window.addEventListener "DOMMouseScroll", mousewheel, false
    window.addEventListener "mousewheel", mousewheel, false
    window.addEventListener "resize", onWindowResize, false
    buildFromHash()  if window.location.hash
    updateHash()
    return
  onWindowResize = ->
    camera.aspect = container.clientWidth / container.clientHeight
    camera.updateProjectionMatrix()
    renderer.setSize container.clientWidth, container.clientHeight
    interact()
    return
  getIntersecting = ->
    intersectable = []
    scene.children.map (c) ->
      intersectable.push c  if c.isVoxel or c.isPlane
      return

    if raycaster
      intersections = raycaster.intersectObjects(intersectable)
      if intersections.length > 0
        intersect = (if intersections[0].object.isBrush then intersections[1] else intersections[0])
        intersect
  interact = ->
    return  if typeof raycaster is "undefined"
    if objectHovered
      objectHovered.material.opacity = 1
      objectHovered = null
    intersect = getIntersecting()
    if intersect
      updateBrush = ->
        brush.position.x = Math.floor(position.x / 50) * 50 + 25
        brush.position.y = Math.floor(position.y / 50) * 50 + 25
        brush.position.z = Math.floor(position.z / 50) * 50 + 25
        return
      normal = intersect.face.normal.clone()
      normal.applyMatrix4 intersect.object.matrixRotationWorld
      position = new THREE.Vector3().addVectors(intersect.point, normal)
      newCube = [
        Math.floor(position.x / 50)
        Math.floor(position.y / 50)
        Math.floor(position.z / 50)
      ]
      if isAltDown
        brush.currentCube = newCube  unless brush.currentCube
        if brush.currentCube.join("") isnt newCube.join("")
          if isShiftDown
            if intersect.object isnt plane
              scene.remove intersect.object.wireMesh
              scene.remove intersect.object
          else
            addVoxel brush.position.x, brush.position.y, brush.position.z, color  unless brush.position.y is 2000
        updateBrush()
        updateHash()
        return brush.currentCube = newCube
      else if isShiftDown
        if intersect.object isnt plane
          objectHovered = intersect.object
          objectHovered.material.opacity = 0.5
          brush.position.y = 2000
          return
      else
        updateBrush()
        return
    brush.position.y = 2000
    return
  onDocumentMouseMove = (event) ->
    event.preventDefault()
    unless isMouseRotating

      # change the mouse cursor to a + letting the user know they can rotate
      intersecting = getIntersecting()
      unless intersecting
        container.classList.add "rotatable"
      else
        container.classList.remove "rotatable"
    if isMouseDown is 1 # left click

      # Rotate only if you clicked outside a block
      unless intersecting
        theta = -((event.clientX - onMouseDownPosition.x) * 0.5) + onMouseDownTheta
        phi = ((event.clientY - onMouseDownPosition.y) * 0.5) + onMouseDownPhi
        phi = Math.min(180, Math.max(0, phi))
        camera.position.x = target.x + radius * Math.sin(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
        camera.position.y = target.y + radius * Math.sin(phi * Math.PI / 360)
        camera.position.z = target.z + radius * Math.cos(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
        camera.updateMatrix()
    else if isMouseDown is 2 # middle click
      theta = -((event.clientX - onMouseDownPosition.x) * 0.5) + onMouseDownTheta
      phi = ((event.clientY - onMouseDownPosition.y) * 0.5) + onMouseDownPhi
      phi = Math.min(180, Math.max(0, phi))
      target.x += Math.sin(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
      target.y += Math.sin(phi * Math.PI / 360)
      target.z += Math.cos(theta * Math.PI / 360) * Math.cos(phi * Math.PI / 360)
    mouse2D.x = (event.clientX / container.clientWidth) * 2 - 1
    mouse2D.y = -(event.clientY / container.clientHeight) * 2 + 1
    interact()
    return
  onDocumentMouseDown = (event) ->
    event.preventDefault()
    isMouseDown = event.which
    onMouseDownTheta = theta
    onMouseDownPhi = phi
    onMouseDownPosition.x = event.clientX
    onMouseDownPosition.y = event.clientY
    isMouseRotating = not getIntersecting()
    return
  onDocumentMouseUp = (event) ->
    event.preventDefault()
    isMouseDown = false
    isMouseRotating = false
    onMouseDownPosition.x = event.clientX - onMouseDownPosition.x
    onMouseDownPosition.y = event.clientY - onMouseDownPosition.y
    return  if onMouseDownPosition.length() > 5
    intersect = getIntersecting()
    if intersect
      if isShiftDown
        unless intersect.object is plane
          scene.remove intersect.object.wireMesh
          scene.remove intersect.object
      else
        addVoxel brush.position.x, brush.position.y, brush.position.z, color  unless brush.position.y is 2000
    updateHash()
    render()
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
        isShiftDown = true
      when 17
        isCtrlDown = true
      when 18
        isAltDown = true
      when 65
        setIsometricAngle()
  onDocumentKeyUp = (event) ->
    switch event.keyCode
      when 16
        isShiftDown = false
      when 17
        isCtrlDown = false
      when 18
        isAltDown = false

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
    frameMask = "A" + currentFrame  unless currentFrame is 0
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
        addVoxel current.x * 50 + 25, current.y * 50 + 25, current.z * 50 + 25, current.c  if code.charAt(0) is "1"
    updateHash()
    return
  updateHash = ->
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

    for i of scene.children
      object = scene.children[i]
      if object.isVoxel and object isnt plane and object isnt brush
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
    $(".play-level").attr "href", "http://philschatz.com/game/" + outHash
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

  # skips every fourth byte when encoding images,
  # i.e. leave the alpha channel
  # alone and only change RGB
  pickRGB = (idx) ->
    idx + (idx / 3) | 0
  exportImage = (width, height) ->
    canvas = getExportCanvas(width, height)
    image = new Image
    image.src = canvas.toDataURL()
    image
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
  save = ->
    window.open renderer.domElement.toDataURL("image/png"), "mywindow"
    return
  render = ->
    camera.lookAt target
    raycaster = projector.pickingRay(mouse2D.clone(), camera)
    renderer.setViewport()
    renderer.setScissor() # TODO: this might ned to become 0,0,renderer.domElement.width,renderer.domElement.height
    renderer.enableScissorTest false
    renderer.setClearColor new THREE.Color().setRGB(1, 1, 1)
    renderer.render scene, camera

    # return;

    # camera 2
    windowWidth = container.clientWidth
    windowHeight = container.clientHeight
    view =
      left: 3 / 4
      bottom: 0
      width: 1 / 4
      height: 1 / 4
      background: new THREE.Color().setRGB(0.5, 0.5, 0.7)

    left = Math.floor(windowWidth * view.left)
    bottom = Math.floor(windowHeight * view.bottom)
    width = Math.floor(windowWidth * view.width)
    height = Math.floor(windowHeight * view.height)
    renderer.setViewport left, bottom, width, height
    renderer.setScissor left, bottom, width, height
    renderer.enableScissorTest true
    renderer.setClearColor view.background
    axisCamera.position.x = 1000
    axisCamera.position.y = target.y
    axisCamera.position.z = target.z
    axisCamera.lookAt target
    renderer.render scene, axisCamera
    return
  container = undefined
  camera = undefined
  renderer = undefined
  brush = undefined
  axisCamera = undefined
  projector = undefined
  plane = undefined
  scene = undefined
  grid = undefined
  shareDialog = undefined
  mouse2D = undefined
  mouse3D = undefined
  raycaster = undefined
  objectHovered = undefined
  isShiftDown = false
  isCtrlDown = false
  isMouseRotating = false
  isMouseDown = false
  isAltDown = false
  onMouseDownPosition = new THREE.Vector2()
  onMouseDownPhi = 60
  onMouseDownTheta = 45
  radius = 1600
  theta = 90
  phi = 60
  target = new THREE.Vector3(0, 200, 0)
  color = 0
  CubeMaterial = THREE.MeshBasicMaterial
  cube = new THREE.CubeGeometry(50, 50, 50)
  wireframeCube = new THREE.CubeGeometry(50.5, 50.5, 50.5)
  wireframe = true
  fill = true
  animation = false
  animating = false
  animationInterval = undefined
  manualAnimating = false
  sliderEl = undefined
  playPauseEl = undefined
  wireframeOptions =
    color: 0x000000
    wireframe: true
    wireframeLinewidth: 1
    opacity: 0.8

  wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
  animationFrames = []
  currentFrame = 0
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
  c = 0

  while c < 12
    addColorToPalette c
    c++
  showWelcome()
  init()
  raf(window).on "data", render
  exports.viewInstructions = ->
    $("#welcome").modal()
    return

  exports.reset = ->
    window.location.replace "#/"
    scene.children.filter((el) ->
      el.isVoxel
    ).map (mesh) ->
      scene.remove mesh
      return

    return

  exports.setColor = (idx) ->
    $("i[data-color=\"" + idx + "\"]").click()
    return

  exports.showGrid = (bool) ->
    grid.material.visible = bool
    return

  $(".play-level").attr "href", "http://philschatz.com/game/" + window.location.hash
  window.exportMap = ->
    voxels = scene.children.filter((el) ->
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

# // camera 2
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
# renderer.setViewport( left, bottom, width, height );
# renderer.setScissor( left, bottom, width, height );
# renderer.enableScissorTest ( true );
# renderer.setClearColor( view.background );
#
# axisCamera.position.x = target.x;
# axisCamera.position.y = 1000;
# axisCamera.position.z = target.z;
# axisCamera.lookAt(target);
# renderer.render(scene, axisCamera)

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
# renderer.setViewport( left, bottom, width, height );
# renderer.setScissor( left, bottom, width, height );
# renderer.enableScissorTest ( true );
# renderer.setClearColor( view.background );
#
# axisCamera.position.x = target.x;
# axisCamera.position.y = target.y;
# axisCamera.position.z = 1000;
# axisCamera.lookAt(target);
#
# renderer.render(scene, axisCamera)
