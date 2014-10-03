module.exports =

  colors: [           # These are tied to the URL hash of the level file
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
  voxels:
    'brick-light'   :
      type      : 'texture'
      front_url : './textures/brick-light-1.png'
      back_url  : './textures/brick-light-2.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/brick-light-5.png'
      right_url : './textures/brick-light-6.png'
    'brick-medium'  :
      type      : 'texture'
      front_url : './textures/brick-medium-1.png'
      back_url  : './textures/brick-medium-2.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/brick-medium-5.png'
      right_url : './textures/brick-medium-6.png'
    'brick-dark'    :
      type      : 'texture'
      front_url : './textures/brick-dark-1.png'
      back_url  : './textures/brick-dark-2.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/brick-dark-5.png'
      right_url : './textures/brick-dark-6.png'
    'brick-grasstop':
      collision : 'top'
      type      : 'texture'
      front_url : './textures/brick-grasstop-1.png'
      back_url  : './textures/brick-grasstop-2.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/brick-grasstop-1.png'
      right_url : './textures/brick-grasstop-2.png'
    'bridge-post-top':
      collision : 'top'
      type      : 'texture'
      front_url : './textures/bridge-post-top.png'
      back_url  : './textures/bridge-post-top.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/bridge-post-top.png'
      right_url : './textures/bridge-post-top.png'
    'bridge-post'   :
      type      : 'texture'
      front_url : './textures/bridge-post-1.png'
      back_url  : './textures/bridge-post-2.png'
      top_url   : './textures/grass.png'
      bottom_url: './textures/grass.png'
      left_url  : './textures/bridge-post-1.png'
      right_url : './textures/bridge-post-2.png'

    'bridge':
      name: 'Bridge'
      collision: 'top'
      type: 'geometry'
      # geometry_url: './geometries/bridge.json'
      geometry: require('./geometries/bridge.json')

    'ladder-top':
      name: 'Ladder Top'
      collision: 'ladder'
      type: 'geometry'
      # geometry_url: './geometries/ladder-top.json'
      geometry: require('./geometries/ladder-top.json')

    'ladder-middle':
      name: 'Ladder Middle'
      collision: 'ladder'
      type: 'geometry'
      # geometry_url: './geometries/ladder-middle.json'
      geometry: require('./geometries/ladder-middle.json')

    'ladder-bottom':
      name: 'Ladder Bottom'
      collision: 'ladder'
      type: 'geometry'
      # geometry_url: './geometries/ladder-bottom.json'
      geometry: require('./geometries/ladder-bottom.json')
