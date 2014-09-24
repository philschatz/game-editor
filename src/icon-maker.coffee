module.exports = new class IconMaker
  width: 64
  height: 64
  constructor: ->
    @scene = new THREE.Scene()
    @camera = new THREE.OrthographicCamera(50/-2, 50/2, 50/-2, 50/2, 1, 1000)
    @camera.aspect = @width / @height
    @camera.position.z = -500
    # Move the @camera because some voxels are shifted (TODO: Fix voxels so they are always centered)

    @scene.add(new THREE.AmbientLight(0x606060))
    # @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer = new THREE.CanvasRenderer()
    @renderer.setSize(@width, @height)
    @renderer.setClearColor(new THREE.Color().setRGB(1,1,1))

    @canvas = document.createElement('canvas')
    @canvas.width = @width
    @canvas.height = @height
    @ctx = @canvas.getContext('2d')

  dispose: ->
    delete @scene
    delete @camera
    delete @renderer
    delete @canvas
    delete @ctx


  renderVoxel: (voxel) ->
    @scene.add(voxel)
    @camera.lookAt(voxel.position)
    @renderer.render(@scene, @camera)
    @scene.remove(voxel)
    @ctx.drawImage(@renderer.domElement, 0, 0, @width, @height)
    @canvas.toDataURL()

  renderImage: (voxel) ->
    data = @renderVoxel(voxel)
    img = new Image()
    img.src = data
    img
