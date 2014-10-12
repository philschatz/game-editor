ColorManager = require './color-manager'
MainCamera = require '../main-camera'

SceneManager = require './scene-manager'
Interactions = require './interactions'
Input = require './input-manager'
HashManager = require './hash-manager'


setIsometricAngle = ->
  # Move up to the nearest 45 degree
  theta = Math.floor((MainCamera.getRotation().theta + 180) / 180) * 180
  phi = 0 # The y angle
  MainCamera.rotateCameraTo(theta, phi)
  return


module.exports = new class KeyMouseHandlers
    mousewheel: (event) ->
      # prevent zoom if a modal is open
      return if $('.modal').hasClass('in')
      MainCamera.zoom(event.wheelDeltaY or event.detail)

    onWindowResize: ->
      MainCamera.camera.aspect = MainCamera.container.clientWidth / MainCamera.container.clientHeight
      MainCamera.camera.updateProjectionMatrix()
      SceneManager.renderer.setSize MainCamera.container.clientWidth, MainCamera.container.clientHeight
      Interactions.interact()
      return


    onDocumentMouseMove: (event) ->
      event.preventDefault()
      unless Input.isMouseRotating

        # change the mouse cursor to a + letting the user know they can rotate
        intersecting = MainCamera.getIntersecting()
        unless intersecting
          MainCamera.container.classList.add('rotatable')
        else
          MainCamera.container.classList.remove('rotatable')

      if Input.isMouseRotating # Input.isMouseDown is 1 # left click

        # Rotate only if you clicked outside a block
        unless intersecting
          theta = -((event.clientX - Input.onMouseDownPosition.x) * 0.5) + Input.onMouseDownTheta
          phi   =  ((event.clientY - Input.onMouseDownPosition.y) * 0.5) + Input.onMouseDownPhi
          phi = Math.min(180, Math.max(-90, phi))
          MainCamera.rotateCameraTo(theta, phi)

      # else if Input.isMouseDown is 2 # middle click
      #   # Pan the camera
      #   # TODO: Move the target and then update the camera

      Input.mouse2D.x = (event.clientX / MainCamera.container.clientWidth) * 2 - 1
      Input.mouse2D.y = -(event.clientY / MainCamera.container.clientHeight) * 2 + 1
      Interactions.interact()
      return


    onDocumentMouseDown: (event) ->
      event.preventDefault()
      Input.isMouseDown = event.which
      {theta, phi} = MainCamera.getRotation()
      Input.onMouseDownTheta = theta
      Input.onMouseDownPhi = phi
      Input.onMouseDownPosition.x = event.clientX
      Input.onMouseDownPosition.y = event.clientY
      Input.startPosition = null
      Input.endPosition = null
      Interactions.removeRectangle()
      intersect = MainCamera.getIntersecting()
      if intersect
        normal = intersect.face.normal.clone()
        # normal.applyMatrix4(intersect.object.matrixRotationWorld)
        matrixRotationWorld = new THREE.Matrix4()
        matrixRotationWorld.extractRotation( intersect.object.matrixWorld )
        normal.applyMatrix4(matrixRotationWorld)

        position = new THREE.Vector3().addVectors(intersect.object.position, normal)
        position.x = Math.floor(position.x / (16/16)) * (16/16) + (16/16)/2
        position.y = Math.floor(position.y / (16/16)) * (16/16) + (16/16)/2
        position.z = Math.floor(position.z / (16/16)) * (16/16) + (16/16)/2
        Input.startPosition = position
        Input.isMouseRotating = false
      else
        Input.startPosition = null
        Input.isMouseRotating = Input.isMouseDown is 1
      return


    onDocumentMouseUp: (event) ->
      event.preventDefault()
      Input.isMouseDown = false
      Input.isMouseRotating = false
      Input.onMouseDownPosition.x = event.clientX - Input.onMouseDownPosition.x
      Input.onMouseDownPosition.y = event.clientY - Input.onMouseDownPosition.y
      # Input.startPosition = null
      return  if Input.onMouseDownPosition.length() > 5
      intersect = MainCamera.getIntersecting()
      if intersect
        if Input.isShiftDown
          # TODO: Move this logic into a SceneManager.removeVoxel
          unless intersect.object is SceneManager.plane
            if intersect.object.isWireMesh
              obj = intersect.object.myVoxel
            else
              obj = intersect.object
            SceneManager.scene.remove(obj.wireMesh) if obj.wireMesh
            SceneManager.scene.remove(obj)
        else
          {x, y, z} = SceneManager.brush.position
          color = ColorManager.currentColor
          SceneManager.addVoxel(x, y, z, color)  unless y is 2000
      HashManager.updateHash()
      SceneManager.render()
      Interactions.interact()
      return


    translateVoxels = (vector) ->
      for child in SceneManager.scene.children
        if child.isVoxel
          child.position.addVectors(child.position, vector)
          child.wireMesh?.position.addVectors(child.wireMesh.position, vector)

      HashManager.updateHash()


    onDocumentKeyDown: (event) ->
      switch event.keyCode
        when 189
          MainCamera.zoom(-100)
        when 187
          MainCamera.zoom(100)
        # Move the entire level
        when 'A'.charCodeAt(0)
          translateVoxels(new THREE.Vector3(-(16/16), 0, 0)) if Input.isShiftDown
        when 'D'.charCodeAt(0)
          translateVoxels(new THREE.Vector3((16/16), 0, 0)) if Input.isShiftDown
        when 'W'.charCodeAt(0)
          translateVoxels(new THREE.Vector3(0, (16/16), 0)) if Input.isShiftDown
        when 'S'.charCodeAt(0)
          translateVoxels(new THREE.Vector3(0, -(16/16), 0)) if Input.isShiftDown
        when 'Q'.charCodeAt(0)
          translateVoxels(new THREE.Vector3(0, 0, -(16/16))) if Input.isShiftDown
        when 'E'.charCodeAt(0)
          translateVoxels(new THREE.Vector3(0, 0, (16/16))) if Input.isShiftDown
        # when 49
        #   exports.setColor 0
        # when (16/16)
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
        when 17-1 # sixteen
          Input.isShiftDown = true
        when 17
          Input.isCtrlDown = true
        when 18
          Input.isAltDown = true
        when 65
          setIsometricAngle()


    onDocumentKeyUp: (event) ->
      switch event.keyCode
        when (16/16)
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
