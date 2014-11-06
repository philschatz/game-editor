PaletteManager = require '../../voxels/palette-manager'

GameManager = new class GameManager

  DEBUG: false

  _loadMax: 50
  _cachedInfo: null
  _playerRotatedBehindWall: false

  _getGame: -> window.game

  load: (@_map) ->
    @_sparseCollisionMap = [{}, {}, {}, {}]

    for dir in [0..3]
      multiplier = if dir < 2 then -1 else 1
      for y in [0..@_loadMax]
        for a in [-@_loadMax..@_loadMax]
          wallDepth = null
          wallOrientation = null
          ladderDepth = null
          type = null
          collideStart = null
          collideEnd = null
          for b in [-@_loadMax..@_loadMax]
            B = b * multiplier
            if dir % 2 is 0
              pos = [a, y, B]
            if dir % 2 is 1
              pos = [B, y, a]

            {color, orientation} = @_map.getInfo(pos[0], pos[1], pos[2])
            myColor = color
            type = PaletteManager.collisionFor(myColor)

            if not ladderDepth? and type in ['ladder'] and not wallDepth?
              # The ladder doesn't count if it's behind a wall
              ladderDepth = B

            if not wallDepth? and myColor and type not in ['ladder', 'none']
              wallDepth = B
              wallType = PaletteManager.collisionFor(myColor)
              wallOrientation = orientation


            # belowCollidables are only valid if nothing is above them (`not myColor`)
            pos[1] = y + 1
            aboveColor = @_map.getColor(pos[0], pos[1], pos[2])

            if myColor and not collideStart? and not aboveColor
              if type in ['top', 'all']
                collideStart = B


            # if a collideStart is followed by a wall then stop
            if aboveColor and collideStart? and collideStart isnt B and not collideEnd?
              collideEnd = B - multiplier

            unless aboveColor

              # Check for endDepth first since it must run at least once after startDepth
              if collideStart? and collideStart isnt B and not collideEnd?

                if myColor
                  type = PaletteManager.collisionFor(myColor)
                  unless type in ['top', 'all']
                    collideEnd = B - multiplier
                else
                  collideEnd = B - multiplier

            # Must comment out because we need to store the back wall depth
            # if wallDepth? and collideEnd?
            #   break

          # Add the wallDepth and the range of belowCollidables
          if wallDepth? or ladderDepth?

            unless (collideStart? and collideEnd?) or (not collideStart? and not collideEnd?)
              throw new Error('BUG: collideStart should always have a matching collideEnd')

            # collideStart is always <= collideEnd
            if collideEnd?
              unless collideStart <= collideEnd
                [collideStart, collideEnd] = [collideEnd, collideStart]
            @_sparseCollisionMap[dir]["#{y}|#{a}"] = {
              wallDepth
              wallType
              wallOrientation
              ladderDepth
              collideStart
              collideEnd
            }

  _clearDebugVoxels: ->
    return unless @DEBUG
    return unless window.scene?
    debugs = []
    for item in window.scene.children
      debugs.push(item) if item.isDebug
    for item in debugs
      window.scene.remove(item)

  _addDebugVoxel: ([x, y, z], c) ->
    return unless @DEBUG
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

      if info.collideEnd
        if info.wallDepth is info.collideStart
          coord[perpendicAxis] = info.collideEnd
        else
          coord[perpendicAxis] = info.collideStart
        @_addDebugVoxel(coord, 2)

    # End debug voxels. Return info
    @_cachedInfo

  isPlayerBehind: (depth=null, playerDepth=null) ->
    {multiplier, axis} = @get2DInfo()

    unless depth?
      {x, y, z} = @_getGame().controlling.position
      {wallDepth} = @getFlattenedInfoCoords(x, y, z, false)
      depth = wallDepth

    unless playerDepth?
      playerPosition = @_getGame().controlling.position
      switch axis
        when 0 then playerDepth = playerPosition.x
        when 2 then playerDepth = playerPosition.z
        else throw new Error('BUG: Invalid axis')

    return false unless depth?
    multiplier * (playerDepth - depth) <= 0

  setPlayerRotatedBehindWall: (@_playerRotatedBehindWall) ->

  getFlattenedInfo: (coords, isReversed) ->
    [x, y, z] = coords
    @getFlattenedInfoCoords(x, y, z, isReversed)


  getFlattenedInfoCoords: (x, y, z, isReversed) ->
    {axis, perpendicAxis, dir} = @get2DInfo()
    a = switch axis
      when 0 then x
      when 2 then z
      else throw new Error('Invalid Axis')

    a = Math.floor(a) # Can be x or z
    y = Math.floor(y)
    dir = (dir + 2) % 4 if isReversed
    @_sparseCollisionMap[dir]["#{y}|#{a}"] or {}


  blockTypeAt: (coords) ->
    color = @_map.getColor(coords[0], coords[1], coords[2])
    if color
      PaletteManager.collisionFor(color)
    else
      undefined


module.exports = window.GameManager = GameManager
