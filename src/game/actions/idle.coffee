MovementHelper = require './movement-helper'

module.exports = new class Idle
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.JUMPING, \
            ActionTypes.WALKING, \
            ActionTypes.RUNNING
        return PlayerManager.isGrounded() and not MovementHelper.isWalking() and not PlayerManager.pushingInstance

  begin: ->
  end: ->
  act: (elapsedTime, ActionTypes, game) ->

  # Extras that are not implemented
  isAnimationLooping: -> false
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
