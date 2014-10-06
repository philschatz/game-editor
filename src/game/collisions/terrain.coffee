_ = require 'underscore'
GameManager = require '../actions/game-manager'

# other -
# bbox - player bbox
# vec -
# resting -

# collideTerrain
module.exports = (other, bbox, vec, resting) ->
  self = this
  axes = ['x', 'y', 'z']
  vec3 = [vec.x, vec.y, vec.z]
  hit = (axis, tile, coords, dir, edge) ->

    newDepth = null
    scaleJustToBeSafe = 1.5

    y = coords[1]
    belowCoords = [coords[0], y - 1, coords[2]]

    {perpendicAxis, multiplier} = GameManager.get2DInfo()

    isCameraAxis = GameManager.isCameraAxis(axis)
    isVelocityAxis = vec3[axis] isnt 0

    isPlayerBehind = (depth) ->
      multiplier * (bbox.base[perpendicAxis] - depth) < 0

    isPlayerInFront = (depth) ->
      multiplier * (bbox.base[perpendicAxis] - depth) > 0


    changeDepthIfBelowFrontHasCollide = (blocks) ->
      return unless blocks.length

      # If below front has collide then change depth
      [depth, type] = _.first(blocks)
      if type in ['top', 'all']
        newDepth = depth
        return true
      else if type
        # below is a wall. Just make sure we are in front of it
        unless isPlayerInFront(depth)
          newDepth = depth + multiplier
          return true
      else
        # Happily keep falling
      return false


    # True if there is a collision block below and no wall in the desired spot
    canWalkOver = ->
      GameManager.blockTypeAt(belowCoords) in ['top', 'all'] and not GameManager.blockTypeAt(coords)


    if isVelocityAxis

      # If below front has collide then change depth (only if we are not already standing on one)
      if GameManager.blockTypeAt(belowCoords) in ['top', 'all']
        tile = false
      else
        blocksBelow = GameManager.getBlockDepths(belowCoords)
        changeDepthIfBelowFrontHasCollide(blocksBelow)

      # if axis is 1 and dir is -1 and coords[1] isnt Math.floor(bbox.base[1])
      #   # the last bit checks to make sure we are actually falling instead of just checking the current voxel where the player is.
      #
      # else
      if isCameraAxis
        blocks = GameManager.getBlockDepths(coords)

        # If I am walking into a wall
        if blocks.length

          originalFront = _.first(blocks)

          while blocks.length
            [depth, type] = _.first(blocks)
            tmpCoord = belowCoords[...]
            tmpCoord[perpendicAxis] = depth + multiplier
            belowType = GameManager.blockTypeAt(tmpCoord)
            if belowType in ['top', 'all']
              break
            blocks = blocks[1..] # Pop!

          if blocks.length
            [depth] = _.first(blocks)
            newDepth = depth + multiplier

          else if canWalkOver()
            # We are already standing on something. Leave the player alone

          else
            blocks = [originalFront]
            [depth] = _.first(blocks)
            newDepth = depth + multiplier



    if newDepth? and Math.floor(newDepth) isnt Math.floor(@controlling.aabb().base[perpendicAxis])
      tile = false

      # Moving back is only necessary when the block below is a hole or if there is a wall on or in front of it
      # Without this, the player "snaps" in front of a wall
      # when they don't really need to.
      if isPlayerInFront(newDepth) and canWalkOver()
        # Don't move
      else
        newCoords = @controlling.aabb().base
        newCoords[perpendicAxis] = Math.floor(newDepth) + .5 # to center the player
        console.log 'moving from:', @controlling.aabb().base
        console.log 'moving to  :', newCoords
        @controlling.moveTo(newCoords[0], newCoords[1], newCoords[2])

    return  unless tile

    # boilerplate code?
    return if Math.abs(vec3[axis]) < Math.abs(edge)
    vec3[axis] = vec[axes[axis]] = edge
    other.acceleration[axes[axis]] = 0
    resting[axes[axis]] = dir
    other.friction[axes[(axis + 1) % 3]] = other.friction[axes[(axis + 2) % 3]] = (if axis is 1 then self.friction else 1)
    true

  @collideVoxels bbox, vec3, hit.bind(this)
  return
