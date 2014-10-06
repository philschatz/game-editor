PaletteManager = require '../../voxels/palette-manager'

module.exports = new class GameManager
  _getGame: -> window.game
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


  _getFlattenedBlock: (coords) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    y = coords[1]
    @_getGame().sparseCollisionMap[dir]['' + Math.floor(coords[axis]) + '|' + y]

  _getBackFlattenedBlock: (coords) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    y = coords[1]
    @_getGame().sparseCollisionMap[(dir + 2).mod(4)]['' + Math.floor(coords[axis]) + '|' + y]


  isCameraAxis: (axis) ->
    @get2DInfo().axis is axis

  getBlockDepths: (coords) ->
    {axis, perpendicAxis, dir, multiplier} = @get2DInfo()
    min = @_getFlattenedBlock(coords)
    max = @_getBackFlattenedBlock(coords)
    coord = [null, coords[1], null]
    coord[axis] = Math.floor(coords[axis])
    blocks = []
    for a in [min..max] by -1 * multiplier
      coord[perpendicAxis] = a
      color = @_getGame().getBlock(coord)
      blocks.push([a, PaletteManager.collisionFor(color)]) if color
    blocks

  getFirstBlockDepth: (coords) ->
    @_getFlattenedBlock(coords)

  blockTypeAt: (coords) ->
    color = @_getGame().getBlock(coords)
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
