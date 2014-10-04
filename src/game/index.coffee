ActionTypes = require('./actions/types')
window.PlayerManager = require('./actions/player-manager')
createGame = require('voxel-engine')
# toolbar = require('toolbar')

# highlight = require('voxel-highlight')
# toolbar = require('toolbar')
player = require('voxel-player')

# toolbar = require('toolbar')
skin = require('minecraft-skin')

# blockSelector = toolbar({el: '#tools'})
voxel = require('voxel')
voxelView = require('voxel-view')
collideTerrain = require('./collisions/terrain')
mapConfig = require('./maps/my')


mapConfig.playerPosition = [1, 7, 3]

module.exports = (SceneManager) ->

  # HACK to use the existing scene
  createGame::addLights = ->
    @scene = SceneManager.scene
  createGame::render = ->

  myMap = mapConfig.map
  myTextures = mapConfig.textures
  {collisionTypes} = mapConfig
  THREE = createGame.THREE
  view = new voxelView THREE,
    ortho: true
    width: window.innerWidth
    height: window.innerHeight

  view.element = SceneManager.renderer.domElement

  view.camera.position.z = 1000 # so the camera is never 'inside' the voxels. Should change based on the min/max depth when camera is rotated
  view.camera.scale.set(.85, .85, .85)

  # Stupid negative modulo in JS
  Number::mod = (n) ->
    ((this % n) + n) % n

  createGame::gravity = [0, -0.0000090, 0]

  # other -
  # bbox - player bbox
  # vec -
  # resting -
  createGame::collideTerrain = collideTerrain


  createGame_showChunk = createGame::showChunk
  createGame::showChunk = (chunk) ->
    # createGame_showChunk.apply(@, arguments)


  # setup the game and add some trees
  game = createGame
    view: view
    generate: myMap
    chunkDistance: 2
    materials: myTextures
    worldOrigin: [0, 0, 0]
    controls:
      discreteFire: true

    keybindings:
      '<up>': 'forward'
      '<left>': 'left'
      '<down>': 'backward'
      '<right>': 'right'
      '<mouse 1>': 'fire'
      '<mouse 2>': 'firealt'
      '<space>': 'jump'
      '<shift>': 'crouch'
      '<control>': 'alt'
      A: 'rotate_counterclockwise'
      D: 'rotate_clockwise'

  window.game = game # for debugging
  # container = document.querySelector('#container')
  # game.appendTo(container)

  # maxogden = skin(game.THREE, 'maxogden.png')
  # window.maxogden = maxogden
  # maxogden.mesh.position.set(0, 2, -20)
  # maxogden.head.rotation.y = 1.5
  # maxogden.mesh.rotation.y = Math.PI
  # maxogden.mesh.scale.set(0.04, 0.04, 0.04)
  # game.scene.add(maxogden.mesh)
  #

  # create the player from a minecraft skin file and tell the
  # game to use it as the main player
  createPlayer = player(game)
  substack = createPlayer('substack.png')
  # Scale because our world size is 1 unit
  substack.playerSkin.mesh.scale.x = 1/16
  substack.playerSkin.mesh.scale.y = 1/16
  substack.playerSkin.mesh.scale.z = 1/16
  substack.possess()
  initialCoords = mapConfig.playerPosition or [0, 5, 0]
  substack.yaw.position.set initialCoords[0], initialCoords[1], initialCoords[2]
  rotatingCameraTo = null
  rotatingCameraDir = 0
  game.on 'tick', (elapsedTime) ->
    PlayerManager.tick elapsedTime, game

    # Support climbing if there is a climbing tile behind the player
    cameraType = game.controlling.rotation.y / Math.PI * 2
    cameraType = Math.round(cameraType).mod(4)
    scaleJustToBeSafe = 1.5
    cameraDir = 1
    cameraAxis = undefined
    cameraPerpendicAxis = undefined
    cameraDir = -1  if cameraType >= 2
    if cameraType.mod(2) is 0 #x
      cameraAxis = 0
      cameraPerpendicAxis = 2
    else #z
      cameraAxis = 2
      cameraPerpendicAxis = 0
    y = Math.floor(game.controlling.aabb().base[1])
    myBlock = @sparseCollisionMap[cameraType]['' + Math.floor(game.controlling.aabb().base[cameraAxis]) + '|' + y]
    myBlockBelow = @sparseCollisionMap[cameraType]['' + Math.floor(game.controlling.aabb().base[cameraAxis]) + '|' + (y - 1)]
    if game.controls.state.climbing and not (game.controls.state.forward or game.controls.state.backward) and myBlock?
      game.controlling.resting.y = true

      # prevent moving left/right (TODO: Unless there are tiles left/right)
      game.controlling.resting.x = true
      game.controlling.resting.z = true
    else if game.controls.state.climbing and game.controls.state.forward
      game.controlling.position.y += .1
      game.controlling.resting.y = true

      # prevent moving left/right (TODO: Unless there are tiles left/right)
      game.controlling.resting.x = true
      game.controlling.resting.z = true
    else if game.controls.state.climbing and not (game.controls.state.forward or game.controls.state.backward) and not myBlock?
      game.controls.state.climbing = false
      game.controlling.resting.y = false
    else if not game.controls.state.climbing and game.controls.state.forward and myBlock?
      game.controls.state.climbing = true
      game.controlling.resting.y = true

      # prevent moving left/right (TODO: Unless there are tiles left/right)
      game.controlling.resting.x = true
      game.controlling.resting.z = true
    else if game.controls.state.climbing and game.controls.state.backward
      game.controlling.position.y -= .1
      game.controlling.resting.y = true

      # prevent moving left/right (TODO: Unless there are tiles left/right)
      game.controlling.resting.x = true
      game.controlling.resting.z = true

    # } else if (!game.controls.state.climbing && game.controls.state.backward && myBlock != null) {
    #   game.controls.state.climbing = true;
    #   game.controlling.resting.y = true;
    else if not game.controls.state.climbing and game.controls.state.backward and myBlockBelow?

      # Allow climbing down when there is a block below
      game.controls.state.climbing = true
      game.controlling.resting.y = true

      # prevent moving left/right (TODO: Unless there are tiles left/right)
      game.controlling.resting.x = true
      game.controlling.resting.z = true
    return

  game.on 'tick', ->
    if not rotatingCameraDir and game.controls.state.rotate_clockwise

      # 'D' was pressed
      # snap to 90degrees
      y = game.controlling.rotation.y
      y = Math.round(y * 2 / Math.PI)
      y += 1
      rotatingCameraDir = 1
      rotatingCameraTo = y * Math.PI / 2

      # Reset if te mouse moved the camera
      game.controlling.pitch.rotation.x = 0
      game.controlling.pitch.rotation.x = 0
    else if not rotatingCameraDir and game.controls.state.rotate_counterclockwise

      # 'A' was pressed
      # Rotating the avatar implicitly rotates the camera in it's head
      # snap to 90degrees
      y = game.controlling.rotation.y
      y = Math.round(y * 2 / Math.PI)
      y -= 1
      rotatingCameraDir = -1
      rotatingCameraTo = y * Math.PI / 2

      # Reset if te mouse moved the camera
      game.controlling.pitch.rotation.x = 0
      game.controlling.pitch.rotation.x = 0
    if @controlling.aabb().base[1] < -20
      alert 'You died a horrible death. Try again.'
      @controlling.moveTo(initialCoords[0], initialCoords[1], initialCoords[2])
      @controlling.velocity.x = 0
      @controlling.velocity.y = 0
      @controlling.velocity.z = 0

    # player debugging
    boxes = ''
    cameraType = @controlling.rotation.y / Math.PI * 2
    cameraType = Math.round(cameraType).mod(4)
    cameraDir = 1
    cameraAxis = undefined
    cameraPerpendicAxis = undefined
    cameraDir = -1  if cameraType >= 2
    if cameraType.mod(2) is 0 #x
      cameraAxis = 0
      cameraPerpendicAxis = 2
    else #z
      cameraAxis = 2
      cameraPerpendicAxis = 0
    playerX = Math.floor(@controlling.aabb().base[cameraAxis])
    playerY = Math.floor(@controlling.aabb().base[1])

    for i in [-2..2]
      for j in [-2..2]
        boxY = playerY + (-1 * i)
        boxX = playerX + (j)
        block = @sparseCollisionMap[cameraType]['' + boxX + '|' + boxY]
        if block
          if block < 10
            boxes += '0' + block
          else
            boxes += block
        else
          boxes += '--'
        if i is 0 and j is -1
          boxes += '['
        else if i is 0 and j is 0
          boxes += ']'
        else
          boxes += ' '
      boxes += '<br/>'

    boxes += 'me = [' + Math.floor(@controlling.aabb().base[0]) + ', ' + Math.floor(@controlling.aabb().base[1]) + ', ' + Math.floor(@controlling.aabb().base[2]) + ']'
    boxes += '<br/>cameraAxis = ' + cameraAxis
    boxes += '<br/>cameraDir = ' + cameraDir
    boxes += '<br/>curAction = ' + PlayerManager.currentAction().constructor.name  if PlayerManager.currentAction()
    document.getElementById('player-boxes').innerHTML = boxes
    if rotatingCameraDir
      game.controlling.rotation.y += rotatingCameraDir * Math.PI / 50
      if rotatingCameraDir > 0 and game.controlling.rotation.y - rotatingCameraTo > 0
        game.controlling.rotation.y = rotatingCameraTo
        rotatingCameraDir = 0
      if rotatingCameraDir < 0 and game.controlling.rotation.y - rotatingCameraTo < 0
        game.controlling.rotation.y = rotatingCameraTo
        rotatingCameraDir = 0
    return

  buildCollisionMap = ->
    game.sparseCollisionMap = [ {}, {}, {}, {} ]

    # dir is 0, 1, 2, 3 depending on the rotation
    # build a sparse array for each location
    for dir in [0..3]
      for y in [0..50]
        for a in [-50..50]
          block = null
          prevBlockBelow = null
          for b in [-50..50]
            B = b
            B = -b if dir < 2
            if dir % 2 is 0
              pos = [a, y, B]
            if dir % 2 is 1
              pos = [B, y, a]
            block = game.getBlock(pos)
            if block and collisionTypes?[block]
              break

          game.sparseCollisionMap[dir]['' + a + '|' + y] = B  if block


  # Build initial collision map
  buildCollisionMap()
