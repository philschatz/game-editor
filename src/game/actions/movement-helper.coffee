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
    cameraType = window.game.controlling.rotation.y / Math.PI * 2

    if cameraType.mod(2) is 0 #x
      cameraAxis = 0
      cameraPerpendicAxis = 2
    else #z
      cameraAxis = 2
      cameraPerpendicAxis = 0
    y = Math.floor(game.controlling.aabb().base[1])

    state.forward and window.game.sparseCollisionMap[cameraType]['' + Math.floor(window.game.controlling.aabb().base[cameraAxis]) + '|' + y]
