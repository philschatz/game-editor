ColorManager = require './color-manager'
CameraManager = require './camera-manager'

module.exports = (SceneManager, Interactions, Input, HashManager) ->


  setIsometricAngle = ->
    # Move up to the nearest 45 degree
    theta = Math.floor((CameraManager.getRotation().theta + 180) / 180) * 180
    phi = 0 # The y angle
    CameraManager.rotateCameraTo(theta, phi)
    return

  return new class KeyMouseHandlers
    mousewheel: (event) ->
      # prevent zoom if a modal is open
      return if $('.modal').hasClass('in')
      CameraManager.zoom(event.wheelDeltaY or event.detail)

    onWindowResize: ->
      CameraManager.camera.aspect = CameraManager.container.clientWidth / CameraManager.container.clientHeight
      CameraManager.camera.updateProjectionMatrix()
      SceneManager.renderer.setSize CameraManager.container.clientWidth, CameraManager.container.clientHeight
      Interactions.interact()
      return


    onDocumentMouseMove: (event) ->
      event.preventDefault()
      unless Input.isMouseRotating

        # change the mouse cursor to a + letting the user know they can rotate
        intersecting = CameraManager.getIntersecting()
        unless intersecting
          CameraManager.container.classList.add 'rotatable'
        else
          CameraManager.container.classList.remove 'rotatable'
      if Input.isMouseDown is 1 # left click

        # Rotate only if you clicked outside a block
        unless intersecting
          theta = -((event.clientX - Input.onMouseDownPosition.x) * 0.5) + Input.onMouseDownTheta
          phi   =  ((event.clientY - Input.onMouseDownPosition.y) * 0.5) + Input.onMouseDownPhi
          phi = Math.min(180, Math.max(-90, phi))
          CameraManager.rotateCameraTo(theta, phi)

      # else if Input.isMouseDown is 2 # middle click
      #   # Pan the camera
      #   # TODO: Move the target and then update the camera

      Input.mouse2D.x = (event.clientX / CameraManager.container.clientWidth) * 2 - 1
      Input.mouse2D.y = -(event.clientY / CameraManager.container.clientHeight) * 2 + 1
      Interactions.interact()
      return


    onDocumentMouseDown: (event) ->
      event.preventDefault()
      Input.isMouseDown = event.which
      Input.onMouseDownTheta = CameraManager.getRotation().theta
      Input.onMouseDownPhi = CameraManager.getRotation().phi
      Input.onMouseDownPosition.x = event.clientX
      Input.onMouseDownPosition.y = event.clientY
      Input.isMouseRotating = not CameraManager.getIntersecting()
      return


    onDocumentMouseUp: (event) ->
      event.preventDefault()
      Input.isMouseDown = false
      Input.isMouseRotating = false
      Input.onMouseDownPosition.x = event.clientX - Input.onMouseDownPosition.x
      Input.onMouseDownPosition.y = event.clientY - Input.onMouseDownPosition.y
      return  if Input.onMouseDownPosition.length() > 5
      intersect = CameraManager.getIntersecting()
      if intersect
        if Input.isShiftDown
          unless intersect.object is SceneManager.plane
            SceneManager.scene.remove intersect.object.wireMesh
            SceneManager.scene.remove intersect.object
        else
          SceneManager.addVoxel SceneManager.brush.position.x, SceneManager.brush.position.y, SceneManager.brush.position.z, ColorManager.colors[ColorManager.currentColor]  unless SceneManager.brush.position.y is 2000
      HashManager.updateHash()
      SceneManager.render()
      Interactions.interact()
      return



    onDocumentKeyDown: (event) ->
      switch event.keyCode
        when 189
          CameraManager.zoom(100)
        when 187
          CameraManager.zoom(-100)
        # when 49
        #   exports.setColor 0
        # when 50
        #   exports.setColor 1
        # when 51
        #   exports.setColor 2
        # when 52
        #   exports.setColor 3
        # when 53
        #   exports.setColor 4
        # when 54
        #   exports.setColor 5
        # when 55
        #   exports.setColor 6
        # when 56
        #   exports.setColor 7
        # when 57
        #   exports.setColor 8
        # when 48
        #   exports.setColor 9
        when 16
          Input.isShiftDown = true
        when 17
          Input.isCtrlDown = true
        when 18
          Input.isAltDown = true
        when 65
          setIsometricAngle()


    onDocumentKeyUp: (event) ->
      switch event.keyCode
        when 16
          Input.isShiftDown = false
        when 17
          Input.isCtrlDown = false
        when 18
          Input.isAltDown = false



    attachEvents: ->
      SceneManager.renderer.domElement.addEventListener 'mousemove', @onDocumentMouseMove, false
      SceneManager.renderer.domElement.addEventListener 'mousedown', @onDocumentMouseDown, false
      SceneManager.renderer.domElement.addEventListener 'mouseup', @onDocumentMouseUp, false
      document.addEventListener 'keydown', @onDocumentKeyDown, false
      document.addEventListener 'keyup', @onDocumentKeyUp, false
      window.addEventListener 'DOMMouseScroll', @mousewheel, false
      window.addEventListener 'mousewheel', @mousewheel, false
      window.addEventListener 'resize', @onWindowResize, false
