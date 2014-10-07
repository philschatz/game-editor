PaletteManager = require '../../voxels/palette-manager'

module.exports = new class GameManager

  _loadMax: 50
  _cachedInfo: null

  _getGame: -> window.game
  _getBlock: (coord) -> @_getGame().getBlock(coord)

  load: ->
    @_sparseCollisionMap = [{}, {}, {}, {}]

    for dir in [0..3]
      multiplier = if dir < 2 then -1 else 1
      for y in [0..@_loadMax]
        for a in [-@_loadMax..@_loadMax]
          wallDepth = null
          wallType = null
          belowStart = null
          belowEnd = null
          for b in [-@_loadMax..@_loadMax]
            B = b * multiplier
            if dir % 2 is 0
              pos = [a, y, B]
            if dir % 2 is 1
              pos = [B, y, a]

            myColor = @_getBlock(pos)
            if not wallDepth? and myColor
              wallDepth = B
              wallType = PaletteManager.collisionFor(myColor)

            # belowCollidables are only valid if nothing is above them (`not myColor`)
            pos[1] = y - 1

            # if a belowStart is followed by a wall then stop
            if belowStart? and myColor
              belowEnd = B - multiplier

            unless myColor

              # Check for endDepth first since it must run at least once after startDepth
              if belowStart? and not belowEnd?
                belowColor = @_getBlock(pos)
                if belowColor
                  type = PaletteManager.collisionFor(belowColor)
                  unless type in ['top', 'all']
                    belowEnd = B - multiplier
                else
                  belowEnd = B - multiplier

              else
                belowColor = @_getBlock(pos)
                if belowColor
                  type = PaletteManager.collisionFor(belowColor)
                  if type in ['top', 'all']
                    belowStart = B

            if wallDepth? and belowEnd?
              break

          # Add the wallDepth and the range of belowCollidables
          if wallDepth? or belowEnd?
            # belowStart is always <= belowEnd
            unless belowStart <= belowEnd
              [belowStart, belowEnd] = [belowEnd, belowStart]
            @_sparseCollisionMap[dir]["#{y}|#{a}"] = {
              wallDepth
              wallType
              belowStart
              belowEnd
            }

  invalidateCache: -> @_cachedInfo = null

  get2DInfo: ->
    return @_cachedInfo if @_cachedInfo

    dir = @_getGame().controlling.rotation.y / Math.PI * 2
    dir = Math.round(dir).mod(4)
    multiplier = 1
    multiplier = -1  if dir >= 2
    if dir.mod(2) is 0 #x
      axis = 0
      perpendicAxis = 2
    else #z
      axis = 2
      perpendicAxis = 0
    @_cachedInfo = {axis, perpendicAxis, dir, multiplier}
    @_cachedInfo


  getFlattenedInfo: (coords, isReversed) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    a = Math.floor(coords[axis]) # Can be x or z
    y = Math.floor(coords[1])
    dir = (dir + 2) % 4 if isReversed
    @_sparseCollisionMap[dir]["#{y}|#{a}"] or {}


  blockTypeAt: (coords) ->
    color = @_getBlock(coords)
    if color
      PaletteManager.collisionFor(color)
    else
      undefined
