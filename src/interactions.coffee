ColorManager = require './color-manager'
MainCamera = require './main-camera'

module.exports = (Input, SceneManager) ->
  new class Interactions

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
          matrixRotationWorld = new (SceneManager.THREE().Matrix4)()
          matrixRotationWorld.extractRotation( intersect.object.matrixWorld )
          normal.applyMatrix4(matrixRotationWorld)

          position = new (SceneManager.THREE().Vector3)().addVectors(intersect.point, normal)
          updateBrush = ->
            SceneManager.brush.position.x = Math.floor(position.x / 50) * 50 + 25
            SceneManager.brush.position.y = Math.floor(position.y / 50) * 50 + 25
            SceneManager.brush.position.z = Math.floor(position.z / 50) * 50 + 25
            return

          if Input.isAltDown
            newCube = [
              Math.floor(position.x / 50)
              Math.floor(position.y / 50)
              Math.floor(position.z / 50)
            ]
            SceneManager.brush.currentCube = newCube  unless SceneManager.brush.currentCube
            if SceneManager.brush.currentCube.join('') isnt newCube.join('')
              if Input.isShiftDown
                if intersect.object isnt SceneManager.plane
                  SceneManager.scene.remove intersect.object.wireMesh
                  SceneManager.scene.remove intersect.object
              else
                SceneManager.addVoxel SceneManager.brush.position.x, SceneManager.brush.position.y, SceneManager.brush.position.z, ColorManager.colors[ColorManager.currentColor]  unless SceneManager.brush.position.y is 2000
            updateBrush()
            HashManager.updateHash()
            SceneManager.brush.currentCube = newCube
            return
          else if Input.isShiftDown
            if intersect.object isnt SceneManager.plane
              @_objectHovered = intersect.object
              @_objectHovered.material.opacity = 0.5
              SceneManager.brush.position.y = 2000
              return
          else if Input.startPosition and Input.isMouseDown # or Input.isMouseDown and not Input.isMouseRotating

            @removeRectangle()
            THREE = SceneManager.THREE()

            # Draw a rectangle
            x1 = Math.floor(Input.startPosition.x / 50) * 50 + 25
            y1 = Math.floor(Input.startPosition.y / 50) * 50 + 25
            z1 = Math.floor(Input.startPosition.z / 50) * 50 + 25
            x2 = Math.floor(position.x / 50) * 50 + 25
            y2 = Math.floor(position.y / 50) * 50 + 25
            z2 = Math.floor(position.z / 50) * 50 + 25

            Input.endPosition = {x:x2, y:y2, z:z2}

            bbox = (x1, x2) ->
              if x1 <= x2
                [x1 - 25, x2 + 25]
              else
                [x1 + 25, x2 - 25]

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

            @rectangle.position = {x:(x2-x1)/2+x1, y:(y2-y1)/2+y1, z:(z2-z1)/2+z1}
            SceneManager.scene.add(@rectangle)

          else
            updateBrush()
            return
        SceneManager.brush.position.y = 2000
        return
