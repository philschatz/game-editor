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
            ActionTypes.RUNNING, \
            ActionTypes.JUMPING
        return PlayerManager.isGrounded() and MovementHelper.isWalking() and not MovementHelper.isJumping() and not PlayerManager.pushingInstance

  begin: (game, sprite) ->
    # Rotate the sprite depending on if the left or right key were pressed last
    if game.controls.state.left
      game.controlling.avatar.children[0].rotation.y = Math.PI
    else
      game.controlling.avatar.children[0].rotation.y = 0
    ANIMATION.start(sprite)

  end: -> ANIMATION.stop()

  act: (elapsedTime, ActionTypes, game) ->
    # Transform input to physics impulses in a helper class
    # MovementHelper.update(elapsedTime)

    return ActionTypes.RUNNING if MovementHelper.isRunning()
    @

  # Extras that are not implemented
  isAnimationLooping: -> true
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
