$ = require 'jquery'
_ = require 'underscore'
URI = require 'uri-js'
{EventEmitter} = require 'events'
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

  toJSON: ->
    _.extend({}, @_config)

  voxelInfo: (color) ->
    @_config[color]

  allVoxels: ->
    @_config


class Map extends EventEmitter
  _map: {}
  constructor: (config=[]) ->
    # TODO: Uncompress if necessary
    # Map structure is '1|2|3' -> {color, orient}
    for [x, y, z, color, orientation] in config
      @_map["#{x}|#{y}|#{z}"] = {color, orientation}

  toJSON: ->
    ret = for coordStr, info of @_map
      [x, y, z] = coordStr.split('|')
      x = parseInt(x)
      y = parseInt(y)
      z = parseInt(z)
      {color, orientation} = info
      foo = [x, y, z, color]
      foo.push(orientation) if orientation?
      foo
    ret


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
    throw new Error('Only whole numbers please') unless x is Math.floor(x)
    throw new Error('Only whole numbers please') unless y is Math.floor(y)
    throw new Error('Only whole numbers please') unless z is Math.floor(z)
    @_map["#{x}|#{y}|#{z}"] = {color, orientation}
    @emit('add', x, y, z, color, orientation)

  removeVoxel: (x, y, z) ->
    throw new Error('Only whole numbers please') unless x is Math.floor(x)
    throw new Error('Only whole numbers please') unless y is Math.floor(y)
    throw new Error('Only whole numbers please') unless z is Math.floor(z)
    delete @_map["#{x}|#{y}|#{z}"]
    @emit('remove', x, y, z)


# Used by .toJSON() to include the url and skip the loaded object
recStripThingsWithUrl = (obj) ->
  if typeof obj is 'object'
    for key, val of obj
      if /_url$/.test(key)
        key = key.substring(0, key.length - '_url'.length)
        delete obj[key]
      else if /_urls$/.test(key)
        key = key.substring(0, key.length - '_urls'.length) + 's'
        delete obj[key]
      else
        recStripThingsWithUrl(val)

module.exports =
  load: (url) ->
    GenericLoader_fetchUrl(url, '')
    .then (obj) ->
      map = new Map(obj.map)
      palette = new Palette(obj.palette)
      obj.getMap = -> map
      obj.getPalette = -> palette
      obj.toJSON = ->
        json = _.extend({}, obj)
        delete json.getMap
        delete json.getPalette
        delete json.toJSON
        # Assume the Map was changed. If so, no longer use the map_url
        if json.map_url
          delete json.map_url
        json.map = map.toJSON()

        # Assume the Palette did not change (if it started as a URL)
        json.palette = palette.toJSON()
        recStripThingsWithUrl(json)
        json

      obj

  loadHash: (paletteUrl) ->
    map = new Map()
    HashManager.loadFromHash(window.location.hash.substring(1), map)

    promise = GenericLoader_parseObject '',
      name: 'loaded-from-hash'
      default_position: [-1.5, 10, 2.5, 0]
      player_url: './data/player.json'
      palette_url: './data/palette-nature.json'

    promise.then (level) ->
      palette = new Palette(level.palette)

      level.getPalette = -> palette
      level.getMap = -> map
      level.toJSON = ->
        json = _.extend({}, level)
        delete json.getMap
        delete json.getPalette
        delete json.toJSON
        # Assume the Map was changed. If so, no longer use the map_url
        if json.map_url
          delete json.map_url
        json.map = map.toJSON()
        # Assume the Palette did not change (if it started as a URL)
        json.palette = palette.toJSON()
        recStripThingsWithUrl(json)
        json

      level
