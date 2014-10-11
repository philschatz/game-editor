ActionTypes = require './types'

module.exports = new class PlayerManager
  _currentAction: null
  _isGrounded: true
  pushingInstance: null

  isGrounded: -> @_isGrounded

  changeAction: (actionType) ->
    return unless actionType # when testConditions() returns null
    if @_currentAction isnt actionType
      @_currentAction?.end()
      @_currentAction = actionType
      @_currentAction.begin()

  currentAction: -> @_currentAction
  tick: (elapsedTime, game) ->
    # Determine if we need to change the currentAction
    for name, actionType of ActionTypes
      continue if @currentAction() is actionType # Skip the current action state. no need to test; we're already in it
      if actionType.isAllowed(@, ActionTypes, game)
        @changeAction(actionType)
    @changeAction(@currentAction()?.act(elapsedTime, ActionTypes, game))

  # When a player dies, reset to idle
  reset: -> @changeAction(ActionTypes.IDLE)

  isClimbing: -> @currentAction() is ActionTypes.CLIMBING
