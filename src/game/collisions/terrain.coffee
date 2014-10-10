_ = require 'underscore'
GameManager = require '../actions/game-manager'


isPlayerBehind = (multiplier, playerDepth, depth) ->
  return false unless depth?
  multiplier * (playerDepth - depth) < 0


# other -
# bbox - player bbox
# vec -
# resting -

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

    isHit = false

    y = coords[1]

    {perpendicAxis, multiplier, axis} = GameManager.get2DInfo()

    isCameraAxis = axis is collisionAxis
    isVelocityAxis = vec3[collisionAxis] isnt 0

    playerBase = @controlling.aabb().base
    playerDepth = Math.floor(playerBase[perpendicAxis])


    newDepth = playerDepth
    scaleJustToBeSafe = 1.5

    setNewDepth = (depth) ->
      if Math.floor(depth) isnt Math.floor(newDepth)
        newDepth = Math.floor(depth)


    if isVelocityAxis

      # If the player is behind a wall then operate as if the level was rotated 180 degrees.
      # This means reversing the blockDepth lists and changing the `+ multiplier` to
      # put the player "in front" of a wall
      {wallDepth} = GameManager.getFlattenedInfo(playerBase)
      isBehindWall = isPlayerBehind(multiplier, playerDepth, wallDepth) and not isPlayerBehind(-1* multiplier, playerDepth, GameManager.getFlattenedInfo(playerBase, true)?.wallDepth)
      isBehindWallMultiplier = if isBehindWall then -1 else 1

      {wallDepth, wallType, collideStart, collideEnd} = GameManager.getFlattenedInfo(coords, isBehindWall)

      # Make sure we are in front of any wall coming up (or behind if isBehindWall)
      # if not isBehindWall and isPlayerBehind(multiplier, playerDepth, wallDepth)
      #   newDepth = wallDepth + multiplier
      # else if isBehindWall and isPlayerInFront(multiplier, playerDepth, wallDepth)
      #   newDepth = wallDepth - multiplier

      if collisionAxis is 1 and dir is 1 # Jumping

      else if collisionAxis is 1 and dir is -1 and coords[1] <= playerBase[1] + dir

        # When falling, line the player up in the "acceptable" depth which has a collision block below

        # This is inlined several times
        if collideStart?
          isHit = true # Hit!
          if collideStart <= playerDepth <= collideEnd
            # depth is fine. May have been set by above code (icky but I'm lazy)
            setNewDepth(playerDepth)
          else if playerDepth < collideStart
            setNewDepth(collideStart)
          else if playerDepth > collideEnd
            setNewDepth(collideEnd)

        else if wallType in ['top', 'all']
          isHit = true # Hit!
          setNewDepth(wallDepth)


      else if isCameraAxis

        {collideStart, collideEnd} = GameManager.getFlattenedInfoCoords(coords[0], y - 1, coords[2], isBehindWall)

        # This is inlined several times
        if collideStart?
          if collideStart <= playerDepth <= collideEnd
            # depth is fine. May have been set by above code (icky but I'm lazy)
            setNewDepth(playerDepth)
          else if playerDepth < collideStart
            setNewDepth(collideStart)
          else if playerDepth > collideEnd
            setNewDepth(collideEnd)


        # If I am walking into a wall
        if wallDepth? and not collideStart?
          # If there was a collideStart it already shifted me to that position.
          # But there isn't so just shift me in front of the wall and I will start falling
          setNewDepth(wallDepth + multiplier * isBehindWallMultiplier)


    if newDepth? and Math.floor(newDepth) isnt Math.floor(playerDepth)

      # Moving back is only necessary when the block below is a hole or if there is a wall on or in front of it
      # Without this, the player "snaps" in front of a wall
      # when they don't really need to.
      newCoords = playerBase
      console.log 'moving from:', playerBase
      newCoords[perpendicAxis] = Math.floor(newDepth) + .5 # to center the player
      console.log 'moving to  :', newCoords
      @controlling.moveTo(newCoords[0], newCoords[1], newCoords[2])

    return unless isHit

    # boilerplate code?
    return if Math.abs(vec3[collisionAxis]) < Math.abs(edge)
    vec3[collisionAxis] = vec[axes[collisionAxis]] = edge
    other.acceleration[axes[collisionAxis]] = 0
    resting[axes[collisionAxis]] = dir
    other.friction[axes[(collisionAxis + 1) % 3]] = other.friction[axes[(collisionAxis + 2) % 3]] = (if collisionAxis is 1 then self.friction else 1)
    true

  @collideVoxels bbox, vec3, hit.bind(this)
  return
