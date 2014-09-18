CameraManager = require './camera-manager'

window.mainCamera = module.exports = new class MainCamera extends CameraManager
  _theta: 90
  _phi: 60
