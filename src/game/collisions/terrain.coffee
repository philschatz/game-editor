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

    if coords[1] < -2
      console.warn('You died by falling too much')
      return true

    y = coords[1]
    # Don't reallocate an array
    belowCoords[0] = coords[0]
    belowCoords[1] = y - 1
    belowCoords[2] = coords[2]

    {perpendicAxis, multiplier, axis} = GameManager.get2DInfo()

    isCameraAxis = axis is collisionAxis
    isVelocityAxis = vec3[collisionAxis] isnt 0

    playerBase = @controlling.aabb().base
    playerDepth = Math.floor(playerBase[perpendicAxis])


    newDepth = playerDepth
    scaleJustToBeSafe = 1.5

    setNewDepth = (depth) ->
      if Math.floor(depth) isnt Math.floor(playerDepth)
        newDepth = Math.floor(depth)


    if isVelocityAxis

      # If the player is behind a wall then operate as if the level was rotated 180 degrees.
      # This means reversing the blockDepth lists and changing the `+ multiplier` to
      # put the player "in front" of a wall
      {wallDepth} = GameManager.getFlattenedInfo(playerBase)
      isBehindWall = isPlayerBehind(multiplier, playerDepth, wallDepth) and not isPlayerBehind(-1* multiplier, playerDepth, GameManager.getFlattenedInfo(playerBase, true)?.wallDepth)
      isBehindWallMultiplier = if isBehindWall then -1 else 1

      {wallDepth, wallType, belowStart, belowEnd} = GameManager.getFlattenedInfo(coords, isBehindWall)

      # Make sure we are in front of any wall coming up (or behind if isBehindWall)
      # if not isBehindWall and isPlayerBehind(multiplier, playerDepth, wallDepth)
      #   setNewDepth(wallDepth + multiplier)
      # else if isBehindWall and isPlayerInFront(multiplier, playerDepth, wallDepth)
      #   setNewDepth(wallDepth - multiplier)


      if collisionAxis is 1 and dir is 1 # Jumping

      else if collisionAxis is 1 and dir is -1 and coords[1] <= playerBase[1] + dir
        # HACK: revisit the efficacy of storing belowStart instead of just start
        # The best spot can be found in the range by looking above and belowStart
        {belowStart, belowEnd} = GameManager.getFlattenedInfo([coords[0], y + 1, coords[2]], isBehindWall)

        # When falling, line the player up in the "acceptable" depth which has a collision block below
        if wallType in ['top', 'all']
          tile = true # Hit!
          # This is inlined several times
          if belowStart?
            if belowStart <= playerDepth <= belowEnd
              # depth is fine. May have been set by above code (icky but I'm lazy)
              setNewDepth(playerDepth)
            else if playerDepth < belowStart
              setNewDepth(belowStart)
            else if playerDepth > belowEnd
              setNewDepth(belowEnd)

        else
          # This is inlined several times
          if belowStart?
            tile = true
            if belowStart <= playerDepth <= belowEnd
              # depth is fine. May have been set by above code (icky but I'm lazy)
              setNewDepth(playerDepth)
            else if playerDepth < belowStart
              setNewDepth(belowStart)
            else if playerDepth > belowEnd
              setNewDepth(belowEnd)



      else if isCameraAxis
        tile = false

        # This is inlined several times
        if belowStart?
          if belowStart <= playerDepth <= belowEnd
            # depth is fine. May have been set by above code (icky but I'm lazy)
            setNewDepth(playerDepth)
          else if playerDepth < belowStart
            setNewDepth(belowStart)
          else if playerDepth > belowEnd
            setNewDepth(belowEnd)


        # If I am walking into a wall
        if wallDepth? and not belowStart?
          # If there was a belowStart it already shifted me to that position.
          # But there isn't so just shift me in front of the wall and I will start falling
          setNewDepth(wallDepth + multiplier * isBehindWallMultiplier)


    if newDepth? and Math.floor(newDepth) isnt Math.floor(playerDepth)
      tile = false

      # Moving back is only necessary when the block below is a hole or if there is a wall on or in front of it
      # Without this, the player "snaps" in front of a wall
      # when they don't really need to.
      if isPlayerInFront(multiplier, playerDepth, newDepth) and canWalkOver(coords, belowCoords)
        # Don't move
      else
        newCoords = playerBase
        console.log 'moving from:', playerBase
        newCoords[perpendicAxis] = Math.floor(newDepth) + .5 # to center the player
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
