TextureCube = require './src/voxels/texture-cube'

module.exports = (SceneManager) ->
  colorGeo = new THREE.Geometry()
  textureGeo = new THREE.Geometry()
  children = SceneManager.scene.children[..]

  doStuff = ->
    for index in [0..Math.min(children.length - 1, 10)]
      i = children.pop()

      if i?.isVoxel
        # Simple color cube
        if i.material?.color
          c = i.material.color
          for f in i.geometry.faces
            # f.vertexColors = [c, c, c]
            f.color = c
          THREE.GeometryUtils.merge(colorGeo, i)

        else if i.material # Textured cube

          for face in i.geometry.faces
            face.color.set(face.materialIndex)

          THREE.GeometryUtils.merge(textureGeo, i)
        else if i instanceof THREE.Object3D # Like a ladder
          # throw new Error('whoops, looks like this is not a ladder...') unless i.children.length is 2
          child = i.children[0] # TODO:
          mesh = child.clone()
          mesh.position.addVectors(mesh.position, i.position)
          THREE.GeometryUtils.merge(colorGeo, mesh)

        else
          throw new Error('whoops!')

      SceneManager.scene.remove(i)
      # TO maybe help with Garbage collection... delete everything from the voxel
      for key of i
        delete i[key]


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
