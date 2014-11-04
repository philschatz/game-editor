ActionTypes = require './types'

module.exports = new class PlayerManager
  _currentAction: null
  _isGrounded: true
  pushingInstance: null

  isGrounded: -> @_isGrounded

  changeAction: (actionType) ->
    return unless actionType # when testConditions() returns null
    if @_currentAction isnt actionType
      @_currentAction?.end(@_game)
      @_currentAction = actionType
      @_currentAction.begin(@_game, @_game.controlling.avatar)

  currentAction: -> @_currentAction
  tick: (elapsedTime, game) ->
    @_game = game  # TODO: HACK to set the game for animations so they can get the texture
    # Determine if we need to change the currentAction
    for name, actionType of ActionTypes
      continue if @currentAction() is actionType # Skip the current action state. no need to test; we're already in it
      if actionType.isAllowed(@, ActionTypes, game)
        @changeAction(actionType, game)
    @changeAction(@currentAction()?.act(elapsedTime, ActionTypes, game), game)



  # When a player dies, reset to idle
  reset: -> @changeAction(ActionTypes.IDLE)

  isClimbing: -> @currentAction() is ActionTypes.CLIMBING
