### Example JSON format:
{
  name: 'Ladder Top'
  collision: 'ladder'
  # For large voxels there may be multiple collision cubes.
  collisions: [
    # origin is bottom-left-front corner
    {x:, y:, z:, collision: 'top'} # can be .5 for 1/2 voxels maybe?
  ]

  type: 'geometry' # or 'texture'
  geometry_url: './geometries/ladder-top.json'
  # or for textures:
  top_url   : './textures/grass-top.png'
  bottom_url: './textures/brick-bottom.png'
  front_url : './textures/brick-front.png'
  back_url  : './textures/brick-front.png'
  left_url  : './textures/brick-left.png'
  right_url : './textures/brick-right.png'
}
###

PALETTE = require './types/nature-palette'

# PALETTE =
#   voxels: {}
#   colors: [
#     'color-000000'
#     'color-2ECC71'
#     'color-3498DB'
#     'color-34495E'
#     'color-E67E22'
#     'color-ECF0F1'
#     'color-fff160'
#     'color-FF0000'
#     'color-00FF38'
#     'color-BD00FF'
#     'color-08c9ff'
#     'color-D32020'
#     'color-FFFF00'
#   ]


module.exports =
  voxelName: (color) -> PALETTE.colors[color]
  # voxelConfig: (voxelName) -> PALETTE.voxels[voxelName]
  collisionFor: (color) ->
    color -= 1 # The game makes 0 be "No Voxel" so everything is shifted
    voxelName = PALETTE.colors[color]

    if voxelName and PALETTE.voxels[voxelName]
      PALETTE.voxels[voxelName].collision
    else
      null
  allVoxelConfigs: -> PALETTE.voxels
