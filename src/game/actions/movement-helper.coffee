GameManager = require './game-manager'

module.exports = new class MovementHelper
  isWalking: ->
    state = window.game.controls.state
    state.left or state.right

  isRunning: ->
    false

  isJumping: ->
    # window.game.controlling.atRestY() is 1
    state = window.game.controls.state
    state.jump or window.game.controlling.velocity.y > 0

  isClimbing: ->
    state = window.game.controls.state
    playerBase = window.game.controlling.aabb().base
    if state.forward
      {wallDepth, wallType, collideStart, collideEnd} = GameManager.getFlattenedInfo(playerBase)
      return wallType in ['ladder']
    else if state.backward
      playerBase[1] -= 1
      {wallDepth, wallType, collideStart, collideEnd} = GameManager.getFlattenedInfo(playerBase)
      return wallType in ['ladder']
