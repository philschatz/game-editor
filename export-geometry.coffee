TextureCube = require './src/voxels/texture-cube'

module.exports = (SceneManager) ->
  colorGeo = new THREE.Geometry()
  textureGeo = new THREE.Geometry()
  for i in SceneManager.scene.children
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


  for i in SceneManager.scene.children
    scene.remove(SceneManager.scene.children[0]) if SceneManager.scene.children[0]


  cubeMaterial = new SceneManager._CubeMaterial(
    vertexColors: THREE.VertexColors
    transparent: true
  )
  cubeMaterial2 = TextureCube.meshFaceMaterial()

  mesh = new THREE.Mesh(colorGeo, cubeMaterial)
  mesh2 = new THREE.Mesh(textureGeo, cubeMaterial2)
  scene.add(mesh)
  scene.add(mesh2)
