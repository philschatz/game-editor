# From collide-3d-tilemap/index.js with tile lookup disabled
module.exports = (field, tilesize, dimensions, offset) ->
  collide = (box, vec, oncollision) ->

    # collide x, then y
    collideaxis = (i_axis) ->
      j_axis = (i_axis + 1) % 3
      k_axis = (i_axis + 2) % 3
      posi = vec[i_axis] > 0
      leading = box[(if posi then "max" else "base")][i_axis]
      dir = (if posi then 1 else -1)
      i_start = Math.floor(leading / tilesize)
      i_end = (Math.floor((leading + vec[i_axis]) / tilesize)) + dir
      j_start = Math.floor(box.base[j_axis] / tilesize)
      j_end = Math.ceil(box.max[j_axis] / tilesize)
      k_start = Math.floor(box.base[k_axis] / tilesize)
      k_end = Math.ceil(box.max[k_axis] / tilesize)
      done = false
      edge_vector = undefined
      edge = undefined
      tile = undefined

      # loop from the current tile coord to the dest tile coord
      #    -> loop on the opposite axis to get the other candidates
      #      -> if `oncollision` return `true` we've hit something and
      #         should break out of the loops entirely.
      #         NB: `oncollision` is where the client gets the chance
      #         to modify the `vec` in-flight.
      # once we're done translate the box to the vec results
      step = 0
      i = i_start

      while not done and i isnt i_end
        continue  if i < offset[i_axis] or i >= dimensions[i_axis]
        j = j_start

        while not done and j isnt j_end
          continue  if j < offset[j_axis] or j >= dimensions[j_axis]
          k = k_start

          while k isnt k_end
            continue  if k < offset[k_axis] or k >= dimensions[k_axis]
            coords[i_axis] = i
            coords[j_axis] = j
            coords[k_axis] = k
            # tile = field.apply(field, coords)
            # continue  if tile is `undefined`
            edge = (if dir > 0 then i * tilesize else (i + 1) * tilesize)
            edge_vector = edge - leading
            if oncollision(i_axis, tile, coords, dir, edge_vector)
              done = true
              break
            ++k
          ++j
        ++step
        i += dir
      coords[0] = coords[1] = coords[2] = 0
      coords[i_axis] = vec[i_axis]
      box.translate coords
      return
    return if vec[0] is 0 and vec[1] is 0 and vec[2] is 0
    collideaxis(0)
    collideaxis(1)
    collideaxis(2)
    return
  dimensions = dimensions or [
    Math.sqrt(field.length) >> 0
    Math.sqrt(field.length) >> 0
    Math.sqrt(field.length) >> 0
  ]
  offset = offset or [
    0
    0
    0
  ]
  field = (if typeof field is "function" then field else ((x, y, z) ->
    this[x + y * dimensions[1] + (z * dimensions[1] * dimensions[2])]
  ).bind(field))
  coords = undefined
  coords = [
    0
    0
    0
  ]
  return collide
