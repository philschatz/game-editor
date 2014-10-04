# Action classes contain the following:
# isAllowed: (PlayerManager, ActionTypes) -> boolean
# begin: () ->
# end: () ->
# act: (elapsed) -> boolean

module.exports = ActionTypes = {
  IDLE          : require './idle'
  WALKING       : require './walking'
  RUNNING       : require './running'
  JUMPING       : require './jumping'
  CLIMBING      : require './climbing'
  # TRAVERSING    : 0
  # ROTATING      : 0
  # SLIDING       : 0
  # TEETERING     : 2
  # GRABBING      : 3
  # PUSHING       : 4
  # LOOKING_AROUND: 5
}


### State Diagram:

Idle -> LookingAround, Walking, Jumping, Pushing, Climbing, Rotating, Floating (if Falling is not possible)
LookingAround -> ...

Walking -> Idle, Jumping, Pushing, Running, Climbing
Running -> Idle, Jumping, Pushing, Climbing
Jumping -> Idle, Walking, Climbing

Climbing -> Idle, Traversing, Jumping
Traversing -> Idle, Climbing, Jumping
Rotating -> Idle

Floating -> Jumping, Climbing
###


### Disallowed keys for various states

Idle -
LookingAround -
Walking - A,D
Running - A,D
Jumping - A,D
Climbing -
Traversing - A,D
Rotating - forward,backward,left,right,jump
Floating - forward,backward

Note: A level (game) can also set this list and they get anded together

###
