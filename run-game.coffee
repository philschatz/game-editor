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

LevelLoader.load('/data/level-empty.json')
.then (level) ->

  # These steps are *only* to generate the exported geometries
  SceneManager.setLevel(level)
  # VoxelFactory.load(level) Needs to be uncommented if SceneManager.setLevel is not used
  exportGeometry(SceneManager)
  # # Or, just remove everything except the skeleton
  # items = scene.children[..]
  # for item in items
  #   scene.remove(item)

  scene.add(new THREE.AmbientLight(0x606060))

  window.CURRENT_LEVEL = level
  GAME(SceneManager)

  raf(window).on 'data', (args...) -> SceneManager.render(args...)


window.startEditor = -> console.warn 'HACK for running the game. making this a noop'
