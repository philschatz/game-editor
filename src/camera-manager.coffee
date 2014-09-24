module.exports = class MainCamera
  radius: 1600
  _theta: 0
  _phi: 0

  _target: null

  init: (@_scene, @camera, @container, @_target) ->

  getRotation: ->
    {theta: @_theta, phi: @_phi}


  zoom: (delta) ->
    origin =
      x: 0
      y: 0
      z: 0

    distance = @camera.position.distanceTo(origin)
    tooFar = distance > 6000
    tooClose = Math.abs(@camera.top) < 200
    return  if delta > 0 and tooFar
    return  if delta < 0 and tooClose
    @radius = distance # for mouse drag calculations to be correct
    aspect = @container.clientWidth / @container.clientHeight
    @camera.top += delta / 2
    @camera.bottom -= delta / 2
    @camera.left -= delta * aspect / 2
    @camera.right += delta * aspect / 2

    # @camera.updateMatrix();
    @camera.updateProjectionMatrix()
    @camera.translateZ(delta)
    return

  rotateCameraTo: (theta, phi) ->
    theta ?= @_theta
    phi   ?= @_phi
    @_theta = theta
    @_phi   = phi
    @updateCamera()

  updateCamera: ->
    @camera.position.x = @_target.x + @radius * Math.sin(@_theta * Math.PI / 360) * Math.cos(@_phi * Math.PI / 360)
    @camera.position.y = @_target.y + @radius * Math.sin(@_phi   * Math.PI / 360)
    @camera.position.z = @_target.z + @radius * Math.cos(@_theta * Math.PI / 360) * Math.cos(@_phi * Math.PI / 360)
    @camera.updateMatrix()

  setRaycaster: (@raycaster) ->

  getIntersecting: ->
    intersectable = []
    @_scene.children.map (c) ->
      if c.isVoxel or c.isPlane
        intersectable.push c
      else if c.isWireMesh
        intersectable.push c
      return

    if @raycaster
      intersections = @raycaster.intersectObjects(intersectable)
      if intersections.length > 0
        intersect = (if intersections[0].object.isBrush then intersections[1] else intersections[0])
        intersect
