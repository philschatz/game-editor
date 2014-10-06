# Stubs for collision detector:
#
# @collideVoxels (which calls our hit())
# @controlling.aabb().base   ... coord
# @controlling.moveTo(coord) ... void
#
# GameManager.get2DInfo()
# GameManager.getFlattenedBlock(coords)  ... color
# GameManager.getPlayerFlattenedBlock()  ... color
# GameManager.isCameraAxis(axis)         ... bool
# GameManager.getGame().getBlock(coords) ... color
# GameManager.getBlockDepthsInFrontOf(coords) ... [coord]
# PaletteManager.collisionFor(color)          ... string

# _ = require 'underscore'
PaletteManager  = require './src/voxels/palette-manager'
CollideTerrain  = require './src/game/collisions/terrain'
GameManager     = require './src/game/actions/game-manager'


window.startEditor = -> console.warn 'HACK for running the test. making this a noop'



# Test consists of:
#
# 1. a map (up to 2 levels (floor and my level)
# 2. expected depth
# 3. expected hit (assume false)

# Optional stuff:
# moveAxis = 0, 1, 2
# moveDir = -1, 1


collideTest = ({map, expectedDepth, axis, dir, expectedHit, playerCoord}) ->
  # These are set by the collision detector
  ACTUAL_HIT = false
  ACTUAL_DEPTH = undefined

  axis ?= 0
  dir ?= 1

  if axis is 0
    perpendicAxis = 2
  else
    perpendicAxis = 0

  multiplier = 1
  playerCoord ?= [0,1,0]

  # Determine the desired coord based on the axis and dir
  desiredCoord = [playerCoord[0], playerCoord[1], playerCoord[2]]
  desiredCoord[axis] += dir


  getBlock = ([x, y, z]) ->
    level = map[y] or []
    row = level[x] or []
    row[z]

  getFlattenedBlock = ([x, y, z]) ->
    level = map[y] or []
    row = level[x] or []
    # _.last(row)
    return undefined unless row.length
    row.length - 1

  getBackFlattenedBlock = ([x, y, z]) ->
    level = map[y] or []
    row = level[x] or []
    return undefined unless row.length
    0

  context =
    collideVoxels: (bbox, vec3, hit) ->
      tile = 4
      edge = 0
      ACTUAL_HIT = hit(axis, tile, desiredCoord, dir, edge)
    controlling:
      aabb: ->
        # Collision detector mutates this array so recreate it here
        [x, y, z] = playerCoord
        base: [x, y, z]
      moveTo: (x, y, z) ->
        coord = [x, y, z]
        console.log 'Moving to', coord
        ACTUAL_DEPTH = Math.floor(coord[perpendicAxis]) # Collision detector adds .5 to the coord to center the player

  GameManager.get2DInfo = ->
    # all are defined above
    {axis, perpendicAxis, dir, multiplier}
  GameManager.getFlattenedBlock = (coords) -> getFlattenedBlock(coords)
  GameManager.getBackFlattenedBlock = (coords) -> getBackFlattenedBlock(coords)
  GameManager.getPlayerFlattenedBlock = -> getFlattenedBlock(playerCoord)
  GameManager.isCameraAxis = -> true
  GameManager.getGame = -> {getBlock}
  # GameManager.getBlockDepthsInFrontOf(coords) No need to implement this
  PaletteManager.collisionFor = (color) -> color

  # Run the collision detector
  other =
    acceleration: []
    friction: []

  # The player coordinates
  bbox =
    base: [0,1,0] # player is standing on something

  # Create a THREE.Vector3 velocity vector
  vec = [0, 0, 0]
  vec[axis] = dir
  [x, y, z] = vec
  vec = {x, y, z}

  resting = []
  CollideTerrain.apply(context, [other, bbox, vec, resting])

  unless !!expectedHit is !!ACTUAL_HIT
    throw new Error("Hit mismatch. Expected: #{expectedHit} Actual: #{ACTUAL_HIT}")
  unless expectedDepth is ACTUAL_DEPTH
    throw new Error("Depth mismatch. Expected: #{expectedDepth} Actual: #{ACTUAL_DEPTH}")


# --------------------- Tests start below -----------------



console.log('Simple walk with top in front, no moving (Do not move the player unnecessarily)')
collideTest
  map: [
    # Floor below the player
    [
      ['top'       ] # ---> Z axis (depth)
      ['top', 'top']
      # |
      # |
      # V
      #
      # X axis
    ]
    # The player level (empty)
  ]



console.log('Simple walk, no moving')
collideTest
  map: [
    # Floor below the player
    [
      ['top'] # ---> Z axis (depth)
      ['top']
      # |
      # |
      # V
      #
      # X axis
    ]
    # The player level (empty)
  ]


console.log('Simple walk, no moving but the player starts in differrent coords')
collideTest
  playerCoord: [1, 1, 1]
  map: [
    # Floor below the player
    [
      [           ]
      [null, 'top'] # ---> Z axis (depth)
      [null, 'top']
    ]
    # The player level (empty)
  ]


console.log('Bump the player over 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'      ] # ---> Z axis (depth)
      [null, 'top']
      # |
      # |
      # V
      #
      # X axis
    ]
    # The player level (empty)
  ]


console.log('Simple wall. Bump the player over 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'      ] # ---> Z axis (depth)
      [null, 'top']
    ]
    # The player level (empty)
    [
      [          ] # ---> Z axis (depth)
      ['none'    ] # The wall
    ]
  ]


console.log('Simple wall. Bump the player over 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'       ] # ---> Z axis (depth)
      ['top', 'top']
    ]
    # The player level (empty)
    [
      [            ] # ---> Z axis (depth)
      ['none'      ] # The wall
    ]
  ]


console.log('Complex wall. Bump the player over 1 unit even though there is a floating post top in front')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'               ] # ---> Z axis (depth)
      [null , 'top',       ]
    ]
    # The player level (empty)
    [
      [                    ] # ---> Z axis (depth)
      ['none', null, 'none'] # The wall
    ]
  ]


console.log('Complex wall. Bump the player over 1 unit even though there is a post in front')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'               ] # ---> Z axis (depth)
      [null , 'top', 'none']
    ]
    # The player level (empty)
    [
      [                    ] # ---> Z axis (depth)
      ['none', null, 'none'] # The wall
    ]
  ]


console.log('Simple wall. Bump the player over 1 unit even though there is no floor')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['top'] # ---> Z axis (depth)
      ['top']
    ]
    # The player level (empty)
    [
      [      ] # ---> Z axis (depth)
      ['none'] # The wall
    ]
  ]
