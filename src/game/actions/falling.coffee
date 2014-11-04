MovementHelper = require './movement-helper'

{StillAnimation} = require '../../sprite-animation'

ANIMATION = new StillAnimation([0, 2])

module.exports = new class Falling
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.JUMPING, \
            ActionTypes.WALKING
        return MovementHelper.isFalling()

  begin: (game, sprite) -> ANIMATION.start(sprite)
  end: -> ANIMATION.stop()
  act: ->
    MovementHelper.flipSpriteLeftRight()
    @
