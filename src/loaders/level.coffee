$ = require 'jquery'
URI = require 'uri-js'


ajax = (url) ->
  $.ajax(url, {dataType: 'json'})


class Palette
  constructor: (@_root, @_config) ->
    @size = @_config.length
    @_voxelInfoCache = new Array(@size)
    @_voxelGeometryCache = {} # Key is the geometry url (may be relative)

  load: ->
    # Fetch all the voxel info
    promises = []
    for voxelConfig, color in @_config
      do (voxelConfig, color) =>
        if typeof voxelConfig is 'string' and /^(http:\/\/|\.|\/).+/.test(voxelConfig)
          path = URI.resolve(@_root, voxelConfig)

          promise = ajax(path)
          .then (info) =>
            switch info.type
              when 'geometry'
                if info.geometry_url
                  # Fetch the geometry file and add it to the info
                  return ajax(URI.resolve(path, info.geometry_url))
                  .then (geometry) =>
                    info.geometry = geometry
                    @_resolvePaths(info, path)
                    @_voxelInfoCache[color] = info
                    return
                else if info.geometry
                  @_resolvePaths(info, path)
                  @_voxelInfoCache[color] = info
                else
                  throw new Error('BUG! Invalid geometry voxel data')
              when 'texture'
                @_resolvePaths(info, path)
                @_voxelInfoCache[color] = info
              else
                throw new Error('BUG! Invalid voxel type')

          promises.push(promise)
        else if typeof voxelConfig isnt 'string'
          if voxelConfig.type is 'geometry' and voxelConfig.geometry_url
            # Fetch the geometry file and add it to the info
            promise = ajax(URI.resolve(@_root, voxelConfig.geometry_url))
            .then (geometry) =>
              voxelConfig.geometry = geometry
              @_resolvePaths(voxelConfig, path)
              @_voxelInfoCache[color] = voxelConfig
              return
            promises.push(promise)
          else
            @_resolvePaths(voxelConfig, @_root)
            @_voxelInfoCache[color] = voxelConfig
        else
          throw new Error('Bug! Unsupported Palette format')

    # Wait for all voxels to load
    $.when(promises...).then => @


  _resolvePaths: (voxelConfig, root) ->
    # Changes the relative paths in a voxel config

    switch voxelConfig.type
      when 'texture'
        for key in ['back_url', 'front_url', 'left_url', 'right_url', 'top_url', 'bottom_url']
          if voxelConfig[key]
            voxelConfig[key] = URI.resolve(root, voxelConfig[key])

  voxelInfo: (color) ->
    @_voxelInfoCache[color]

  allVoxels: ->
    @_voxelInfoCache


class Map
  _map: {}
  constructor: (root, config) ->
    # TODO: Uncompress if necessary
    # Map structure is '1|2|3' -> {color, orient}
    for [x, y, z, color, orientation] in config
      @_map["#{x}|#{y}|#{z}"] = {color, orientation}

  getInfo: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"] or {}

  getColor: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"]?.color or 0

  getOrientation: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"]?.orientation or 0



# Curry the function so we only fetch when necessary
load = (Type, rootUrl, info) -> () ->
  if typeof info is 'string'
    url = URI.resolve(rootUrl, info)
    promise = ajax(url)
    .then (config) ->
      obj = new Type(rootUrl, config)
      if obj.load?
        return obj.load()
      else
        return obj
  else
    promise = $.Deferred()
    promise.resolve(new Type(rootUrl, info))
  promise



parseLevel = (url, isShallow, {name, default_coords, palette, map}) ->
  fetchPalette = load(Palette, url, palette)
  fetchMap = load(Map, url, map)
  if isShallow
    return {name, default_coords, fetchPalette, fetchMap}
  else
    palettePromise = fetchPalette()
    mapPromise = fetchMap()
    return $.when(palettePromise, mapPromise).then (palette, map) ->
      return {name, default_coords, palette, map}



module.exports =
  load: (url, config, isShallow) ->
    if config
      promise = $.Deferred()
      promise.resolve(parseLevel(url, isShallow, config))

    else
      promise = ajax(url)
      .then (config) =>
        parseLevel(url, isShallow, config)

    promise
