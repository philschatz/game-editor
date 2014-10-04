MovementHelper = require './movement-helper'

module.exports = new class Jumping
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.IDLE, \
            ActionTypes.SLIDING, \
            ActionTypes.CLIMBING, \
            ActionTypes.TEETERING, \
            ActionTypes.GRABBING, \
            ActionTypes.PUSHING, \
            ActionTypes.LOOKING_AROUND, \
            ActionTypes.WALKING, \
            ActionTypes.RUNNING
        return MovementHelper.isJumping()

  begin: ->
  end: ->
  act: ->
