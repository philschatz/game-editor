# Stupid negative modulo in JS
Number::mod = (n) ->
  ((this % n) + n) % n

Stats = require './js/stats'
RendererStats = require './js/stats-renderer'
SceneManager = require './src/editor/scene-manager'

requestAnimationFrame = require 'raf'

# require './test-collision'
# require './run-game'
require './run-editor'


stats = new Stats()
stats.domElement.style.position = 'absolute'
stats.domElement.style.bottom = '0'
document.body.appendChild(stats.domElement)

rstats = new RendererStats()
rstats.domElement.style.position = 'absolute'
rstats.domElement.style.right = '0'
rstats.domElement.style.top = '0'
document.body.appendChild(rstats.domElement)

requestAnimationFrame(window).on 'data', ->
  stats.update()
  rstats.update(SceneManager.renderer) if SceneManager.renderer
