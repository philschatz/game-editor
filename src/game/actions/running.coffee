MovementHelper = require './movement-helper'

module.exports = new class Running
  isAllowed: (PlayerManager, ActionTypes)->
    switch PlayerManager.currentAction()
      when @ then true
      when ActionTypes.WALKING
        return PlayerManager.isGrounded() and MovementHelper.isRunning() and not PlayerManager.pushingInstance

  begin: ->
  end: ->
  act: (elapsedTime, ActionTypes) ->
    @
