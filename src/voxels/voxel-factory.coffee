PaletteManager   = require './palette-manager'
TextureCube    = require './texture-cube'


geometryLoader = (config) ->
  voxel = new THREE.ObjectLoader().parse(config.geometry)
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


textureLoader = (config) ->
  {front_url, back_url, top_url, bottom_url, left_url, right_url} = config
  # Unsure if the order below is correct or not but it's close
  TextureCube.freshCube([front_url, back_url, top_url, bottom_url, left_url, right_url])


VOXEL_TEMPLATE_MAP = {}
for voxelName, config of PaletteManager.allVoxelConfigs()
  template = switch config.type
    when 'geometry' then geometryLoader(config)
    when 'texture'  then textureLoader(config)
    else throw new Error('BUG: Unsupported Voxel type')
  VOXEL_TEMPLATE_MAP[voxelName] = template



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
