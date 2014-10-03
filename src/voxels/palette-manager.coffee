COLLISION = [
  null # none
  null
  null
  null
  'top' # grasstop
  'top' # bridge-post-top
  'top' # bridge
  null
  null
  null
  'ladder'
  'ladder'
  'ladder'
]

PALETTE = [
  'color-000000'
  'brick-light'
  'brick-medium'
  'brick-dark'
  'brick-grasstop'
  'bridge-post-top'
  'bridge'
  'bridge-post'
  'color-fff160'
  'color-ecf0f1'
  'ladder-top'
  'ladder-middle'
  'ladder-bottom'
]


# PALETTE = [
#   'color-000000'
#   'color-2ECC71'
#   'color-3498DB'
#   'color-34495E'
#   'color-E67E22'
#   'color-ECF0F1'
#   'color-FFF160'
#   'color-FF0000'
#   'color-00FF38'
#   'color-BD00FF'
#   'color-08c9ff'
#   'color-D32020'
#   'color-FFFF00'
# ]

module.exports =
  _PALETTE: PALETTE
  voxelName: (color) -> PALETTE[color]
  voxelCollision: (color) -> COLLISION[color]
