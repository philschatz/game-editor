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
      if actionType.isAllowed(@, ActionTypes, game)
        @changeAction(actionType)
    @changeAction(@currentAction()?.act(elapsedTime, ActionTypes, game))
