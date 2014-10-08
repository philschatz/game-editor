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
            if myColor and belowStart? and not belowEnd?
              belowEnd = B - multiplier

            unless myColor
              belowColor = @_getBlock(pos)

              # Check for endDepth first since it must run at least once after startDepth
              if belowStart? and not belowEnd?

                if belowColor
                  type = PaletteManager.collisionFor(belowColor)
                  unless type in ['top', 'all']
                    belowEnd = B - multiplier
                else
                  belowEnd = B - multiplier

              else

                if belowColor and not wallDepth?
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

  _clearDebugVoxels: ->
    return unless window.scene?
    debugs = []
    for item in window.scene.children
      debugs.push(item) if item.isDebug
    for item in debugs
      window.scene.remove(item)

  _addDebugVoxel: ([x, y, z], c) ->
    return unless window.scene?

    color = switch c
      when 1 then 0xFF0000
      when 2 then 0x999999
      when 3 then 0x333333
      else 0x0000FF

    size = (16/16) + .5 + 2 * ((c - 1) * .2)
    wireframeCube = new THREE.BoxGeometry(size, size , size)
    wireframeOptions =
      color: color
      wireframe: true
      wireframeLinewidth: 1
      opacity: .5

    wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
    voxel = new THREE.Mesh(wireframeCube, wireframeMaterial)
    voxel.isDebug = true
    voxel.position.x = x + size / 2
    voxel.position.y = y + size / 2
    voxel.position.z = z + size / 2
    window.scene.add(voxel)




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


    # Mark up all the debug voxels
    @_clearDebugVoxels()
    coord = [null, null, null]
    for key, info of @_sparseCollisionMap[dir]
      [y, a] = key.split('|')
      y = parseInt(y)
      a = parseInt(a)
      coord[1] = y
      coord[axis] = a

      if info.wallDepth?
        coord[perpendicAxis] = info.wallDepth
        @_addDebugVoxel(coord, 1)

      coord[1] = y - 1
      if info.belowStart
        coord[perpendicAxis] = info.belowStart
        @_addDebugVoxel(coord, 2)

      if info.belowEnd
        coord[perpendicAxis] = info.belowEnd
        @_addDebugVoxel(coord, 3)




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
