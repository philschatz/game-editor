

module.exports = (THREE) ->
  isShiftDown: false
  isCtrlDown: false
  isMouseRotating: false
  isMouseDown: false
  isAltDown: false

  onMouseDownPosition: new THREE.Vector2()
  onMouseDownPhi: 60
  onMouseDownTheta: 45
