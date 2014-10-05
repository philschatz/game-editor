_ = require 'underscore'
GameManager = require '../actions/game-manager'
PaletteManager = require '../../voxels/palette-manager'

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
    blockDepth = GameManager.getFlattenedBlock(coords)
    belowBlockDepth = GameManager.getFlattenedBlock([coords[0], y - 1, coords[2]])

    myBlock = GameManager.getPlayerFlattenedBlock()
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
      else if isCameraAxis

        if isBehind(myBlock)
          # I am walking and I am behind a block
          console.log 'walking behind a block'
          console.log game.controlling
          tile = false

        else

          ###
            This bit is hairy. (modeled in the space between lighthouse and a pillar)
            1. If first below is top/all and there is no wall above it just move to it; done
            2. Find last wall (nearest me)
            3. Loop through all adjacent walls until an opening appears
            4. From there, find last below (nearest opening) that is top/all and move to it; done
            5. Otherwise, move in front of first and let fall; done
          ###

          # 1. If first below is top/all ...
          tmpCoords = [coords[0], y - 1, coords[2]]
          tmpCoords[perpendicAxis] = belowBlockDepth
          if belowBlockDepth? and PaletteManager.collisionFor(GameManager.getGame().getBlock(tmpCoords)) in ['top', 'all']
            # 1. ... and there is no wall above it ...
            tmpCoords[1] = y
            unless GameManager.getGame().getBlock(tmpCoords)
              # 1. ... just move to it; done
              newDepth = belowBlockDepth
              tile = false

          unless newDepth?
            # 2. Find last wall (nearest me)
            blockDepths = GameManager.getBlockDepthsInFrontOf(coords, true)
            if blockDepths.length
              lastWallDepth = _.first(blockDepths)
              # 3. Loop through all adjacent walls until an opening appears
              i = 0
              while blockDepths[i]? and blockDepths[i] is lastWallDepth + i * multiplier
                i++
              lastWallDepth += i * multiplier

              # 4. From there, find last below (nearest opening) that is top/all and move to it; done
              tmpCoords[1] = y - 1
              tmpCoords[perpendicAxis] = lastWallDepth
              walkableDepth = _.first(GameManager.getBlockDepthsInFrontOf(tmpCoords, true))
              if walkableDepth?
                newDepth = walkableDepth
                tile = false
              else
                # 5. Otherwise, move in front of first and let fall; done
                newDepth = lastWallDepth
                tile = false



    if newDepth? and Math.floor(newDepth) isnt Math.floor(@controlling.aabb().base[perpendicAxis])
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
