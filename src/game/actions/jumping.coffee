MovementHelper = require './movement-helper'

{StillAnimation} = require '../../sprite-animation'

ANIMATION = new StillAnimation([0, 2])

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

  begin: (game, sprite) -> ANIMATION.start(sprite)
  end: -> ANIMATION.stop()
  act: ->
    MovementHelper.flipSpriteLeftRight()
    @
