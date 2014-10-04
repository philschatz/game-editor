THE_MAP = window.THE_MAP = {}

addVoxel = (x, y, z, c) ->
  return unless c # Black voxels are ignored
  c = c + 1
  x = '' + x
  y = '' + y
  z = '' + z
  THE_MAP[x] = {}  unless THE_MAP[x]?
  THE_MAP[x][y] = {}  unless THE_MAP[x][y]?
  THE_MAP[x][y][z] = c
  return


getVoxel = (i, j, k) ->
  x = THE_MAP['' + i]
  return 0  unless x
  y = x['' + j]
  return 0  unless y
  z = y['' + k]
  z or 0

# https://gist.github.com/665235
decode = (string) ->
  output = []
  string.split('').forEach (v) ->
    output.push 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.indexOf(v)
    return
  output


buildFromHash = (hash=window.location.hash.substr(1), variantChooser) ->
  hashMask = null
  hashChunks = hash.split(':')
  chunks = {}
  animationFrames = []
  n = hashChunks.length
  j = 0
  while j < n
    chunk = hashChunks[j].split('/')
    chunks[chunk[0]] = chunk[1]
    j++
  frameMask = 'A'
  if (not hashMask or hashMask is frameMask) and chunks[frameMask]

    # decode geo
    current =
      x: 0
      y: 0
      z: 0
      c: 0

    data = decode(chunks[frameMask])
    i = 0
    l = data.length
    while i < l
      code = data[i++].toString(2)
      current.x += data[i++] - 32  if code.charAt(1) is '1'
      current.y += data[i++] - 32  if code.charAt(2) is '1'
      current.z += data[i++] - 32  if code.charAt(3) is '1'
      current.c += data[i++] - 32  if code.charAt(4) is '1'

      if code.charAt(0) is '1'
        color = current.c
        color = variantChooser(color) if variantChooser
        addVoxel current.x, current.y, current.z, color

  return getVoxel



module.exports = buildFromHash
