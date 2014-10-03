ladderTop     = require './types/ladder-top.json' # extension is optional
ladderBottom  = require './types/ladder-bottom.json'
ladderMiddle  = require './types/ladder-middle.json'
bridge        = require './types/bridge.json'
TextureCube    = require './types/texture-cube'


loader = (config) ->
  voxel = new THREE.ObjectLoader().parse(config)
  voxel.scale.x = 1/16 / (50/16)
  voxel.scale.y = 1/16 / (50/16)
  voxel.scale.z = 1/16 / (50/16)
  voxel.position.y += -8

  wireframeCube = new THREE.BoxGeometry(16.5, 16.5 , 16.5)
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


VOXEL_TEMPLATE_MAP =
  'brick-light'   : TextureCube.freshCube(['brick-light-1', 'brick-light-2', 'grass', 'grass', 'brick-light-5', 'brick-light-6'])
  'brick-medium'  : TextureCube.freshCube(['brick-medium-1', 'brick-medium-2', 'grass', 'grass', 'brick-medium-5', 'brick-medium-6'])
  'brick-dark'    : TextureCube.freshCube(['brick-dark-1', 'brick-dark-2', 'grass', 'grass', 'brick-dark-5', 'brick-dark-6'])
  'brick-grasstop': TextureCube.freshCube(['brick-grasstop-1', 'brick-grasstop-2', 'grass', 'grass', 'brick-grasstop-1', 'brick-grasstop-2'])
  'bridge-post-top': TextureCube.freshCube(['bridge-post-top', 'bridge-post-top', 'grass', 'grass', 'bridge-post-top', 'bridge-post-top'])
  'bridge-post'   : TextureCube.freshCube(['bridge-post-1', 'bridge-post-2', 'grass', 'grass', 'bridge-post-1', 'bridge-post-2'])
  'bridge'        : loader(bridge)
  'ladder-top'    : loader(ladderTop)
  'ladder-bottom' : loader(ladderBottom)
  'ladder-middle' : loader(ladderMiddle)


module.exports = new class VoxelFactory

  _cube: new THREE.BoxGeometry( 16, 16, 16 )

  freshVoxel: (id, addWireframe) ->
    template = VOXEL_TEMPLATE_MAP[id]

    unless id
      console.warn('BUG! Invalid voxel color name. using black')
      id = 'color-000000'

    if template
      voxel = template.clone()
      if template.wireMesh
        voxel.wireMesh = template.wireMesh.clone()
        voxel.wireMesh.isWireMesh = true
        voxel.wireMesh.myVoxel = voxel

      voxel.name = id

    else if /^color-[0-9a-fA-F]{6}/.test(id)
      # Extract the color and build a simple cube

      _CubeMaterial = THREE.MeshBasicMaterial
      cubeMaterial = new _CubeMaterial(
        vertexColors: THREE.VertexColors
        transparent: true
      )

      colorInt = parseInt(id.substring('color-'.length),16)
      cubeMaterial.color = new THREE.Color(colorInt)
      voxel = new THREE.Mesh(@_cube, cubeMaterial)
      voxel.name = id

    else
      throw new Error('BUG! Invalid Voxel name')

    return voxel
