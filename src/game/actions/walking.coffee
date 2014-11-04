MovementHelper = require './movement-helper'
THREE = require '../../three'
{PositionAnimation} = require '../../sprite-animation'


ANIMATION = new PositionAnimation false, [
  [0, 1]
  [1, 1]
]

module.exports = new class Walking
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.IDLE, \
            ActionTypes.SLIDING, \
            # ActionTypes.CLIMBING, \
            ActionTypes.TEETERING, \
            ActionTypes.GRABBING, \
            ActionTypes.PUSHING, \
            ActionTypes.LOOKING_AROUND, \
            # ActionTypes.WALKING, \
            ActionTypes.RUNNING
            # ActionTypes.JUMPING, \
            # ActionTypes.FALLING
        return PlayerManager.isGrounded() and MovementHelper.isWalking() and not PlayerManager.pushingInstance

  begin: (game, sprite) -> ANIMATION.start(sprite)

  end: -> ANIMATION.stop()

  act: (elapsedTime, ActionTypes, game) ->
    # Transform input to physics impulses in a helper class
    # MovementHelper.update(elapsedTime)

    MovementHelper.flipSpriteLeftRight()
    return ActionTypes.RUNNING if MovementHelper.isRunning()
    @

  # Extras that are not implemented
  isAnimationLooping: -> true
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
