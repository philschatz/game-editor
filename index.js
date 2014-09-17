var THREE = require('three')
var raf = require('raf')
// var lsb = require('lsb')
// var Convert = require('voxel-critter/lib/convert.js')
// var ndarray = require('ndarray')
// var ndarrayFill = require('ndarray-fill')

ColorUtils = require('./src/color-utils')

window.startEditor = function() {
  var container
  var camera, renderer, brush, axisCamera
  var projector, plane, scene, grid, shareDialog
  var mouse2D, mouse3D, raycaster, objectHovered
  var isShiftDown = false, isCtrlDown = false, isMouseRotating = false, isMouseDown = false, isAltDown = false
  var onMouseDownPosition = new THREE.Vector2(), onMouseDownPhi = 60, onMouseDownTheta = 45
  var radius = 1600, theta = 90, phi = 60
  var target = new THREE.Vector3( 0, 200, 0 ) // -1200, 300, 900
  var color = 0
  var CubeMaterial = THREE.MeshBasicMaterial
  var cube = new THREE.CubeGeometry( 50, 50, 50 )
  var wireframeCube = new THREE.CubeGeometry(50.5, 50.5 , 50.5)
  var wireframe = true, fill = true, animation = false, animating = false, animationInterval
  var manualAnimating = false
  var sliderEl, playPauseEl
  var wireframeOptions = { color: 0x000000, wireframe: true, wireframeLinewidth: 1, opacity: 0.8 }
  var wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
  var animationFrames = []
  var currentFrame = 0
  //var colors = ['000000', 'FFF500', ].map(function(c) { return ColorUtils.hex2rgb(c) })
  var colors = ['000000', '2ECC71', '3498DB', '34495E', 'E67E22', 'ECF0F1', 'FFF500', 'FF0000', '00FF38', 'BD00FF', '08c9ff', 'D32020'].map(function(c) { return ColorUtils.hex2rgb(c); })
  for( var c = 0; c < 12; c++ ) {
    addColorToPalette(c)
  }

  showWelcome()
  init()
  raf(window).on('data', render)

  function showWelcome() {
    var seenWelcome = localStorage.getItem('seenWelcome')
    if (seenWelcome) return
    $('#welcome').modal()
    localStorage.setItem('seenWelcome', true)
  }

  exports.viewInstructions = function() {
    $('#welcome').modal()
  }

  exports.reset = function() {
    window.location.replace('#/')
    scene.children
      .filter(function(el) { return el.isVoxel })
      .map(function(mesh) { scene.remove(mesh) })
  }

  exports.setColor = function(idx) {
    $('i[data-color="' + idx + '"]').click()
  }

  exports.showGrid = function(bool) {
    grid.material.visible = bool
  }

  // function getVoxels() {
  //   var hash = window.location.hash.substr(1)
  //   var convert = new Convert()
  //   var data = convert.toVoxels(hash)
  //   var l = data.bounds[0]
  //   var h = data.bounds[1]
  //   var d = [ h[0]-l[0] + 1, h[1]-l[1] + 1, h[2]-l[2] + 1]
  //   var len = d[0] * d[1] * d[2]
  //   var voxels = ndarray(new Int32Array(len), [d[0], d[1], d[2]])
  //
  //   var colors = [undefined]
  //   data.colors.map(function(c) {
  //     colors.push('#' + ColorUtils.rgb2hex(c))
  //   })
  //
  //   function generateVoxels(x, y, z) {
  //     var offset = [x + l[0], y + l[1], z + l[2]]
  //     var val = data.voxels[offset.join('|')]
  //     return data.colors[val] ? val + 1: 0
  //   }
  //
  //   ndarrayFill(voxels, generateVoxels)
  //   return {voxels: voxels, colors: colors}
  // }

  function addVoxel(x, y, z, c) {
    var cubeMaterial = new CubeMaterial( { vertexColors: THREE.VertexColors, transparent: true } )
    var col = colors[c] || colors[0]
    cubeMaterial.color.setRGB( col[0], col[1], col[2] )
    var wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions)
    wireframeMaterial.color.setRGB( col[0]-0.05, col[1]-0.05, col[2]-0.05 )
    var voxel = new THREE.Mesh( cube, cubeMaterial )
    voxel.wireMesh = new THREE.Mesh( wireframeCube, wireframeMaterial )
    voxel.isVoxel = true
    voxel.position.x = x
    voxel.position.y = y
    voxel.position.z = z
    voxel.wireMesh.position.copy(voxel.position)
    voxel.wireMesh.visible = wireframe
    voxel.matrixAutoUpdate = false
    voxel.updateMatrix()
    voxel.name = x + "," + y + "," + z
    voxel.overdraw = true
    scene.add( voxel )
    scene.add( voxel.wireMesh )
  }

  function addColorToPalette(idx) {
    // add a button to the group
    var colorBox = $('i[data-color="' + idx + '"]')
    if(!colorBox.length) {
      var base = $('.colorAddButton')
      var clone = base.clone()
      clone.removeClass('colorAddButton')
      clone.addClass('colorPickButton')
      colorBox = clone.find('.colorAdd')
      colorBox.removeClass('colorAdd')
      colorBox.addClass('color')
      colorBox.attr('data-color',idx)
      colorBox.text('')
      base.before(clone)
      clone.click(function(e) {
        pickColor(e)
        e.preventDefault()
      })
      clone.on("contextmenu", changeColor)
    }

    colorBox.parent().attr('data-color','#'+ColorUtils.rgb2hex(colors[idx]))
    colorBox.css('background',"#"+ColorUtils.rgb2hex(colors[idx]))

    if( color == idx && brush )
      brush.children[0].material.color.setRGB(colors[idx][0], colors[idx][1], colors[idx][2])
  }

  function zoom(delta) {
    var origin = {x: 0, y: 0, z: 0}
    var distance = camera.position.distanceTo(origin)
    var tooFar = distance  > 6000
    var tooClose = Math.abs(camera.top) < 1000
    if (delta > 0 && tooFar) return
    if (delta < 0 && tooClose) return
    radius = distance // for mouse drag calculations to be correct
    aspect = container.clientWidth / container.clientHeight
    camera.top += delta / 2;
    camera.bottom -= delta / 2;
    camera.left -= delta * aspect / 2;
    camera.right += delta * aspect / 2;
    // camera.updateMatrix();
    camera.updateProjectionMatrix();

    camera.translateZ( delta )
  }

  function setIsometricAngle() {

    theta += 90

    camera.position.x = radius * Math.sin( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
    camera.position.y = radius * Math.sin( phi * Math.PI / 360 )
    camera.position.z = radius * Math.cos( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
    camera.updateMatrix()

  }

  function addColor(e) {
    //add new color
    colors.push([0.0,0.0,0.0])
    idx = colors.length-1

    color = idx;

    addColorToPalette(idx)

    updateHash()

    updateColor(idx)
  }

  function updateColor(idx) {
    color = idx
    var picker = $('i[data-color="' + idx + '"]').parent().colorpicker('show')

    picker.on('changeColor', function(e) {
      colors[idx]=ColorUtils.hex2rgb(e.color.toHex())
      addColorToPalette(idx)

      // todo:  better way to update color of existing blocks
      scene.children
        .filter(function(el) { return el.isVoxel })
        .map(function(mesh) { scene.remove(mesh.wireMesh); scene.remove(mesh) })
      var frameMask = 'A'
      if (currentFrame != 0) frameMask = 'A' + currentFrame
      buildFromHash(frameMask)
    })
    picker.on('hide', function(e) {
      // todo:  add a better remove for the colorpicker.
      picker.unbind('click.colorpicker')
    })
  }

  function changeColor(e) {
    var target = $(e.currentTarget)
    var idx = +target.find('.color').attr('data-color')
    updateColor(idx)
    return false // eat the event
  }

  function pickColor(e) {
    var target = $(e.currentTarget)
    var idx = +target.find('.color').attr('data-color')

    color = idx
    brush.children[0].material.color.setRGB(colors[idx][0], colors[idx][1], colors[idx][2])
  }

  function bindEventsAndPlugins() {

    $(window).on('hashchange', function() {
      if (updatingHash) return
      localStorage.setItem('seenWelcome', true)
      window.location.reload()
    })


    $('.colorPickButton').click(pickColor)
    $('.colorPickButton').on("contextmenu", changeColor)
    $('.colorAddButton').click(addColor)

    $('.toggle input').click(function(e) {
      // setTimeout ensures this fires after the input value changes
      setTimeout(function() {
        var el = $(e.target).parent()
        var state = !el.hasClass('toggle-off')
        exports[el.attr('data-action')](state)
      }, 0)
    })

    var actionsMenu = $(".actionsMenu")
    actionsMenu.dropkick({
      change: function(value, label) {
        if (value === 'noop') return
        if (value in exports) exports[value]()
        setTimeout(function() {
          actionsMenu.dropkick('reset')
        }, 0)
      }
    })


    // Init tooltips
    $("[data-toggle=tooltip]").tooltip("show");

    // Init tags input
    $("#tagsinput").tagsInput();


    // JS input/textarea placeholder
    $("input, textarea").placeholder();

    $(".btn-group").on("click", "a", function() {
        $(this).siblings().removeClass("active");
        $(this).addClass("active");
    });

    // Disable link click not scroll top
    $("a[href='#']").click(function(e) {
        e.preventDefault()
    });

  }

  function init() {

    bindEventsAndPlugins()

    container = document.getElementById( 'editor-area' )

    //camera = new THREE.PerspectiveCamera( 40, container.clientWidth / container.clientHeight, 1, 10000 )
    camera = new THREE.OrthographicCamera(container.clientWidth / -1, container.clientWidth / 1, container.clientHeight / 1, container.clientHeight / -1, 1, 10000 )
    camera.position.x = radius * Math.sin( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
    camera.position.y = radius * Math.sin( phi * Math.PI / 360 )
    camera.position.z = radius * Math.cos( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )


    axisCamera = new THREE.OrthographicCamera(container.clientWidth / -2, container.clientWidth / 2, container.clientHeight / 2, container.clientHeight / -2, 1, 10000 )


    scene = new THREE.Scene()
    window.scene = scene

    // Grid

    var size = 500, step = 50

    var geometry = new THREE.Geometry()

    for ( var i = - size; i <= size; i += step ) {

      geometry.vertices.push( new THREE.Vector3( - size, 0, i ) )
      geometry.vertices.push( new THREE.Vector3(   size, 0, i ) )

      geometry.vertices.push( new THREE.Vector3( i, 0, - size ) )
      geometry.vertices.push( new THREE.Vector3( i, 0,   size ) )

    }

    var material = new THREE.LineBasicMaterial( { color: 0x000000, opacity: 0.2 } )

    var line = new THREE.Line( geometry, material )
    line.type = THREE.LinePieces
    grid = line
    scene.add( line )

    // Plane

    projector = new THREE.Projector()

    plane = new THREE.Mesh( new THREE.PlaneGeometry( 1000, 1000 ), new THREE.MeshBasicMaterial() )
    plane.rotation.x = - Math.PI / 2
    plane.visible = false
    plane.isPlane = true
    scene.add( plane )

    mouse2D = new THREE.Vector3( 0, 10000, 0.5 )

    // Brush

    var brushMaterials = [
      new CubeMaterial( { vertexColors: THREE.VertexColors, opacity: 0.5, transparent: true } ),
      new THREE.MeshBasicMaterial( { color: 0x000000, wireframe: true } )
    ]
    brushMaterials[0].color.setRGB(colors[0][0], colors[0][1], colors[0][2])
    brush = THREE.SceneUtils.createMultiMaterialObject( cube, brushMaterials )

    brush.isBrush = true
    brush.position.y = 2000
    brush.overdraw = false
    scene.add( brush )

    // Lights

    var ambientLight = new THREE.AmbientLight( 0x606060 )
    scene.add( ambientLight )

    var directionalLight = new THREE.DirectionalLight( 0xffffff );
		directionalLight.position.set( 1, 0.75, 0.5 ).normalize();
		scene.add( directionalLight );


    var hasWebGL =  ( function () { try { return !! window.WebGLRenderingContext && !! document.createElement( 'canvas' ).getContext( 'experimental-webgl' ); } catch( e ) { return false; } } )()

    if (hasWebGL) renderer = new THREE.WebGLRenderer({antialias: true})
    else renderer = new THREE.CanvasRenderer()

    renderer.setSize( container.clientWidth, container.clientHeight )

    container.appendChild(renderer.domElement)


    renderer.domElement.addEventListener( 'mousemove', onDocumentMouseMove, false )
    renderer.domElement.addEventListener( 'mousedown', onDocumentMouseDown, false )
    renderer.domElement.addEventListener( 'mouseup', onDocumentMouseUp, false )
    document.addEventListener( 'keydown', onDocumentKeyDown, false )
    document.addEventListener( 'keyup', onDocumentKeyUp, false )
    window.addEventListener('DOMMouseScroll', mousewheel, false);
    window.addEventListener('mousewheel', mousewheel, false);

    function mousewheel( event ) {
      // prevent zoom if a modal is open
      if ($('.modal').hasClass('in'))
        return
      zoom(event.wheelDeltaY || event.detail)
    }

    window.addEventListener( 'resize', onWindowResize, false )

    if ( window.location.hash ) buildFromHash()

    updateHash()

  }

  function onWindowResize() {

    camera.aspect = container.clientWidth / container.clientHeight
    camera.updateProjectionMatrix()

    renderer.setSize( container.clientWidth, container.clientHeight )
    interact()
  }

  function getIntersecting() {
    var intersectable = []
    scene.children.map(function(c) { if (c.isVoxel || c.isPlane) intersectable.push(c); })
    if (raycaster) {
      var intersections = raycaster.intersectObjects( intersectable )
      if (intersections.length > 0) {
        var intersect = intersections[ 0 ].object.isBrush ? intersections[ 1 ] : intersections[ 0 ]
        return intersect
      }

    }
  }

  function interact() {
    if (typeof raycaster === 'undefined') return

    if ( objectHovered ) {
      objectHovered.material.opacity = 1
      objectHovered = null
    }

    var intersect = getIntersecting()

    if ( intersect ) {
      var normal = intersect.face.normal.clone()
      normal.applyMatrix4( intersect.object.matrixRotationWorld )
      var position = new THREE.Vector3().addVectors( intersect.point, normal )
      var newCube = [Math.floor( position.x / 50 ), Math.floor( position.y / 50 ), Math.floor( position.z / 50 )]

      function updateBrush() {
        brush.position.x = Math.floor( position.x / 50 ) * 50 + 25
        brush.position.y = Math.floor( position.y / 50 ) * 50 + 25
        brush.position.z = Math.floor( position.z / 50 ) * 50 + 25
      }

      if (isAltDown) {
        if (!brush.currentCube) brush.currentCube = newCube
        if (brush.currentCube.join('') !== newCube.join('')) {
          if ( isShiftDown ) {
            if ( intersect.object !== plane ) {
              scene.remove( intersect.object.wireMesh )
              scene.remove( intersect.object )
            }
          } else {
            if (brush.position.y != 2000) addVoxel(brush.position.x, brush.position.y, brush.position.z, color)
          }
        }
        updateBrush()
        updateHash()
        return brush.currentCube = newCube
      } else if ( isShiftDown ) {
        if ( intersect.object !== plane ) {
          objectHovered = intersect.object
          objectHovered.material.opacity = 0.5
          brush.position.y = 2000
          return
        }
      } else {
        updateBrush()
        return
      }
    }
    brush.position.y = 2000
  }

  function onDocumentMouseMove( event ) {
    event.preventDefault()

    if (!isMouseRotating) {
      // change the mouse cursor to a + letting the user know they can rotate
      intersecting = getIntersecting();
      if (!intersecting) {
        container.classList.add('rotatable');
      } else {
        container.classList.remove('rotatable');
      }

    }

    if ( isMouseDown == 1) { // left click


      // Rotate only if you clicked outside a block
      if (!intersecting) {

        theta = - ( ( event.clientX - onMouseDownPosition.x ) * 0.5 ) + onMouseDownTheta
        phi = ( ( event.clientY - onMouseDownPosition.y ) * 0.5 ) + onMouseDownPhi

        phi = Math.min( 180, Math.max( 0, phi ) )

        camera.position.x = target.x + radius * Math.sin( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
        camera.position.y = target.y + radius * Math.sin( phi * Math.PI / 360 )
        camera.position.z = target.z + radius * Math.cos( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
        camera.updateMatrix()

      }


    } else if ( isMouseDown == 2) { // middle click

      theta = - ( ( event.clientX - onMouseDownPosition.x ) * 0.5 ) + onMouseDownTheta
      phi = ( ( event.clientY - onMouseDownPosition.y ) * 0.5 ) + onMouseDownPhi

      phi = Math.min( 180, Math.max( 0, phi ) )

target.x += Math.sin( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
target.y += Math.sin( phi * Math.PI / 360 )
target.z += Math.cos( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )

    }


    mouse2D.x = ( event.clientX / container.clientWidth ) * 2 - 1
    mouse2D.y = - ( event.clientY / container.clientHeight ) * 2 + 1

    interact()
  }

  function onDocumentMouseDown( event ) {
    event.preventDefault()
    isMouseDown = event.which
    onMouseDownTheta = theta
    onMouseDownPhi = phi
    onMouseDownPosition.x = event.clientX
    onMouseDownPosition.y = event.clientY
    isMouseRotating = !getIntersecting()
  }

  function onDocumentMouseUp( event ) {
    event.preventDefault()
    isMouseDown = false
    isMouseRotating = false
    onMouseDownPosition.x = event.clientX - onMouseDownPosition.x
    onMouseDownPosition.y = event.clientY - onMouseDownPosition.y

    if ( onMouseDownPosition.length() > 5 ) return

    var intersect = getIntersecting()

    if ( intersect ) {
      if ( isShiftDown ) {
        if ( intersect.object != plane ) {
          scene.remove( intersect.object.wireMesh )
          scene.remove( intersect.object )
        }
      } else {
        if (brush.position.y != 2000) addVoxel(brush.position.x, brush.position.y, brush.position.z, color)
      }
    }

    updateHash()
    render()
    interact()
  }

  function onDocumentKeyDown( event ) {
    console.log(event.keyCode);
    switch( event.keyCode ) {
      case 189: zoom(100); break
      case 187: zoom(-100); break
      case 49: exports.setColor(0); break
      case 50: exports.setColor(1); break
      case 51: exports.setColor(2); break
      case 52: exports.setColor(3); break
      case 53: exports.setColor(4); break
      case 54: exports.setColor(5); break
      case 55: exports.setColor(6); break
      case 56: exports.setColor(7); break
      case 57: exports.setColor(8); break
      case 48: exports.setColor(9); break
      case 16: isShiftDown = true; break
      case 17: isCtrlDown = true; break
      case 18: isAltDown = true; break
      case 65: setIsometricAngle(); break
    }

  }

  function onDocumentKeyUp( event ) {

    switch( event.keyCode ) {
      case 16: isShiftDown = false; break
      case 17: isCtrlDown = false; break
      case 18: isAltDown = false; break
    }
  }


  // Array.prototype.diff = function(a) {
  //   return this.filter(function(i) {return !(a.indexOf(i) > -1);});
  // };


  function buildFromHash(hashMask) {

    var hash = window.location.hash.substr( 1 ),
    hashChunks = hash.split(':'),
    chunks = {}

    animationFrames = []
    for( var j = 0, n = hashChunks.length; j < n; j++ ) {
      chunk = hashChunks[j].split('/')
      chunks[chunk[0]] = chunk[1]
      if (chunk[0].charAt(0) == 'A') {
        animationFrames.push(chunk[1])
      }
    }

    if ( (!hashMask || hashMask == 'C') && chunks['C'] )
    {
      // decode colors
      var hexColors = chunks['C']
      for(var c = 0, nC = hexColors.length/6; c < nC; c++) {
        var hex = hexColors.substr(c*6,6)
        colors[c] = ColorUtils.hex2rgb(hex)
        addColorToPalette(c)
      }
    }
    var frameMask = 'A'

    if (currentFrame != 0) frameMask = 'A' + currentFrame

    if ( (!hashMask || hashMask == frameMask) && chunks[frameMask] ) {
      // decode geo
      var current = { x: 0, y: 0, z: 0, c: 0 }
      var data = decode( chunks[frameMask] )
      var i = 0, l = data.length

      while ( i < l ) {

        var code = data[ i ++ ].toString( 2 )
        if ( code.charAt( 1 ) == "1" ) current.x += data[ i ++ ] - 32
        if ( code.charAt( 2 ) == "1" ) current.y += data[ i ++ ] - 32
        if ( code.charAt( 3 ) == "1" ) current.z += data[ i ++ ] - 32
        if ( code.charAt( 4 ) == "1" ) current.c += data[ i ++ ] - 32
        if ( code.charAt( 0 ) == "1" ) {
          addVoxel(current.x * 50 + 25, current.y * 50 + 25, current.z * 50 + 25, current.c)
        }
      }
    }

    updateHash()

  }

  function updateHash() {
    var data = [], voxels = [], code
    var current = { x: 0, y: 0, z: 0, c: 0 }
    var last = { x: 0, y: 0, z: 0, c: 0 }
    for ( var i in scene.children ) {

      var object = scene.children[ i ]

      if ( object.isVoxel && object !== plane && object !== brush ) {

        current.x = ( object.position.x - 25 ) / 50
        current.y = ( object.position.y - 25 ) / 50
        current.z = ( object.position.z - 25 ) / 50

        var colorString = ['r', 'g', 'b'].map(function(col) { return object.material.color[col] }).join('')
        // this string matching of floating point values to find an index seems a little sketchy
        for (var i = 0; i < colors.length; i++) if (colors[i].join('') === colorString) current.c = i
        voxels.push({x: current.x, y: current.y + 1, z: current.z , c: current.c + 1})

        code = 0

        if ( current.x != last.x ) code += 1000
        if ( current.y != last.y ) code += 100
        if ( current.z != last.z ) code += 10
        if ( current.c != last.c ) code += 1

        code += 10000

        data.push( parseInt( code, 2 ) )

        if ( current.x != last.x ) {

          data.push( current.x - last.x + 32 )
          last.x = current.x

        }

        if ( current.y != last.y ) {

          data.push( current.y - last.y + 32 )
          last.y = current.y

        }

        if ( current.z != last.z ) {

          data.push( current.z - last.z + 32 )
          last.z = current.z

        }

        if ( current.c != last.c ) {

          data.push( current.c - last.c + 32 )
          last.c = current.c

        }
      }
    }

    data = encode(data)
    animationFrames[currentFrame] = data

    var cData = '';
    // ignore color data
    // for (var i = 0; i < colors.length; i++){
    //   cData += ColorUtils.rgb2hex(colors[i]);
    // }

    var outHash = "#" + (cData ? ("C/" + cData) : '')
    for (var i = 0; i < animationFrames.length; i++) {
      if (i === 0) {
        outHash = outHash + ":A/" + animationFrames[i]
      } else {
        outHash = outHash + ":A" + i + '/' + animationFrames[i]
      }
    }

    // hack to ignore programmatic hash changes
    window.updatingHash = true

    window.location.replace(outHash)

    // Update the Play Level link
    $('.play-level').attr('href', 'http://philschatz.com/game/' + outHash);

    setTimeout(function() {
      window.updatingHash = false
    }, 1)

    return voxels
  }

  // Update the Play Level link
  $('.play-level').attr('href', 'http://philschatz.com/game/' + window.location.hash);


  function exportFunction(voxels) {
    var dimensions = getDimensions(voxels)
    voxels = voxels.map(function(v) { return [v.x, v.y, v.z, v.c]})
    var funcString = "var voxels = " + JSON.stringify(voxels) + ";"
    funcString += 'var dimensions = ' + JSON.stringify(dimensions) + ';'
    funcString += 'voxels.map(function(voxel) {' +
    'if (colorMapper(voxel[3])) { addBlock([position.x + voxel[0], position.y + voxel[1], position.z + voxel[2]], colorMapper(voxel[3])) }' +
    '});'
    return funcString
  }



  window.exportMap = function() {
    var voxels = scene.children
      .filter(function(el) { return el.isVoxel });
    var voxelsReal = voxels.map(function(v) { return {x:(v.position.x-25)/50, y:(v.position.y-25)/50, z:(v.position.z-25)/50, c:v.wireMesh.material.color.getHexString()};});
    console.log(exportFunction(voxelsReal));
  }

  // skips every fourth byte when encoding images,
  // i.e. leave the alpha channel
  // alone and only change RGB
  function pickRGB(idx) {
    return idx + (idx/3) | 0
  }


  function exportImage(width, height) {
    var canvas = getExportCanvas(width, height)
    var image = new Image
    image.src = canvas.toDataURL()
    return image
  }



  function getDimensions(voxels) {
    var low = [0,0,0], high = [0,0,0]
    voxels.map(function(voxel) {
      if (voxel.x < low[0]) low[0] = voxel.x
      if (voxel.x > high[0]) high[0] = voxel.x
      if (voxel.y < low[1]) low[1] = voxel.y
      if (voxel.y > high[1]) high[1] = voxel.y
      if (voxel.z < low[2]) low[2] = voxel.z
      if (voxel.z > high[2]) high[2] = voxel.z
    })
    return [ (high[0]-low[0]) || 1, (high[1]-low[1]) || 1, (high[2]-low[2]) || 1 ]
  }

  // https://gist.github.com/665235

  function decode( string ) {
    var output = []
    string.split('').forEach( function ( v ) { output.push( "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf( v ) ) } )
    return output
  }

  function encode( array ) {
    var output = ""
    array.forEach( function ( v ) { output += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt( v ) } )
    return output
  }

  function save() {
    window.open( renderer.domElement.toDataURL('image/png'), 'mywindow' )
  }

  function render() {

    camera.lookAt( target )
    raycaster = projector.pickingRay( mouse2D.clone(), camera )


    renderer.setViewport();
    renderer.setScissor() // TODO: this might ned to become 0,0,renderer.domElement.width,renderer.domElement.height
    renderer.enableScissorTest(false);
    renderer.setClearColor(new THREE.Color().setRGB( 1, 1, 1 ))

    renderer.render( scene, camera )

// return;


          // camera 2
          windowWidth = container.clientWidth;
          windowHeight = container.clientHeight;
          view = {
            left: 3/4,
            bottom: 0,
            width: 1/4,
            height: 1/4,
            background: new THREE.Color().setRGB( 0.5, 0.5, 0.7 )
          }
          var left   = Math.floor( windowWidth  * view.left );
					var bottom = Math.floor( windowHeight * view.bottom );
					var width  = Math.floor( windowWidth  * view.width );
					var height = Math.floor( windowHeight * view.height );
					renderer.setViewport( left, bottom, width, height );
					renderer.setScissor( left, bottom, width, height );
					renderer.enableScissorTest ( true );
					renderer.setClearColor( view.background );

          axisCamera.position.x = 1000;
          axisCamera.position.y = target.y;
          axisCamera.position.z = target.z;
          axisCamera.lookAt(target);

          renderer.render(scene, axisCamera)


          // // camera 2
          // windowWidth = container.clientWidth;
          // windowHeight = container.clientHeight;
          // view = {
          //   left: 2/3,
          //   bottom: 1/3,
          //   width: 1/3,
          //   height: 1/3,
          //   background: new THREE.Color().setRGB( 0.7, 0.5, 0.5 )
          // }
          // var left   = Math.floor( windowWidth  * view.left );
          // var bottom = Math.floor( windowHeight * view.bottom );
          // var width  = Math.floor( windowWidth  * view.width );
          // var height = Math.floor( windowHeight * view.height );
          // renderer.setViewport( left, bottom, width, height );
          // renderer.setScissor( left, bottom, width, height );
          // renderer.enableScissorTest ( true );
          // renderer.setClearColor( view.background );
          //
          // axisCamera.position.x = target.x;
          // axisCamera.position.y = 1000;
          // axisCamera.position.z = target.z;
          // axisCamera.lookAt(target);
          // renderer.render(scene, axisCamera)


          // view = {
          //   left: 2/3,
          //   bottom: 2/3,
          //   width: 1/3,
          //   height: 1/3,
          //   background: new THREE.Color().setRGB( 0.5, 0.7, 0.5 )
          // }
          // var left   = Math.floor( windowWidth  * view.left );
          // var bottom = Math.floor( windowHeight * view.bottom );
          // var width  = Math.floor( windowWidth  * view.width );
          // var height = Math.floor( windowHeight * view.height );
          // renderer.setViewport( left, bottom, width, height );
          // renderer.setScissor( left, bottom, width, height );
          // renderer.enableScissorTest ( true );
          // renderer.setClearColor( view.background );
          //
          // axisCamera.position.x = target.x;
          // axisCamera.position.y = target.y;
          // axisCamera.position.z = 1000;
          // axisCamera.lookAt(target);
          //
          // renderer.render(scene, axisCamera)


  }

}
