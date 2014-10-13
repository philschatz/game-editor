# Stupid negative modulo in JS
Number::mod = (n) ->
  ((this % n) + n) % n

Stats = require './js/stats'
requestAnimationFrame = require 'raf'

# require './test-collision'
# require './run-game'
require './run-editor'


stats = new Stats()
stats.domElement.style.position = 'absolute'
stats.domElement.style.bottom = '0'
document.body.appendChild(stats.domElement)

requestAnimationFrame(window).on 'data', -> stats.update()
