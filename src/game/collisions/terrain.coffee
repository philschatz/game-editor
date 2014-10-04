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

    # Collision cases:
    #
    #    - I am falling and there is a flattened block below me: move my depth
    #    - I am walking and there is a flattened block next to me: move me in front of that block (may start falling)
    #    - walking and I am behind a block: do not move my depth
    #
    #
    newDepth = null
    scaleJustToBeSafe = 1.5

    y = coords[1]
    {perpendicAxis, multiplier} = GameManager.get2DInfo()
    blockDepth = GameManager.get2DBlock(coords)
    belowBlockDepth = GameManager.get2DBlock([coords[0], y - 1, coords[2]])

    myBlock = GameManager.getPlayerBlock()
    isCameraAxis = GameManager.isCameraAxis(axis)
    isVectorAxis = vec3[axis] isnt 0

    # isDirOfMovement = dir * vec3[cameraAxis] > 0;
    isBehind = (depth) ->
      multiplier * (bbox.base[perpendicAxis] - depth) < 0

    isInside = (depth) ->
      Math.floor(bbox.base[perpendicAxis]) is depth

    isBelowTopCollide = (depth) ->
      multiplier * (belowBlockDepth - depth) > 0


    # Collision cases:
    #
    #    - I am falling and there is a flattened block below me: move my depth
    #    - I am walking and there is a flattened block next to me: move me in front of that block
    #    - walking and I am behind a block: do not move my depth
    #
    #
    if isVectorAxis
      if axis is 1 and dir is -1

        # I am falling ...
        if blockDepth? and coords[1] isnt Math.floor(bbox.base[1]) # the last bit checks to make sure we are actually falling instead of just checking the current voxel where the player is.
          # .. and there is a flattened block below me
          # console.log('falling and block below');

          # If I am going to land on ground then do not change the depth
          unless tile
            console.log 'fallingg......'
            newDepth = blockDepth
            tile = true # HACK to tell the game there's a collision
      else if isCameraAxis and not isBehind(myBlock) and blockDepth?

        # I am walking and there is a flattened block next to me
        console.log 'walking and block next to me'
        newDepth = blockDepth + multiplier  if (isBehind(blockDepth) or isInside(blockDepth)) and isBelowTopCollide(blockDepth)
        tile = false
      else if isCameraAxis and isBehind(myBlock)

        # I am walking and I am behind a block
        console.log 'walking behind a block'
        tile = false

    if newDepth? and newDepth isnt @controlling.aabb().base[perpendicAxis]
      newCoords = @controlling.aabb().base
      newCoords[perpendicAxis] = newDepth + .5 # to center the player
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
