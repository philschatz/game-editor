MovementHelper = require './movement-helper'
GameManager = require './game-manager'

{OrientedPositionAnimation} = require '../../sprite-animation'

ANIMATION = new OrientedPositionAnimation(true, [[0, 3], [1, 3], [2, 3]])

module.exports = new class Climbing
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.IDLE,    \
            ActionTypes.JUMPING, \
            ActionTypes.WALKING, \
            ActionTypes.RUNNING
        return (window.game.buttons.forward or window.game.buttons.backward) and MovementHelper.isClimbing()

  begin: (game, sprite) ->
    # Center the player
    sprite.position.x = Math.floor(sprite.position.x) + .5
    # sprite.position.y = Math.floor(sprite.position.y) + .5
    sprite.position.z = Math.floor(sprite.position.z) + .5

    ANIMATION.start(sprite)

  end: -> ANIMATION.stop()

  act: (elapsedTime, ActionTypes, game) -> @

  # Extras that are not implemented
  isAnimationLooping: -> false
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
