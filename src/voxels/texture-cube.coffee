

module.exports = (textureSides) ->
  geometry = new THREE.CubeGeometry(50, 50, 50)
  materials = []

  # create textures array for all cube sides
  for i in [0..5]
     img = new Image()
     tex = new THREE.Texture(img)
     img.src = "./src/voxels/textures/#{textureSides[i]}.png"
     img.tex = tex

     img.onload = ->
        @tex.needsUpdate = true

     mat = new THREE.MeshBasicMaterial(color: 0x00ff00, map: tex, transparent: false, overdraw: true)
     materials.push(mat)

  cube = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial(materials))
  cube.name = textureSides[0]
  cube
