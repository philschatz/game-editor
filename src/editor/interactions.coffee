THREE = require '../three'
ColorManager = require './color-manager'
MainCamera = require '../main-camera'

Input = require './input-manager'
SceneManager = require './scene-manager'

module.exports = new class Interactions

      removeRectangle: ->
        SceneManager.scene.remove(@rectangle) if @rectangle

      interact: ->
        return  unless MainCamera.raycaster
        if @_objectHovered
          @_objectHovered.material.opacity = 1
          @_objectHovered = null
        intersect = MainCamera.getIntersecting()
        if intersect
          normal = intersect.face.normal.clone()
          # normal.applyMatrix4(intersect.object.matrixRotationWorld)
          matrixRotationWorld = new THREE.Matrix4()
          matrixRotationWorld.extractRotation( intersect.object.matrixWorld )
          normal.applyMatrix4(matrixRotationWorld)

          position = new THREE.Vector3().addVectors(intersect.object.position, normal)
          updateBrush = ->
            SceneManager.brush.position.x = Math.floor(position.x / (16/16)) * (16/16) + (16/16)/2
            SceneManager.brush.position.y = Math.floor(position.y / (16/16)) * (16/16) + (16/16)/2
            SceneManager.brush.position.z = Math.floor(position.z / (16/16)) * (16/16) + (16/16)/2
            return

          if Input.isShiftDown
            if intersect.object isnt SceneManager.plane
              @_objectHovered = intersect.object
              @_objectHovered.material.opacity = 0.5
              SceneManager.brush.position.y = 2000
              return
          else if Input.startPosition and Input.isMouseDown # or Input.isMouseDown and not Input.isMouseRotating

            @removeRectangle()

            # Draw a rectangle
            x1 = Math.floor(Input.startPosition.x / (16/16)) * (16/16) + (16/16)/2
            y1 = Math.floor(Input.startPosition.y / (16/16)) * (16/16) + (16/16)/2
            z1 = Math.floor(Input.startPosition.z / (16/16)) * (16/16) + (16/16)/2
            x2 = Math.floor(position.x / (16/16)) * (16/16) + (16/16)/2
            y2 = Math.floor(position.y / (16/16)) * (16/16) + (16/16)/2
            z2 = Math.floor(position.z / (16/16)) * (16/16) + (16/16)/2

            Input.endPosition = {x:x2, y:y2, z:z2}

            bbox = (x1, x2) ->
              if x1 <= x2
                [x1 - (16/16)/2, x2 + (16/16)/2]
              else
                [x1 + (16/16)/2, x2 - (16/16)/2]

            [x1, x2] = bbox(x1, x2)
            [y1, y2] = bbox(y1, y2)
            [z1, z2] = bbox(z1, z2)


            width   = Math.abs(x2 - x1)
            height  = Math.abs(y2 - y1)
            depth   = Math.abs(z2 - z1)
            cube = new THREE.BoxGeometry( width, height, depth )


            brushMaterials = [
              new THREE.MeshBasicMaterial(
                vertexColors: THREE.VertexColors
                opacity: 0.5
                transparent: true
              )
              new THREE.MeshBasicMaterial(
                color: 0x000000
                wireframe: true
              )
            ]
            brushMaterials[0].color.setRGB(0, 0, 0) # black
            @rectangle = THREE.SceneUtils.createMultiMaterialObject(cube, brushMaterials)

            @rectangle.position.set((x2-x1)/2+x1, (y2-y1)/2+y1, (z2-z1)/2+z1)
            SceneManager.scene.add(@rectangle)

          else
            updateBrush()
            return
        SceneManager.brush.position.y = 2000
        return
