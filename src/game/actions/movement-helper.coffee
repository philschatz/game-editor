GameManager = require './game-manager'

module.exports = new class MovementHelper

  getControlState: ->
    window.game.controls.state

  playerFlattenedBlock: ->
    # Returns {wallDepth, wallType, collideStart, collideEnd}
    playerBase = window.game.controlling.aabb().base
    return GameManager.getFlattenedInfo(playerBase)

  flipSpriteLeftRight: (opts={isReversed:false, force:0}) ->
    {isReversed, force} = opts
    # Rotate the sprite depending on if the left or right key were pressed last
    state = @getControlState()
    if state.left or (state.right and isReversed) or force is -1
      window.game.controlling.avatar.children[0].rotation.y = Math.PI
    else if state.right or (state.left and isReversed) or force is 1
      window.game.controlling.avatar.children[0].rotation.y = 0


  isWalking: ->
    state = window.game.controls.state
    state.left or state.right

  isRunning: ->
    false

  isJumping: ->
    # window.game.controlling.atRestY() is 1
    state = window.game.controls.state
    state.jump # or window.game.controlling.velocity.y > 0

  isFalling: ->
    # window.game.controlling.atRestY() is 1
    window.game.controlling.velocity.y < -0.014152 # Whatever gravity is...

  isClimbing: ->
    state = @getControlState()
    if state.forward or state.backward
      {ladderDepth} = @playerFlattenedBlock()
      return ladderDepth?
