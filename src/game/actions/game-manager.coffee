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


  get2DBlock: (coords) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    y = coords[1]
    @getGame().sparseCollisionMap[dir]['' + Math.floor(coords[axis]) + '|' + y]

  getPlayerBlock: ->
    @get2DBlock(@getGame().controlling.aabb().base)

  isCameraAxis: (axis) ->
    @get2DInfo().axis is axis
