TextureCube = require './src/voxels/texture-cube'

module.exports = (SceneManager) ->
  colorGeo = new THREE.Geometry()
  textureGeo = new THREE.Geometry()
  children = SceneManager.scene.children[..]

  doStuff = ->
    for index in [0..Math.min(children.length - 1, 10)]
      child = children.pop()

      if child?.isVoxel
        # Simple color cube
        if child.material?.color
          c = child.material.color
          for f in child.geometry.faces
            # f.vertexColors = [c, c, c]
            f.color = c
          THREE.GeometryUtils.merge(colorGeo, child)

        else if child.material # Textured cube

          # Colors are only useful for exporting
          for face in child.geometry.faces
            face.color.set(face.materialIndex)


          THREE.GeometryUtils.merge(textureGeo, child)
        else if child instanceof THREE.Object3D # Like a ladder
          # throw new Error('whoops, looks like this is not a ladder...') unless child.children.length is 2
          foo = child.children[0] # TODO:
          mesh = foo.clone()
          mesh.position.addVectors(mesh.position, child.position)
          mesh.rotation.y = foo.rotation.y
          THREE.GeometryUtils.merge(colorGeo, mesh)

        else
          throw new Error('whoops!')

      SceneManager.scene.remove(child)
      # TO maybe help with Garbage collection... delete everything from the voxel
      # for key of child
      #   delete child[key]


    # Once all children have been merged and removed...
    if children.length is 0

      cubeMaterial = new SceneManager._CubeMaterial(
        vertexColors: THREE.VertexColors
        transparent: true
      )
      cubeMaterial2 = TextureCube.meshFaceMaterial()

      mesh = new THREE.Mesh(colorGeo, cubeMaterial)
      mesh2 = new THREE.Mesh(textureGeo, cubeMaterial2)

      # scene.__webglObjects = {}
      console.log('Objects after grouping geometries: ', Object.keys(scene.__webglObjects).length)

      scene.add(mesh)
      scene.add(mesh2)

    else
      setTimeout(doStuff, 100)

  doStuff()
