# Stupid negative modulo in JS
Number::mod = (n) ->
  ((this % n) + n) % n

# require './test-collision'
# require './run-game'
require './run-editor'
