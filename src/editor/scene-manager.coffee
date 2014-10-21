{SpriteAnimationHandler} = require '../sprite-animation'

MainCamera = require '../main-camera'
AxisCamera = require './axis-camera'

PaletteManager = require '../voxels/palette-manager'
VoxelFactory = require '../voxels/voxel-factory'

THREE = require '../three'
InputManager = require './input-manager' # ONLY useful for getting the mouse2d TODO: move this out

module.exports = new class SceneManager

    renderer: null
    brush: null
    scene: null

    plane: null

    _container: null
    _camera: null
    _target: new THREE.Vector3( 0, 4 * (16/16), 0 ) # -1200, 300, 900


    _CubeMaterial: THREE.MeshBasicMaterial
    _cube: new THREE.BoxGeometry( (16/16), (16/16), (16/16) )
    _axisCamera: null
    _projector: null
    _size: (16/16) * 10
    _step: (16/16)
    _showWireframe: true


    prepare: (@_container) ->
      window.scene = @scene = new THREE.Scene()
      hasWebGL = (->
        try
          return !!window.WebGLRenderingContext and !!document.createElement('canvas').getContext('experimental-webgl')
        catch e
          return false
        return
      )()
      if hasWebGL
        @renderer = new THREE.WebGLRenderer(antialias: false) # for *much* better FPS (60 no matter what I do)
      else
        @renderer = new THREE.CanvasRenderer()
      @renderer.setSize(@_container.clientWidth, @_container.clientHeight)


    init: (@_container) ->
      @renderer.setSize(@_container.clientWidth, @_container.clientHeight)
      width = 50 # @_container.clientWidth
      height = width * (@_container.clientHeight / @_container.clientWidth) # @_container.clientHeight
      @_camera = new THREE.OrthographicCamera(-1 * width, 1 * width, 1 * height,-1 * height, 1, 1000)
      # @_camera = new THREE.PerspectiveCamera(45, width/height, 1, 10000)
      MainCamera.init(@scene, @_camera, @_container, @_target)
      MainCamera.updateCamera({x:0, y:0, z:0})
      @_axisCamera = new THREE.OrthographicCamera(width / -2, width / 2, height / 2, height / -2, 1, 1000)

      AxisCamera.init(@scene, @_axisCamera, @_container, @_target)
      AxisCamera.updateCamera({x:0, y:0, z:0})

      geometry = new THREE.Geometry()
      i = -@_size

      while i <= @_size
        geometry.vertices.push new THREE.Vector3(-@_size, 0, i)
        geometry.vertices.push new THREE.Vector3(@_size, 0, i)
        geometry.vertices.push new THREE.Vector3(i, 0, -@_size)
        geometry.vertices.push new THREE.Vector3(i, 0, @_size)
        i += @_step
      material = new THREE.LineBasicMaterial(
        color: 0x000000
        opacity: 0.2
      )
      @grid = new THREE.Line(geometry, material)
      @grid.type = THREE.LinePieces
      @scene.add(@grid)
      @_projector = new THREE.Projector()
      @plane = new THREE.Mesh(new THREE.PlaneGeometry(20 * (16/16), 20 * (16/16)), new THREE.MeshBasicMaterial())
      @plane.rotation.x = -Math.PI / 2
      @plane.visible = false
      @plane.isPlane = true
      @plane.name = 'plane'
      @scene.add(@plane)
      brushMaterials = [
        new @_CubeMaterial(
          vertexColors: THREE.VertexColors
          opacity: 0.5
          transparent: true
        )
        new THREE.MeshBasicMaterial(
          color: 0x000000
          wireframe: true
        )
      ]
      brushMaterials[0].color.setRGB(0, 0, 0) # black
      @brush = THREE.SceneUtils.createMultiMaterialObject(@_cube, brushMaterials)
      @brush.isBrush = true
      @brush.position.y = 2000
      @brush.overdraw = false
      @scene.add(@brush)
      # ambientLight = new THREE.AmbientLight(0x0)
      # @scene.add(ambientLight)
      # directionalLight = new THREE.DirectionalLight(0xffffff)
      # directionalLight.position.set(0, 20, -100).normalize()
      # directionalLight.lookAt(@_target)
      # @scene.add directionalLight


    removeVoxel: (obj) ->
      # This calls Map.removeVoxel because there is no need to look up the voxel; we already have it

      @scene.remove(obj.wireMesh) if obj.wireMesh
      @scene.remove(obj)

      @currentMap().removeVoxel(Math.floor(obj.position.x), Math.floor(obj.position.y), Math.floor(obj.position.z))

    _addVoxel: (x, y, z, color) ->

      x = Math.floor(x) + .5
      y = Math.floor(y) + .5
      z = Math.floor(z) + .5

      wireframeCube = new THREE.BoxGeometry((16/16) + .5, (16/16) + .5 , (16/16) + .5)
      wireframeOptions =
        color: 0xEEEEEE
        wireframe: true
        wireframeLinewidth: 1
        opacity: 0.05

      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
      # wireframeMaterial.color.setRGB(0, 0, 0) # or color - .05

      voxel = VoxelFactory.freshVoxel(color, true) # true = addWireframe

      voxel.isVoxel = true
      voxel.colorCode = color

      voxel.position.x += x
      voxel.position.y += y
      voxel.position.z += z
      if voxel.wireMesh
        voxel.wireMesh.position.x = x
        voxel.wireMesh.position.y = y
        voxel.wireMesh.position.z = z
        voxel.wireMesh.visible = @_showWireframe
      voxel.matrixAutoUpdate = false
      voxel.updateMatrix()
      voxel.name ?= x + ',' + y + ',' + z
      voxel.overdraw = true
      @scene.add(voxel)
      @scene.add(voxel.wireMesh) if voxel.wireMesh
      return

    render: (elapsedMs) ->
      return console.warn 'Trying to render scene before initialized' unless @_camera

      SpriteAnimationHandler.update(elapsedMs)

      windowWidth = @_container.clientWidth
      windowHeight = @_container.clientHeight

      @_camera.lookAt(@_target)
      MainCamera.setRaycaster(@_projector.pickingRay(InputManager.mouse2D.clone(), @_camera))
      @renderer.setViewport(0, 0, windowWidth, windowHeight)
      @renderer.setScissor(0, 0, windowWidth, windowHeight)
      @renderer.enableScissorTest(false)
      @renderer.setClearColor(new THREE.Color().setRGB(1, 1, 1))
      @renderer.render(@scene, @_camera)

      # return;

      # @_camera 2
      view =
        left: 3 / 4
        bottom: 0
        width: 1 / 4
        height: 1 / 3
        background: new THREE.Color().setRGB(0.5, 0.5, 0.7)

      left = Math.floor(windowWidth * view.left)
      bottom = Math.floor(windowHeight * view.bottom)
      width = Math.floor(windowWidth * view.width)
      height = Math.floor(windowHeight * view.height)
      @renderer.setViewport left, bottom, width, height
      @renderer.setScissor left, bottom, width, height
      @renderer.enableScissorTest true
      @renderer.setClearColor view.background
      @_axisCamera.lookAt(@_target)
      @renderer.render(@scene, @_axisCamera)
      return

    setTarget: (mesh) ->
      @_target = mesh.position
      MainCamera.setTarget(@_target)
      AxisCamera.setTarget(@_target)

    setLevel: (@_currentLevel) ->
      # TODO: Clear current voxels
      VoxelFactory.load(@_currentLevel)
      map = @_currentLevel.getMap()
      map.forEach (x, y, z, color, orientation) =>
        @_addVoxel(x, y, z, color, orientation)
      map.on 'add', (x, y, z, color, orientation) =>
        @_addVoxel(x, y, z, color, orientation)
      # map.on 'remove', => console.error('Shouuld call SceneManager.removeVoxel directly')

    currentMap: -> @_currentLevel.getMap()
