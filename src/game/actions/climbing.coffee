MovementHelper = require './movement-helper'

module.exports = new class Climbing
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.IDLE,    \
            ActionTypes.JUMPING, \
            ActionTypes.WALKING, \
            ActionTypes.RUNNING
        return window.game.buttons.forward and MovementHelper.isClimbing()

  begin: ->
  end: ->
  act: (elapsedTime, ActionTypes, game) ->

  # Extras that are not implemented
  isAnimationLooping: -> false
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
