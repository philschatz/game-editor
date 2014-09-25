ladderTop     = require './voxels/ladder-top.json' # extension is optional
ladderBottom  = require './voxels/ladder-bottom.json' # extension is optional
ladderMiddle  = require './voxels/ladder-middle.json' # extension is optional
TextureCube    = require './voxels/texture-cube'

ColorManager = require './color-manager'

COLOR_MAP =
  '1': 'brick-light'
  '2': 'brick-medium'
  '3': 'brick-dark'
  '4': 'brick-grasstop'
  '5': 'bridge-post-top'
  '7': 'bridge-post'
  '10': 'ladder-top'
  '11': 'ladder-middle'
  '12': 'ladder-bottom'

module.exports = new class VoxelFactory

  _cube: new THREE.BoxGeometry( 50, 50, 50 )

  constructor: ->
    loader = (config) ->
      voxel = new THREE.ObjectLoader().parse(config)
      voxel.scale.x = 1/16
      voxel.scale.y = 1/16
      voxel.scale.z = 1/16
      voxel.position.y += -25

      wireframeCube = new THREE.BoxGeometry(50.5, 50.5 , 50.5)
      wireframeOptions =
        color: 0xEEEEEE
        wireframe: true
        wireframeLinewidth: 1
        opacity: 0.05

      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)


      group = new THREE.Object3D()
      group.add(voxel)

      group.wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial)
      group.wireMesh.myVoxel = group
      group.wireMesh.isWireMesh = true

      group.add(group.wireMesh)

      group


    @_VOXEL_MAP =
      'brick-light'   : TextureCube.freshCube(['brick-light-1', 'brick-light-2', 'grass', 'grass', 'brick-light-5', 'brick-light-6'])
      'brick-medium'  : TextureCube.freshCube(['brick-medium-1', 'brick-medium-2', 'grass', 'grass', 'brick-medium-5', 'brick-medium-6'])
      'brick-dark'    : TextureCube.freshCube(['brick-dark-1', 'brick-dark-2', 'grass', 'grass', 'brick-dark-5', 'brick-dark-6'])
      'brick-grasstop': TextureCube.freshCube(['brick-grasstop-1', 'brick-grasstop-2', 'grass', 'grass', 'brick-grasstop-1', 'brick-grasstop-2'])
      'bridge-post-top': TextureCube.freshCube(['bridge-post-top', 'bridge-post-top', 'grass', 'grass', 'bridge-post-top', 'bridge-post-top'])
      'bridge-post'   : TextureCube.freshCube(['bridge-post-1', 'bridge-post-1', 'grass', 'grass', 'bridge-post-1', 'bridge-post-1'])
      'ladder-top'    : loader(ladderTop)
      'ladder-bottom' : loader(ladderBottom)
      'ladder-middle' : loader(ladderMiddle)

  freshVoxel: (color, addWireframe) ->
    id = COLOR_MAP["#{color}"]
    if id
      template = @_VOXEL_MAP[id]
      throw new Error('invalid voxel id') unless template
      voxel = template.clone()
      if template.wireMesh
        voxel.wireMesh = template.wireMesh.clone()
        voxel.wireMesh.isWireMesh = true
        voxel.wireMesh.myVoxel = voxel


      voxel.name = id

    else
      # Look the color up in the ColorManager
      _CubeMaterial = THREE.MeshBasicMaterial
      cubeMaterial = new _CubeMaterial(
        vertexColors: THREE.VertexColors
        transparent: true
      )

      # col = colors[c] or colors[0]
      col = ColorManager.colors[color]
      unless col
        throw new Error('BUG! color not found. Maybe just use black?')

      cubeMaterial.color.setRGB(col[0], col[1], col[2])
      voxel = new THREE.Mesh(@_cube, cubeMaterial)
      voxel.name = "color-#{color}"

      if addWireframe
        wireframeCube = new THREE.BoxGeometry(50.5, 50.5 , 50.5)
        wireframeOptions =
          color: 0xEEEEEE
          wireframe: true
          wireframeLinewidth: 1
          opacity: 0.05

        wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
        voxel.wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial)
        voxel.wireMesh.myVoxel = voxel
        voxel.wireMesh.isWireMesh = true



    voxel.colorCode = color
    return voxel
