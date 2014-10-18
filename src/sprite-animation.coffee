SpriteAnimationHandler = new class SpriteAnimationHandler
  animations: []
  update: (deltaTimeMs) ->
    for animation in @animations
      animation.update(deltaTimeMs)
  addToUpdate: (animation) ->
    @animations.push(animation)
  removeFromUpdate: (animation) ->
    i = @animations.indexOf(animation)
    if i >= 0
      @animations.splice(i, 1)


class Animation
  constructor: (@_offsets) ->

  start: (@_sprite) ->
    @_spriteTexture = @_sprite.material.map
    @isPlaying = true
    # @update(0)
    SpriteAnimationHandler.addToUpdate(@)

  pause:  -> @isPlaying = false
  resume: -> @isPlaying = true

  stop: ->
    @isPlaying = false
    @_curOffset = -1
    SpriteAnimationHandler.removeFromUpdate(@)

  # Returns newOffset (modulus'd)
  newOffset: (deltaTimeMs) -> throw new Error('Subclass must implement')

  update: (deltaTimeMs) ->
    if @isPlaying
      newOffset = @newOffset(deltaTimeMs)

      if newOffset isnt @_curOffset
        throw new Error('Invalid offset') unless @_offsets[newOffset]
        @_curOffset = newOffset
        [x, y] = @_offsets[newOffset]
        x = x * @_spriteTexture.repeat.x
        y = y * @_spriteTexture.repeat.y
        @_spriteTexture.offset.set(x, y)


class StillAnimation extends Animation

  constructor: (offset) ->
    super([offset])

  newOffset: (deltaTimeMs) -> 0


class TimeAnimation extends Animation

  constructor: (@_msBetweenSprite, @_isLooping, offsets) ->
    super(offsets)

  start: (args...) ->
    @_curTime = 0
    super(args...)

  newOffset: (deltaTimeMs) ->
    @_curTime += deltaTimeMs
    newOffset = Math.floor(@_curTime / @_msBetweenSprite)
    if newOffset >= @_offsets.length
      unless @_isLooping
        @pause()
        return 0

    newOffset % @_offsets.length


class PositionAnimation extends Animation

  constructor: (@_isVertical, offsets) ->
    super(offsets)

  start: ->
    super
    @_startPosition = @_sprite.position.clone()

  newOffset: (deltaTimeMs) ->
    position = @_sprite.position
    if @_isVertical
      delta = position.y - @_startPosition.y
    else
      # TODO: This should only compute in the current axis so depth changes don't matter
      delta = position.x - @_startPosition.x
      if delta is 0
        delta = position.z - @_startPosition.z

    newOffset = Math.round(delta * @_offsets.length)

    newOffset.mod(@_offsets.length) # Can be negative



module.exports = {SpriteAnimationHandler, StillAnimation, TimeAnimation, PositionAnimation}
