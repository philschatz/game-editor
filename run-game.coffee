THREE = require './src/three'
raf = require("raf")
exportGeometry = require './export-geometry'
InputManager = require './src/editor/input-manager'
SceneManager = require './src/editor/scene-manager'
VoxelFactory = require './src/voxels/voxel-factory'
LevelLoader = require './src/loaders/level'
GAME = require './src/game'

container = document.getElementById("editor-area")
SceneManager.prepare(container)
SceneManager.init(container)
container.appendChild(SceneManager.renderer.domElement)

LevelLoader.load('/data/level-lighthouse.json')
.then (level) ->

  VoxelFactory.load(level)

  # These steps are *only* to generate the exported geometries
  level.map.forEach (x, y, z, color, orientation) ->
    x += .5
    y += .5
    z += .5
    SceneManager.addVoxel(x, y, z, color)

  exportGeometry(SceneManager)
  # # Or, just remove everything except the skeleton
  # items = scene.children[..]
  # for item in items
  #   scene.remove(item)

  scene.add(new THREE.AmbientLight(0x606060))

  window.CURRENT_LEVEL = level
  GAME(SceneManager)

  raf(window).on 'data', -> SceneManager.render()


window.startEditor = -> console.warn 'HACK for running the game. making this a noop'
