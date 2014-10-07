PaletteManager = require '../../voxels/palette-manager'

module.exports = new class GameManager


  _getGame: -> window.game
  _getBlock: (coord) -> @_getGame().getBlock(coord)

  load: ->
    @_sparseCollisionMap = [{}, {}, {}, {}]

    for dir in [0..0]
      for y in [0..50]
        for a in [-50..50]
          color = null
          for b in [-50..50]
            B = b
            B = -b if dir < 2
            if dir % 2 is 0
              pos = [a, y, B]
            if dir % 2 is 1
              pos = [B, y, a]
            color = @_getBlock(pos)

            if color
              @_sparseCollisionMap[dir]['' + a + '|' + y] ?= []
              list = @_sparseCollisionMap[dir]['' + a + '|' + y]
              list.push({depth: B, type: PaletteManager.collisionFor(color)})

  get2DInfo: ->
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
    {axis, perpendicAxis, dir, multiplier}


  _getFlattenedBlock: (coords, isReversed) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    y = coords[1]
    dir = (dir + 2).mod(4) if isReversed
    @_sparseCollisionMap[dir]['' + Math.floor(coords[axis]) + '|' + y] or []


  isCameraAxis: (axis) ->
    @get2DInfo().axis is axis

  getBlockDepths: (coords, isReversed) ->
    @_getFlattenedBlock(coords, isReversed)

  getFirstBlockDepth: (coords, isReversed) ->
    @_getFlattenedBlock(coords, isReversed)[0]

  blockTypeAt: (coords) ->
    color = @_getBlock(coords)
    if color
      PaletteManager.collisionFor(color)
    else
      undefined

  # Returns an array of coords. (me ... block-on-screen] (inclusive)
  # So you can loop and decide how much to change depth
  # _getBlockDepthsInFrontOf: (coords, isMeInclusive) ->
  #   {axis, perpendicAxis, dir, multiplier} = @get2DInfo()
  #   min = @_getFlattenedBlock(coords)
  #   max = Math.floor(coords[perpendicAxis])
  #   max += (16/16) * multiplier unless isMeInclusive
  #   coord = [0, coords[1], 0]
  #   coord[axis] = Math.floor(coords[axis])
  #   blocks = []
  #   for a in [max..min] by multiplier
  #     coord[perpendicAxis] = a
  #     color = @_getGame().getBlock(coord)
  #     blocks.push([a, PaletteManager.collisionFor(color)]) if color
  #   blocks
  #
  # _getBlockDepthsBehindOf: (coords, isMeInclusive) ->
  #   {axis, perpendicAxis, dir, multiplier} = @get2DInfo()
  #   max = @_getBackFlattenedBlock(coords)
  #   min = Math.floor(coords[perpendicAxis])
  #   min += (16/16) * multiplier unless isMeInclusive
  #   coord = [0, coords[1], 0]
  #   coord[axis] = Math.floor(coords[axis])
  #   blocks = []
  #   for a in [min..max] by -1 * multiplier
  #     coord[perpendicAxis] = a
  #     blocks.push(a) if @_getGame().getBlock(coord)
  #   blocks
