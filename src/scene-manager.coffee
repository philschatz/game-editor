MainCamera = require './main-camera'
AxisCamera = require './axis-camera'

module.exports = (THREE, Input) ->
  new class SceneManager

    # To limit the scope of requiring THREE
    THREE: -> THREE

    renderer: null
    brush: null
    scene: null

    plane: null

    _container: null
    _camera: null
    _target: new THREE.Vector3( 0, 200, 0 ) # -1200, 300, 900


    _CubeMaterial: THREE.MeshBasicMaterial
    _cube: new THREE.CubeGeometry( 50, 50, 50 )
    _axisCamera: null
    _projector: null
    _size: 500
    _step: 50
    _showWireframe: true

    init: (@_container) ->
      window.scene = @scene = new THREE.Scene()
      @_camera = new THREE.OrthographicCamera(@_container.clientWidth / -1, @_container.clientWidth / 1, @_container.clientHeight / 1, @_container.clientHeight / -1, 1, 10000)
      MainCamera.init(@scene, @_camera, @_container, @_target)
      MainCamera.updateCamera({x:0, y:0, z:0})
      @_axisCamera = new THREE.OrthographicCamera(@_container.clientWidth / -2, @_container.clientWidth / 2, @_container.clientHeight / 2, @_container.clientHeight / -2, 1, 10000)

      @_axisCamera = new THREE.OrthographicCamera(@_container.clientWidth / -2, @_container.clientWidth / 2, @_container.clientHeight / 2, @_container.clientHeight / -2, 1, 10000)
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
      @plane = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), new THREE.MeshBasicMaterial())
      @plane.rotation.x = -Math.PI / 2
      @plane.visible = false
      @plane.isPlane = true
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
      ambientLight = new THREE.AmbientLight(0x606060)
      @scene.add(ambientLight)
      directionalLight = new THREE.DirectionalLight(0xffffff)
      directionalLight.position.set(1, 0.75, 0.5).normalize()
      @scene.add directionalLight
      hasWebGL = (->
        try
          return !!window.WebGLRenderingContext and !!document.createElement('canvas').getContext('experimental-webgl')
        catch e
          return false
        return
      )()
      if hasWebGL
        @renderer = new THREE.WebGLRenderer(antialias: true)
      else
        @renderer = new THREE.CanvasRenderer()
      @renderer.setSize(@_container.clientWidth, @_container.clientHeight)


    addVoxel: (x, y, z, col) ->
      cubeMaterial = new @_CubeMaterial(
        vertexColors: THREE.VertexColors
        transparent: true
      )
      wireframeCube = new THREE.CubeGeometry(50.5, 50.5 , 50.5)
      wireframeOptions =
        color: 0x000000
        wireframe: true
        wireframeLinewidth: 1
        opacity: 0.8
      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)

      # col = colors[c] or colors[0]
      cubeMaterial.color.setRGB(col[0], col[1], col[2])
      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
      wireframeMaterial.color.setRGB(col[0] - 0.05, col[1] - 0.05, col[2] - 0.05)
      voxel = new THREE.Mesh(@_cube, cubeMaterial)
      voxel.wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial)
      voxel.isVoxel = true
      voxel.position.x = x
      voxel.position.y = y
      voxel.position.z = z
      voxel.wireMesh.position.copy(voxel.position)
      voxel.wireMesh.visible = @_showWireframe
      voxel.matrixAutoUpdate = false
      voxel.updateMatrix()
      voxel.name = x + ',' + y + ',' + z
      voxel.overdraw = true
      @scene.add(voxel)
      @scene.add(voxel.wireMesh)
      return


    render: ->
      return console.warn 'Trying to render scene before initialized' unless @_camera
      @_camera.lookAt(@_target)
      MainCamera.setRaycaster(@_projector.pickingRay(Input.mouse2D.clone(), @_camera))
      @renderer.setViewport()
      @renderer.setScissor() # TODO: this might ned to become 0,0,@renderer.domElement.width,@renderer.domElement.height
      @renderer.enableScissorTest(false)
      @renderer.setClearColor(new THREE.Color().setRGB(1, 1, 1))
      @renderer.render(@scene, @_camera)

      # return;

      # @_camera 2
      windowWidth = @_container.clientWidth
      windowHeight = @_container.clientHeight
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
