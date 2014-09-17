ColorManager = require './color-manager'

module.exports = (Input, SceneManager) ->
  new class Interactions

      interact: ->
        return  if typeof SceneManager.raycaster is 'undefined'
        if @_objectHovered
          @_objectHovered.material.opacity = 1
          @_objectHovered = null
        intersect = SceneManager.getIntersecting()
        if intersect
          updateBrush = ->
            SceneManager.brush.position.x = Math.floor(position.x / 50) * 50 + 25
            SceneManager.brush.position.y = Math.floor(position.y / 50) * 50 + 25
            SceneManager.brush.position.z = Math.floor(position.z / 50) * 50 + 25
            return
          normal = intersect.face.normal.clone()
          normal.applyMatrix4 intersect.object.matrixRotationWorld
          position = new (SceneManager.THREE().Vector3)().addVectors(intersect.point, normal)
          newCube = [
            Math.floor(position.x / 50)
            Math.floor(position.y / 50)
            Math.floor(position.z / 50)
          ]
          if Input.isAltDown
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
            return SceneManager.brush.currentCube = newCube
          else if Input.isShiftDown
            if intersect.object isnt SceneManager.plane
              @_objectHovered = intersect.object
              @_objectHovered.material.opacity = 0.5
              SceneManager.brush.position.y = 2000
              return
          else
            updateBrush()
            return
        SceneManager.brush.position.y = 2000
        return
