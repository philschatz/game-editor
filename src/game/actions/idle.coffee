MovementHelper = require './movement-helper'

THREE = require '../../three'
{TimeAnimation} = require '../../sprite-animation'

ANIMATION = new TimeAnimation 100, true, [
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [1, 0]
  [2, 0]
  [1, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [0, 0]
  [1, 0]
  [2, 0]
  [1, 0]
  [4, 0]
  [4, 0]
  [5, 0]
  [5, 0]
  [6, 0]
  [6, 0]
  [7, 0]
  [7, 0]
  [1, 0]
  [0, 0]
]

module.exports = new class Idle
  isAllowed: (PlayerManager, ActionTypes, game)->
    switch PlayerManager.currentAction()
      when @ then true
      when  null, \
            ActionTypes.JUMPING, \
            ActionTypes.WALKING, \
            ActionTypes.RUNNING
        return PlayerManager.isGrounded() and not MovementHelper.isWalking() and not PlayerManager.pushingInstance

  begin: (game, sprite) -> ANIMATION.start(sprite)

  end: -> ANIMATION.stop()

  act: (elapsedTime, ActionTypes, game) ->

  # Extras that are not implemented
  isAnimationLooping: -> false
  disallowsRespawns: -> false # Maybe true for jumping?
  preventsRotations: -> true # Can't rotate while walking
