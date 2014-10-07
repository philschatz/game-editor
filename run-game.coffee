
THREE = window.THREE
Input = require('./src/input-manager')(THREE)
SceneManager = require('./src/scene-manager')(THREE, Input)
GAME = require './src/game'

container = document.getElementById("editor-area")
SceneManager.prepare(container)
SceneManager.init(container)
container.appendChild(SceneManager.renderer.domElement)

GAME(SceneManager)
return
