# skin = require 'minecraft-skin'
THREE = require '../../three'

parseXYZ = (x, y, z) ->
  if typeof x is 'object' and Array.isArray(x)
    return (
      x: x[0]
      y: x[1]
      z: x[2]
    )
  else if typeof x is 'object'
    return (
      x: x.x or 0
      y: x.y or 0
      z: x.z or 0
    )
  x: Number(x)
  y: Number(y)
  z: Number(z)

skin = (THREE, img, skinOpts) ->
  map = THREE.ImageUtils.loadTexture( img )
  # material = new THREE.SpriteMaterial({map})
  # sprite = new THREE.Sprite(material)

  material = new THREE.MeshBasicMaterial({map, side:THREE.DoubleSide, transparent:true})
  geometry = new THREE.PlaneGeometry(1, 1)
  sprite = new THREE.Mesh(geometry, material)
  sprite2 = new THREE.Object3D()
  sprite2.add(sprite)

  mesh: sprite2


module.exports = (game) ->
  mountPoint = undefined
  possessed = undefined
  (img, skinOpts) ->
    skinOpts = {}  unless skinOpts
    skinOpts.scale = skinOpts.scale or new THREE.Vector3(0.04, 0.04, 0.04)
    playerSkin = skin(THREE, img, skinOpts)
    player = playerSkin.mesh
    physics = game.makePhysical(player)
    physics.playerSkin = playerSkin

    game.scene.add(player)
    game.addItem(physics)
    physics.yaw = player
    physics.pitch = player.head # This is undefined for a sprite
    physics.subjectTo(game.gravity)
    physics.blocksCreation = true
    game.control(physics)
    physics.move = (x, y, z) ->
      xyz = parseXYZ(x, y, z)
      physics.yaw.position.x += xyz.x
      physics.yaw.position.y += xyz.y
      physics.yaw.position.z += xyz.z
      return

    physics.moveTo = (x, y, z) ->
      xyz = parseXYZ(x, y, z)
      physics.yaw.position.x = xyz.x
      physics.yaw.position.y = xyz.y
      physics.yaw.position.z = xyz.z
      return

    pov = 1
    physics.pov = (type) ->
      if type is 'first' or type is 1
        pov = 1
      else pov = 3  if type is 'third' or type is 3
      physics.possess()
      return

    physics.toggle = ->
      physics.pov (if pov is 1 then 3 else 1)
      return

    physics.possess = ->
      possessed.remove game.camera  if possessed
      key = (if pov is 1 then 'cameraInside' else 'cameraOutside')
      # player[key].add game.camera
      possessed = player[key]
      return

    physics.position = physics.yaw.position
    physics
