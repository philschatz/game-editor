

module.exports = new class TextureCubeBuilder

    _materialNames: {} # filename to index
    _materials: [] # Array of all materials
    _meshMaterial: null

    constructor: ->
      @_meshMaterial = new THREE.MeshFaceMaterial(@_materials)

    # allMaterials: -> @_materials
    meshFaceMaterial: -> @_meshMaterial

    freshCube: (textureSides) ->
      geometry = new THREE.CubeGeometry(16, 16, 16)

      alreadyReindexedFaces = []
      # create textures array for all cube sides
      for i in [0..5]
        side = textureSides[i]
        unless @_materialNames[side]?
          img = new Image()
          tex = new THREE.Texture(img)
          img.src = "./src/voxels/types/textures/#{side}.png"
          img.tex = tex

          img.onload = ->
            @tex.needsUpdate = true

          mat = new THREE.MeshBasicMaterial(color: 0x00ff00, map: tex, transparent: false, overdraw: true)
          materialIndex = @_materials.length
          @_materials.push(mat)
          @_materialNames[side] = materialIndex

        faces = geometry.faces.filter (face) ->
          if face.materialIndex is i and alreadyReindexedFaces.indexOf(face) < 0
            return true

        for face in faces
          face.materialIndex = @_materialNames[side]
          alreadyReindexedFaces.push(face)

      cube = new THREE.Mesh(geometry, @_meshMaterial)
      cube.name = textureSides[0]
      cube
