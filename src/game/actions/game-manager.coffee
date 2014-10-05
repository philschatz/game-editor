module.exports = new class GameManager
  getGame: -> window.game
  get2DInfo: ->
    dir = @getGame().controlling.rotation.y / Math.PI * 2
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


  getFlattenedBlock: (coords) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    y = coords[1]
    @getGame().sparseCollisionMap[dir]['' + Math.floor(coords[axis]) + '|' + y]

  getPlayerFlattenedBlock: ->
    @getFlattenedBlock(@getGame().controlling.aabb().base)

  isCameraAxis: (axis) ->
    @get2DInfo().axis is axis

  # Returns an array of coords. (me ... block-on-screen] (inclusive)
  # So you can loop and decide how much to change depth
  getBlockDepthsInFrontOf: (coords, isMeInclusive) ->
    {axis, perpendicAxis, dir, multiplier} = @get2DInfo()
    min = @getFlattenedBlock(coords)
    max = Math.floor(coords[perpendicAxis])
    max += (16/16) * multiplier unless isMeInclusive
    coord = [0, coords[1], 0]
    coord[axis] = Math.floor(coords[axis])
    blocks = []
    for a in [max..min] by multiplier
      coord[perpendicAxis] = a
      blocks.push(a) if @getGame().getBlock(coord)
    blocks
