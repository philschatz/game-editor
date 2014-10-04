MovementHelper = require './movement-helper'

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
        return PlayerManager.isGrounded() and MovementHelper.isWalking() and not MovementHelper.isJumping() and not PlayerManager.pushingInstance

  begin: ->
  end: ->
  act: (elapsedTime, ActionTypes, game) ->
    # Transform input to physics impulses in a helper class
    # MovementHelper.update(elapsedTime)

    return ActionTypes.RUNNING if MovementHelper.isRunning()
    @

  # Extras that are not implemented
  isAnimationLooping: -> false
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
