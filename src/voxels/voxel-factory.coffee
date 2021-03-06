THREE = require '../three'
PaletteManager   = require './palette-manager'
TextureCube    = require './texture-cube'


geometryLoader = (config) ->
  voxel = new THREE.ObjectLoader().parse(config.geometry)
  voxel.scale.x = 1/50/16# 1/(16) / (50/(16))
  voxel.scale.y = 1/50/16# 1/(16) / (50/(16))
  voxel.scale.z = 1/50/16# 1/(16) / (50/(16))
  voxel.position.y += -.5 # -8

  wireframeCube = new THREE.BoxGeometry((16/16) + .5/16, (16/16) + .5/16 , (16/16) + .5/16)
  wireframeOptions =
    color: 0xEEEEEE
    wireframe: true
    wireframeLinewidth: 1
    opacity: 0.05

  wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)

  group = new THREE.Object3D()
  group.add(voxel)

  wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial)
  wireMesh.myVoxel = group
  wireMesh.isWireMesh = true

  {wireMesh, voxel: group, canRandomlyRotate: false}


textureLoader = (config, doNotRandomize) ->
  {front_href, back_href, top_href, bottom_href, left_href, right_href} = config
  # Unsure if the order below is correct or not but it's close
  voxel = TextureCube.freshCube([front_href, back_href, top_href, bottom_href, left_href, right_href])

  {voxel, canRandomlyRotate: true}


# Share the same geometry for simple color cubes
colorCube = new THREE.BoxGeometry( (16/16), (16/16), (16/16) )

colorLoader = (config) ->
  _CubeMaterial = THREE.MeshBasicMaterial
  cubeMaterial = new _CubeMaterial(
    vertexColors: THREE.VertexColors
    transparent: true
  )

  colorInt = parseInt(config.color_hex, 16)
  cubeMaterial.color = new THREE.Color(colorInt)
  voxel = new THREE.Mesh(colorCube, cubeMaterial)
  voxel.name = "color-#{config.color_hex}"

  {voxel, canRandomlyRotate:false}


VOXEL_TEMPLATE_MAP = []



module.exports = new class VoxelFactory

  load: (level) ->
    PaletteManager.load(level)
    for voxelName, config of PaletteManager.allVoxelConfigs()
      template = switch config.type
        when 'geometry' then geometryLoader(config)
        when 'texture'  then textureLoader(config)
        when 'color'    then colorLoader(config)
        else throw new Error('BUG: Unsupported Voxel type')
      VOXEL_TEMPLATE_MAP[voxelName] = template


  freshVoxel: (id, addWireframe) ->
    template = VOXEL_TEMPLATE_MAP[id]

    if template
      voxel = template.voxel.clone()
      if template.wireMesh
        voxel.wireMesh = template.wireMesh.clone()
        voxel.wireMesh.isWireMesh = true
        voxel.wireMesh.myVoxel = voxel

      if template.canRandomlyRotate
        voxel.rotation.y = Math.round(Math.random() * 4) * Math.PI / 2

      voxel.name = id

    else if /^color-[0-9a-fA-F]{6}/.test(id)
      # Extract the color and build a simple cube

      _CubeMaterial = THREE.MeshBasicMaterial
      cubeMaterial = new _CubeMaterial(
        vertexColors: THREE.VertexColors
        transparent: true
      )

      colorInt = parseInt(id.substring('color-'.length), 16)
      cubeMaterial.color = new THREE.Color(colorInt)
      voxel = new THREE.Mesh(@_cube, cubeMaterial)
      voxel.name = id

    else
      throw new Error('BUG! Invalid Voxel name')

    return voxel
