THREE = require '../../three'
GameManager = require '../actions/game-manager'

isPlayerBehind = (multiplier, playerDepth, depth) ->
  return false unless depth?
  multiplier * (playerDepth - depth) <= 0

# So we do not reinstantiate objects needlessly
DEST_VECTOR = new THREE.Vector3()


# States that require shifting and how to shift:
#
# - idle        none
# - jumping     be in front of walls (unless isBehind)
# - falling     be in front of walls (unless isBehind) and above top if there is one
# - walking     be in front of walls (unless isBehind) and above top if there is one
# - climbing    be inside the ladder unless there is a closer ladder neighbor (so sprite doesn't clip)
#
# The only way isBehind can be set is if we rotated ourselves into that position
# - so it should always get unset when moving
#
# So, collision detector only cares about the 'top' block below the player and
# another tick adjusts the player depth (depending on the current action?)
#
# Basically, only the destination depth (range) matters and if we adjust **before** collision detector then we should be OK.


module.exports = depthAdjuster = (physical, aabb, vec, stationary)->
  # Vector can be more than 1 away. if it is, then we should set it to 1 in some other part of the code)
  [DEST_VECTOR.x, DEST_VECTOR.y, DEST_VECTOR.z] = aabb.base
  vec.y = -1 if vec.y < -1

  DEST_VECTOR.addVectors(DEST_VECTOR, vec)

  isReversed = false


  {perpendicAxis, multiplier, axis} = GameManager.get2DInfo()
  playerBase = aabb.base # @controlling.aabb().base
  playerDepth = Math.floor(playerBase[perpendicAxis])

  newDepth = playerDepth
  setNewDepth = (depth, msg) ->
    if Math.floor(depth) isnt Math.floor(newDepth)
      newDepth = Math.floor(depth)
      console.log "Setting new depth depthAdjuster #{msg}"


  {wallType, wallDepth} = GameManager.getFlattenedInfoCoords(DEST_VECTOR.x, DEST_VECTOR.y, DEST_VECTOR.z, isReversed)

  # First move the player up if they would become inside a wall
  # if Math.floor(DEST_VECTOR.y) is Math.floor(aabb.base[1]) and isPlayerBehind(multiplier, playerDepth, wallDepth)
  dirDownAndBelowIsntTop = Math.floor(DEST_VECTOR.y) < Math.floor(aabb.base[1]) and GameManager.getFlattenedInfoCoords(DEST_VECTOR.x, DEST_VECTOR.y, DEST_VECTOR.z, isReversed).wallType isnt 'top'
  if (Math.floor(DEST_VECTOR.y) is Math.floor(aabb.base[1]) or dirDownAndBelowIsntTop) and isPlayerBehind(multiplier, playerDepth, wallDepth)
    # Make sure the depth keeps the player within the collideStart/End range for the pixel below

    {collideStart, collideEnd} = GameManager.getFlattenedInfoCoords(DEST_VECTOR.x, DEST_VECTOR.y - 1, DEST_VECTOR.z, isReversed)
    if collideStart # therefore must have collideEnd
      if playerDepth < collideStart
        setNewDepth(collideStart, 'depthAdjuster. walking. moving to start')
      else if playerDepth > collideEnd
        setNewDepth(collideEnd, 'depthAdjuster. walking. moving to end')
      # else if collideStart <= playerDepth <= collideEnd

    else
      # If there is no collideStart/End then just shove the player in front
      setNewDepth(wallDepth + multiplier, 'because-would-be-inside-wall')

  # If the player is climbing adjust the depth to be **inside** the ladder voxel
  if PlayerManager.isClimbing()
    # Ensure the player is in the ladder voxel
    {wallType, wallDepth, ladderDepth} = GameManager.getFlattenedInfoCoords(DEST_VECTOR.x, DEST_VECTOR.y, DEST_VECTOR.z, isReversed)

    if ladderDepth?
      setNewDepth(ladderDepth, 'because-is-ladder-and-climbing2')

  else

    # Look below the player to see how to adjust
    {collideStart, collideEnd} = GameManager.getFlattenedInfoCoords(DEST_VECTOR.x, aabb.base[1] - 1, DEST_VECTOR.z, isReversed)

    if collideStart # therefore must have collideEnd
      if playerDepth < collideStart
        setNewDepth(collideStart, 'depthAdjuster. moving to start')
      else if playerDepth > collideEnd
        setNewDepth(collideEnd, 'depthAdjuster. moving to end')
      # else if collideStart <= playerDepth <= collideEnd

  # if the depth has changed, update the player depth
  if newDepth isnt playerDepth
    switch perpendicAxis
      when 0 then @controlling.position.setX(newDepth + .5)
      when 2 then @controlling.position.setZ(newDepth + .5)
      else throw new Error('BUG: Invalid perpendicAxis')
