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
        base: playerCoord[..]
      moveTo: (x, y, z) ->
        coord = [x, y, z]
        ACTUAL_DEPTH = Math.floor(coord[perpendicAxis]) # Collision detector adds .5 to the coord to center the player

  GameManager.get2DInfo = ->
    # all are defined above
    {axis, perpendicAxis, dir, multiplier}
  GameManager.blockTypeAt = (coords) -> getBlock(coords)
  GameManager._getFlattenedBlock = (coords) -> getFlattenedBlock(coords)
  GameManager._getBackFlattenedBlock = (coords) -> getBackFlattenedBlock(coords)
  GameManager.isCameraAxis = -> true
  GameManager._getGame = -> {getBlock}
  PaletteManager.collisionFor = (color) -> color

  # Run the collision detector
  other =
    acceleration: []
    friction: []

  # The player coordinates
  bbox =
    base: playerCoord[..] # player is standing on something

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


# console.log('Behind a wall2. No need to move')
# collideTest
#   map: [
#     # Floor below the player
#     [
#       ['all'] # ---> Z axis (depth)
#       ['top', 'top', null, 'top']
#     ]
#     # The player level
#     [
#       [null , null , 'none'] # ---> Z axis (depth)
#       [null , null , 'none'] # The wall
#     ]
#   ]


console.log('Behind a wall. No need to move')
collideTest
  map: [
    # Floor below the player
    [
      ['all'] # ---> Z axis (depth)
      ['top', null, 'top']
    ]
    # The player level
    [
      [null , 'none'] # ---> Z axis (depth)
      [null , 'none'] # The wall
    ]
  ]


console.log('Simple walk with top in front, no moving (Do not move the player unnecessarily)')
collideTest
  map: [
    # Floor below the player
    [
      ['all'       ] # ---> Z axis (depth)
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
      ['all'] # ---> Z axis (depth)
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
      [null, 'all'] # ---> Z axis (depth)
      [null, 'top']
    ]
    # The player level (empty)
  ]


console.log('Bump the player forward 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['all'      ] # ---> Z axis (depth)
      [null, 'top']
    ]
    # The player level (empty)
  ]


console.log('Bump the player backward 1 unit')
collideTest
  playerCoord: [0, 1, 1]
  expectedDepth: 0
  map: [
    # Floor below the player
    [
      [null , 'all'] # ---> Z axis (depth)
      ['top'       ]
    ]
    # The player level (empty)
  ]


console.log('Simple wall. Bump the player over 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['all'      ] # ---> Z axis (depth)
      [null, 'top']
    ]
    # The player level
    [
      [          ] # ---> Z axis (depth)
      ['none'    ] # The wall
    ]
  ]


console.log('Simple wall2. Bump the player over 1 unit')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['all'       ] # ---> Z axis (depth)
      ['top', 'top']
    ]
    # The player level
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
      ['all'               ] # ---> Z axis (depth)
      [null , 'top',       ]
    ]
    # The player level
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
      ['all'               ] # ---> Z axis (depth)
      [null , 'top', 'none']
    ]
    # The player level
    [
      [                    ] # ---> Z axis (depth)
      ['none', null, 'none'] # The wall
    ]
  ]

console.log('Complex wall2. Do not move the player even though there is a post in front')
collideTest
  # expectedDepth: 1
  playerCoord: [0, 1, 1]
  map: [
    # Floor below the player
    [
      [null , 'all'        ] # ---> Z axis (depth)
      [null , 'top'        ]
    ]
    # The player level
    [
      [                    ] # ---> Z axis (depth)
      [null , null , 'none'] # The wall
    ]
  ]


console.log('Simple wall. Bump the player over 1 unit even though there is no floor')
collideTest
  expectedDepth: 1
  map: [
    # Floor below the player
    [
      ['all'] # ---> Z axis (depth)
      ['top']
    ]
    # The player level
    [
      [      ] # ---> Z axis (depth)
      ['none'] # The wall
    ]
  ]


console.log('Simple wall. Move up only if necessary. It is not necessary in this case')
collideTest
  # expectedDepth: 1
  playerCoord: [0, 1, 2]
  map: [
    # Floor below the player
    [
      [null, null,  'all'] # ---> Z axis (depth)
      [null, 'top', 'top']
    ]
    # The player level
    [
      [      ] # ---> Z axis (depth)
      ['none'] # The wall
    ]
  ]
