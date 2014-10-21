ActionTypes = require('./actions/types')
window.PlayerManager = require('./actions/player-manager')
createGame = require('voxel-engine')
kbControls = require('kb-controls')
# toolbar = require('toolbar')

# highlight = require('voxel-highlight')
# toolbar = require('toolbar')
player = require('./customized/voxel-player')

{LinearSpriteAnimation} = require '../sprite-animation'

# toolbar = require('toolbar')
skin = require('minecraft-skin')

# blockSelector = toolbar({el: '#tools'})
voxel = require('voxel')
voxelView = require('voxel-view')
VoxelPhysical = require('./customized/voxel-physical')
Collision3DTilemap = require './customized/collision-3d-tilemap'
# Change up arrow to be up in the Y axis (not Z)
VoxelControlTick = require './customized/voxel-control-tick'
CollideTerrain = require('./collisions/terrain')
GameManager = require './actions/game-manager'
window.MainCamera = MainCamera = require '../main-camera'


# Used by the collisiondetector so height must be 1
PLAYER_SIZE = [.4, .9, .4]

module.exports = (SceneManager) ->

  mapConfig = window.CURRENT_LEVEL or throw new Error('BUG! Need to load a level first')# require('./maps/my')


  # HACK to use the existing scene
  createGame::addLights = ->
    @scene = SceneManager.scene
  createGame::render = ->


  # Mostly from voxelEngine but added @pausedPhysics
  createGame::tick = (delta) ->
    unless @pausedPhysics
      i = 0
      len = @items.length

      while i < len
        @items[i].tick delta
        ++i
      @materials.tick()  if @materials
    @updateDirtyChunks()  if Object.keys(@chunksNeedsUpdate).length > 0
    @emit "tick", delta
    return  unless @controls
    playerPos = @playerPosition()
    @spatial.emit "position", playerPos, playerPos
    return


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

  createGame::gravity = [0, -0.0000045, 0]

  # Custom collision detector that moves the player in the depth axis
  createGame::collideTerrain = CollideTerrain


  createGame_showChunk = createGame::showChunk
  createGame::showChunk = (chunk) ->
    # createGame_showChunk.apply(@, arguments)

  createGame::initializeControls = (opts) ->
    # player control
    @buttons = kbControls(document.body, opts.keybindings || @defaultButtons)
    @buttons.disable()
    @optout = false
    # @interact = interact(@view.element)
    # @interact
    #     .on('attain', @onControlChange.bind(this, true))
    #     .on('release', @onControlChange.bind(this, false))
    #     .on('opt-out', @onControlOptOut.bind(this))
    @hookupControls(this.buttons, opts)
    @onControlChange(true)

  createGame::onControlChange = (gained, stream) ->
    @paused = false

    if !gained and !@optout
      @buttons.disable()
    else
      @buttons.enable()
      # stream.pipe(this.controls.createWriteRotationStream())

  # Change the terminal velocity defaults for a player
  createGame::makePhysical = (target, envelope, blocksCreation) ->
    # obj = VoxelPhysical(target, @potentialCollisionSet(), envelope or [1/2, 1.5, 1/2])
    obj = VoxelPhysical(target, @potentialCollisionSet(), envelope or PLAYER_SIZE)
    obj.blocksCreation = !!blocksCreation
    return obj


  # setup the game and add some trees
  game = createGame
    statsDisabled: true
    materials: [] # To disable loading the defaults
    view: view
    generate: (x, y, z) -> mapConfig.getMap().getColor(x, y, z)
    chunkDistance: 2
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


  # Use modified collide-3d-tilemap that does not look up the current voxel
  game.collideVoxels = Collision3DTilemap(
    game.getBlock.bind(game),
    1,
    [Infinity, Infinity, Infinity],
    [-Infinity, -Infinity, -Infinity]
  )


  # Change up arrow to be up in the Y axis (not Z)
  game.controls.tick = VoxelControlTick.bind(game.controls)

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
  substack = createPlayer(mapConfig.player.sprite_href)
  # substack.possess() Don't need to posses because camera is elsewhere
  substack.avatar.scale.set(1, 2.76, 1) # TODO: Why 2.75 for the y???

  playerTexture = substack.avatar.children[0].material.map
  playerTexture.wrapS = THREE.RepeatWrapping
  playerTexture.wrapT = THREE.RepeatWrapping
  playerTexture.repeat.set( 1 / mapConfig.player.sprite_width, 1 / mapConfig.player.sprite_height ) # Tiles Horiz, Tiles Vert


  SceneManager.setTarget(substack.avatar)
  initialCoords = mapConfig.default_position
  substack.yaw.position.set(initialCoords[0], initialCoords[1], initialCoords[2])
  rotatingCameraTo = null
  rotatingCameraDir = 0
  game.on 'tick', (elapsedTime) ->
    PlayerManager.tick(elapsedTime, game)
    return

  # Moves the camera to match the player rotation
  rotateCamera = ->
    # Update the camera position
    theta = game.controlling.rotation.y * 360 / Math.PI
    # theta = dir * 2 * Math.PI * 360 * 2  # @_theta * Math.PI / 360
    phi = 0
    MainCamera.rotateCameraTo(theta, phi)
    # Updates camera position too

  game.on 'tick', ->
    if not rotatingCameraDir and game.controls.state.rotate_clockwise

      # 'D' was pressed
      # snap to 90degrees
      y = game.controlling.rotation.y
      y = Math.round(y * 2 / Math.PI)
      y += 1
      rotatingCameraDir = 1
      rotatingCameraTo = y * Math.PI / 2

      game.pausedPhysics = true

    else if not rotatingCameraDir and game.controls.state.rotate_counterclockwise

      # 'A' was pressed
      # Rotating the avatar implicitly rotates the camera in it's head
      # snap to 90degrees
      y = game.controlling.rotation.y
      y = Math.round(y * 2 / Math.PI)
      y -= 1
      rotatingCameraDir = -1
      rotatingCameraTo = y * Math.PI / 2

      game.pausedPhysics = true


    if @controlling.position.y < -10
      # alert 'You died a horrible death. Try again.'
      PlayerManager.reset()
      @controlling.moveTo(initialCoords[0], initialCoords[1], initialCoords[2])
      @controlling.velocity.x = 0
      @controlling.velocity.y = 0
      @controlling.velocity.z = 0

      @controlling.acceleration.x = 0
      @controlling.acceleration.y = 0
      @controlling.acceleration.z = 0

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

    boxes += 'me = [' + Math.floor(@controlling.aabb().base[0]) + ', ' + Math.floor(@controlling.aabb().base[1]) + ', ' + Math.floor(@controlling.aabb().base[2]) + ']'
    boxes += '<br/>cameraAxis = ' + cameraAxis
    boxes += '<br/>cameraDir = ' + cameraDir
    boxes += '<br/>curAction = ' + PlayerManager.currentAction().constructor.name  if PlayerManager.currentAction()
    document.getElementById('player-boxes').innerHTML = boxes


    if rotatingCameraDir
      game.controlling.rotation.y += rotatingCameraDir * Math.PI / 50

      isDoneRotating = (rotatingCameraDir > 0 and game.controlling.rotation.y - rotatingCameraTo > 0) or (rotatingCameraDir < 0 and game.controlling.rotation.y - rotatingCameraTo < 0)
      if isDoneRotating
        game.controlling.rotation.y = rotatingCameraTo
        rotatingCameraDir = 0
        GameManager.invalidateCache()
        game.pausedPhysics = false

      rotateCamera()
    else
      MainCamera.updateCamera() # Update the position when the player moves

    return

  GameManager.load()
