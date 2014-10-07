
THREE = window.THREE
raf = require("raf")
exportGeometry = require './export-geometry'
Input = require('./src/input-manager')(THREE)
SceneManager = require('./src/scene-manager')(THREE, Input)
HashManager = require('./src/hash-manager')(SceneManager)
GAME = require './src/game'

container = document.getElementById("editor-area")
SceneManager.prepare(container)
SceneManager.init(container)
container.appendChild(SceneManager.renderer.domElement)


HashManager.buildFromHash()
exportGeometry(SceneManager)



scene.add(new THREE.AmbientLight(0x606060))


GAME(SceneManager)


raf(window).on 'data', -> SceneManager.render()
