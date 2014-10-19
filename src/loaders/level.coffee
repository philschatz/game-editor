$ = require 'jquery'
URI = require 'uri-js'
HashManager = require '../editor/hash-manager'

ajax = (url) ->
  $.ajax(url, {dataType: 'json'})



GenericLoader_fetchUrl = (root, url) ->
  newUrl = URI.resolve(root, url)
  ajax(newUrl)
  .then (obj) =>
    GenericLoader_parseObject(newUrl, obj)

GenericLoader_parseObject = (root, obj) ->
  promises = []

  for key, value of obj
    do (key, value) =>
      if /_url$/.test(key)
        promise = GenericLoader_fetchUrl(root, value)
        .then (value) =>
          obj[key.replace(/_url$/, '')] = value

        promises.push(promise)
      else if /_urls$/.test(key)
        _.each value, (url) ->
          promise = GenericLoader_fetchUrl(root, url)
          .then (value) =>
            obj[key.replace(/_urls$/, 's')] ?= []
            obj[key.replace(/_urls$/, 's')].push(value)
          promises.push(promise)

      else if /_href$/.test(key)
        obj[key] = URI.resolve(root, value)
      else if typeof value is 'object'
        # Nested objects might have urls that need to be fetched
        promise = GenericLoader_parseObject(root, value)
        .then (v) =>
          obj[key] = v
        promises.push(promise)

  $.when(promises...).then ->
    obj


class Palette
  constructor: (@_config) ->
    @size = @_config.length

  voxelInfo: (color) ->
    @_config[color]

  allVoxels: ->
    @_config


class Map
  _map: {}
  constructor: (config=[]) ->
    # TODO: Uncompress if necessary
    # Map structure is '1|2|3' -> {color, orient}
    for [x, y, z, color, orientation] in config
      @_map["#{x}|#{y}|#{z}"] = {color, orientation}

  # boundingBox: ->
  #   {@x1, @y1, @z1, @x2, @y2, @z2}

  forEach: (iterator) ->
    for key, {color, orientation} of @_map
      coords = key.split('|')
      coords[0] = parseInt(coords[0])
      coords[1] = parseInt(coords[1])
      coords[2] = parseInt(coords[2])
      iterator(coords[0], coords[1], coords[2], color, orientation)

  getInfo: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"] or {}

  getColor: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"]?.color

  getOrientation: (x, y, z) ->
    @_map["#{x}|#{y}|#{z}"]?.orientation

  addVoxel: (x, y, z, color, orientation) ->
    @_map["#{x}|#{y}|#{z}"] = {color, orientation}

  removeVoxel: (x, y, z) ->
    delete @_map["#{x}|#{y}|#{z}"]


module.exports =
  load: (url) ->
    GenericLoader_fetchUrl(url, '')
    .then (obj) ->
      map = new Map(obj.map)
      palette = new Palette(obj.palette)
      obj.getMap = -> map
      obj.getPalette = -> palette
      obj

  loadHash: (paletteUrl) ->
    map = new Map()
    HashManager.loadFromHash window.location.hash.substring(1), (x, y, z, color, orientation) ->
      map.addVoxel(x, y, z, color, orientation)

    promise = GenericLoader_parseObject '',
      name: 'loaded-from-hash'
      default_position: [-1.5, 10, 2.5, 0]
      player_url: './data/player.json'
      palette_url: './data/palette-nature.json'

    promise.then (level) ->
      palette = new Palette(level.palette)

      level.getPalette = -> palette
      level.getMap = -> map
      level
