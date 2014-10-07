_ = require 'underscore'
GameManager = require '../actions/game-manager'


isPlayerBehind = (multiplier, playerDepth, depth) ->
  return false unless depth?
  multiplier * (playerDepth - depth) < 0

isPlayerInFront = (multiplier, playerDepth, depth) ->
  multiplier * (playerDepth - depth) > 0


# True if there is a collision block below and no wall in the desired spot
canWalkOver = (coords, belowCoords) ->
  GameManager.blockTypeAt(belowCoords) in ['top', 'all'] and not GameManager.blockTypeAt(coords)


# other -
# bbox - player bbox
# vec -
# resting -

belowCoords = [null, null, null]
tmpCoord = [null, null, null]


axes = ['x', 'y', 'z']
vec3 = [null, null, null]

# collideTerrain
module.exports = (other, bbox, vec, resting) ->
  self = this
  # Don't allocate an array
  vec3[0] = vec.x
  vec3[1] = vec.y
  vec3[2] = vec.z
  hit = (collisionAxis, tile, coords, dir, edge) ->

    newDepth = null
    scaleJustToBeSafe = 1.5

    y = coords[1]
    # Don't reallocate an array
    belowCoords[0] = coords[0]
    belowCoords[1] = y - 1
    belowCoords[2] = coords[2]

    {perpendicAxis, multiplier, axis} = GameManager.get2DInfo()

    isCameraAxis = axis is collisionAxis
    isVelocityAxis = vec3[collisionAxis] isnt 0

    playerBase = @controlling.aabb().base
    playerDepth = playerBase[perpendicAxis]


    # changeDepthIfBelowFrontHasCollide = (blocks) ->
    #   return unless blocks.length
    #
    #   # If below front has collide then change depth
    #   {depth, type} = _.first(blocks)
    #   if type in ['top', 'all']
    #     newDepth = depth
    #     return true
    #   else if type
    #     # below is a wall. Just make sure we are in front of it
    #     unless isPlayerInFront(multiplier, playerDepth, depth)
    #       newDepth = depth + multiplier
    #       return true
    #   else
    #     # Happily keep falling
    #   return false




    if isVelocityAxis

      # If the player is behind a wall then operate as if the level was rotated 180 degrees.
      # This means reversing the blockDepth lists and changing the `+ multiplier` to
      # put the player "in front" of a wall
      isBehindWall = isPlayerBehind(multiplier, playerDepth, GameManager.getFirstBlockDepth(playerBase)?.depth)
      isBehindWallMultiplier = if isBehindWall then -1 else 1

      # If below front has collide then change depth (only if we are not already standing on one)
      if GameManager.blockTypeAt(belowCoords) in ['top', 'all']
        tile = false
      else
        # blocksBelow = GameManager.getBlockDepths(belowCoords, isBehindWall)
        firstBlockBelow = GameManager.getFirstBlockDepth(belowCoords, isBehindWall)
        # Inlined changeDepthIfBelowFrontHasCollide(blocksBelow)
        if firstBlockBelow?

          # If below front has collide then change depth
          {depth, type} = firstBlockBelow
          if type in ['top', 'all']
            newDepth = depth
            # return true
          else if type
            # below is a wall. Just make sure we are in front of it
            unless isPlayerInFront(multiplier, playerDepth, depth)
              newDepth = depth + multiplier
              # return true
          else
            # Happily keep falling
          # return false


      if collisionAxis is 1 and dir is 1 # Jumping
        tile = false
        return
      else if collisionAxis is 1 and dir is -1

      # if collisionAxis is 1 and dir is -1 and coords[1] isnt Math.floor(bbox.base[1])
      #   # the last bit checks to make sure we are actually falling instead of just checking the current voxel where the player is.
      #
      # else
      else if isCameraAxis
        blocks = GameManager.getBlockDepths(coords, isBehindWall)

        # If I am walking into a wall
        if blocks.length

          originalFrontDepth = blocks[0].depth

          frontBlockDepth = null
          for block in blocks
            {depth, type} = block
            # Don't allocate an array
            tmpCoord[0] = belowCoords[0]
            tmpCoord[1] = belowCoords[1]
            tmpCoord[2] = belowCoords[2]
            tmpCoord[perpendicAxis] = depth + multiplier * isBehindWallMultiplier

            belowType = GameManager.blockTypeAt(tmpCoord)
            if belowType in ['top', 'all']
              frontBlockDepth = block.depth
              break

          if frontBlockDepth?
            newDepth = frontBlockDepth + multiplier * isBehindWallMultiplier

          else if canWalkOver(coords, belowCoords)
            # We are already standing on something. Leave the player alone

          else
            newDepth = originalFrontDepth + multiplier * isBehindWallMultiplier



    if newDepth? and Math.floor(newDepth) isnt Math.floor(playerDepth)
      tile = false

      # Moving back is only necessary when the block below is a hole or if there is a wall on or in front of it
      # Without this, the player "snaps" in front of a wall
      # when they don't really need to.
      if isPlayerInFront(multiplier, playerDepth, newDepth) and canWalkOver(coords, belowCoords)
        # Don't move
      else
        newCoords = playerBase
        newCoords[perpendicAxis] = Math.floor(newDepth) + .5 # to center the player
        console.log 'moving from:', bbox.base
        console.log 'moving to  :', newCoords
        @controlling.moveTo(newCoords[0], newCoords[1], newCoords[2])

    return  unless tile

    # boilerplate code?
    return if Math.abs(vec3[collisionAxis]) < Math.abs(edge)
    vec3[collisionAxis] = vec[axes[collisionAxis]] = edge
    other.acceleration[axes[collisionAxis]] = 0
    resting[axes[collisionAxis]] = dir
    other.friction[axes[(collisionAxis + 1) % 3]] = other.friction[axes[(collisionAxis + 2) % 3]] = (if collisionAxis is 1 then self.friction else 1)
    true

  @collideVoxels bbox, vec3, hit.bind(this)
  return
