ladderTop     = require './voxels/ladder-top.json' # extension is optional
ladderBottom  = require './voxels/ladder-bottom.json' # extension is optional
ladderMiddle  = require './voxels/ladder-middle.json' # extension is optional

ColorManager = require './color-manager'

COLOR_MAP =
  '10': 'ladder-top'
  '11': 'ladder-middle'
  '12': 'ladder-bottom'

module.exports = (THREE) -> new class VoxelFactory

  _cube: new THREE.BoxGeometry( 50, 50, 50 )

  constructor: ->
    loader = (config) ->
      new THREE.ObjectLoader().parse(config)

    @_VOXEL_MAP =
      'ladder-top'    : loader(ladderTop)
      'ladder-bottom' : loader(ladderBottom)
      'ladder-middle' : loader(ladderMiddle)

  freshVoxel: (color) ->
    id = COLOR_MAP["#{color}"]
    if id
      voxel = @_VOXEL_MAP[id]?.clone() or throw new Error('invalid voxel id')
      voxel.scale.x = 1/16
      voxel.scale.y = 1/16
      voxel.scale.z = 1/16
      voxel.position.y = -25
      voxel.position.z = -6

      wireframeCube = new THREE.BoxGeometry(50.5, 50.5 , 50.5)
      wireframeOptions =
        color: 0x000000
        # wireframe: true
        transparent: true
        wireframeLinewidth: 0
        opacity: 0.15

      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
      wireframeMaterial.color.setRGB(0, 0, 0) # or color - .05

      group = new THREE.Object3D()
      group.add(voxel)
      group.add(new THREE.Mesh(wireframeCube, wireframeMaterial))

      voxel = group

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

    voxel.colorCode = color
    return voxel
