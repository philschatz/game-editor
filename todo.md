TODO:

- [ ] collision detector should test all voxels in the direction vector
- [x] async fetch palette info
- [x] async fetch level info (maybe from hash)
- [x] generate JSON for level
- [-] generate JSON for voxel
- [ ] store color palette in localstorage
- [ ] have voxel edit mode and level edit mode
- [ ] orient voxels
  - [x] update level format to store orientation
  - [x] randomize orientation for textures (if none is set) in game
  - [x] change sprites based on ladder orientation
- [ ] add a skymap http://jeromeetienne.github.io/threex.skymap/examples/basic.html

- [x] pause game when rotating
- [-] update player state more accurately (jumping, climbing)
- [x] fiddle with walk/jump constants to move more accurately
- [x] move camera when player moves
  - [x] fix camera being slightly off when rotated enough times
- [ ] support secret tunnels
  - [ ] make blocks transparent
- [x] get climbing to work now that we have voxel collision
  - [x] support a slight range when starting to climb
- [x] extract collision-detection and physics
  - [x] get jump up to work
  - [x] get walk left/right (and change depth) to work
- [x] use voxel collision info for collision-detection
  - [x] Map-flattening logic needs to be smarter about pillars in front of walkable area
- [x] remove the take-over mouse stuff in the engine
- [x] change camera target to the player
  - [ ] support dragging the player and dropping
- [x] add "Play" button
- [x] encode collision into voxels
- [x] abstract voxel loading more
- [x] support color/voxel palettes (level-edit vs voxel-edit)



Level JSON:

{
  name: 'Lighthouse'
  default_coords: [x, y, z, orient]
  doors: [] # store x,y,z,color,orient,url,id
  code_url: 'http://philschatz.com/game-lighthouse-level/code.js'

  palette_url: 'http://philschatz.com/game-palettes/nature.json'
  palette_urls: [
    'http://philschatz.com/game-palettes/nature/ladder-top.json'
    '/ladder-middle.json'
    './ladder-bottom.json'
    { type: 'texture', top_href: './textures/ladder-top.png'}
  ]

  map: [{x, y, z, color, orient}]
  map_compressed: [dx,dy,dz,color,dorient, ...]
  map_url: 'http://philschatz.com/game-lighthouse-level/map.json' (contains is_compressed info in the JSON)
}



To support new THREEJS I needed to:

1. change voxel-engine to use window.THREE:

var THREE = window.THREE

2. change node_modules/voxel-player/node_modules/minecraft-skin to:

Skin.prototype.UVMap = function(mesh, face, x, y, w, h, rotateBy) {
  if (!rotateBy) rotateBy = 0;
  var uvs = mesh.geometry.faceVertexUvs[0][face];
  var tileU = x;
  var tileV = y;
  var tileUvWidth = 1/64;
  var tileUvHeight = 1/32;
  if (uvs[ (0 + rotateBy) % 4 ]) {
    uvs[ (0 + rotateBy) % 4 ].x = (tileU * tileUvWidth)
    uvs[ (0 + rotateBy) % 4 ].y = 1 - (tileV * tileUvHeight)
  }
  if (uvs[ (1 + rotateBy) % 4 ]) {
    uvs[ (1 + rotateBy) % 4 ].x = (tileU * tileUvWidth)
    uvs[ (1 + rotateBy) % 4 ].y = 1 - (tileV * tileUvHeight + h * tileUvHeight)
  }
  if (uvs[ (2 + rotateBy) % 4 ]) {
    uvs[ (2 + rotateBy) % 4 ].x = (tileU * tileUvWidth + w * tileUvWidth)
    uvs[ (2 + rotateBy) % 4 ].y = 1 - (tileV * tileUvHeight + h * tileUvHeight)
  }
  if (uvs[ (3 + rotateBy) % 4 ]) {
    uvs[ (3 + rotateBy) % 4 ].x = (tileU * tileUvWidth + w * tileUvWidth)
    uvs[ (3 + rotateBy) % 4 ].y = 1 - (tileV * tileUvHeight)
  }
}




Player Movement:

1. voxel-control : input = up/down/left/right   output = target.velocity, target.resting
2. voxel-physical : input = velocity   calls collide, output = .position
3. voxel-collide
