(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var AxisCamera, ColorManager, ColorUtils, HashManager, Input, Interactions, KeyMouse, MainCamera, SceneManager, THREE, raf;

THREE = window.THREE;

raf = require("raf");

require('./js/exporters/OBJExporter');

require('./js/loaders/OBJLoader');

ColorUtils = require('./src/color-utils');

ColorManager = require('./src/color-manager');

AxisCamera = require('./src/axis-camera');

MainCamera = require('./src/main-camera');

Input = require('./src/input-manager')(THREE);

SceneManager = require('./src/scene-manager')(THREE, Input);

HashManager = require('./src/hash-manager')(SceneManager);

Interactions = require('./src/interactions')(Input, SceneManager);

KeyMouse = require('./src/key-mouse-handlers')(SceneManager, Interactions, Input, HashManager);

Number.prototype.mod = function(n) {
  return ((this % n) + n) % n;
};

window.startEditor = function() {
  var addColor, addColorToPalette, bindEventsAndPlugins, c, cameraHandlers, changeColor, color, container, exportFunction, fill, getDimensions, init, mouse3D, pickColor, shareDialog, showWelcome, updateColor;
  container = null;
  shareDialog = null;
  mouse3D = null;
  color = 0;
  fill = true;
  window.exportGeometry = function() {
    var c, cubeMaterial, f, geo, geo2, i, mesh, txt, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    geo = new THREE.Geometry();
    _ref = SceneManager.scene.children;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      if (i != null ? i.isVoxel : void 0) {
        c = i.material.color;
        _ref1 = i.geometry.faces;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          f = _ref1[_j];
          f.color = c;
        }
        THREE.GeometryUtils.merge(geo, i);
      }
    }
    _ref2 = SceneManager.scene.children;
    for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
      i = _ref2[_k];
      if (SceneManager.scene.children[0]) {
        scene.remove(SceneManager.scene.children[0]);
      }
    }
    cubeMaterial = new SceneManager._CubeMaterial({
      vertexColors: THREE.VertexColors,
      transparent: true
    });
    txt = new THREE.OBJExporter().parse(geo);
    geo2 = new THREE.OBJLoader().parse(txt);
    mesh = new THREE.Mesh(geo, cubeMaterial);
    return scene.add(mesh);
  };
  cameraHandlers = function(id, cameraManager) {
    var updateLabel;
    updateLabel = function() {
      var label, phi, theta, _ref;
      _ref = cameraManager.getRotation(), theta = _ref.theta, phi = _ref.phi;
      theta = Math.round(theta / 180).mod(4);
      label = (function() {
        switch (theta) {
          case 0:
            return 'X';
          case 1:
            return 'Z';
          case 2:
            return '-X';
          case 3:
            return '-Z';
          default:
            return '??';
        }
      })();
      return $("#" + id + " .axis-label").text(label);
    };
    updateLabel();
    setInterval(updateLabel, 1000);
    $("#" + id + " .axis-label").on('click', function() {
      var phi, theta, _ref;
      _ref = cameraManager.getRotation(), theta = _ref.theta, phi = _ref.phi;
      theta += 360;
      if (theta >= 720) {
        theta -= 720;
      }
      cameraManager.rotateCameraTo(theta, phi);
      return updateLabel();
    });
    $("#" + id + " .rotate-left").on('click', function() {
      var phi, theta, _ref;
      _ref = cameraManager.getRotation(), theta = _ref.theta, phi = _ref.phi;
      theta -= 180;
      if (theta < 0) {
        theta += 720;
      }
      cameraManager.rotateCameraTo(theta, phi);
      return updateLabel();
    });
    $("#" + id + " .rotate-right").on('click', function() {
      var phi, theta, _ref;
      _ref = cameraManager.getRotation(), theta = _ref.theta, phi = _ref.phi;
      theta += 180;
      if (theta >= 720) {
        theta -= 720;
      }
      cameraManager.rotateCameraTo(theta, phi);
      return updateLabel();
    });
    $("#" + id + " .zoom-in").on('click', function() {
      return cameraManager.zoom(-100);
    });
    return $("#" + id + " .zoom-out").on('click', function() {
      return cameraManager.zoom(100);
    });
  };
  cameraHandlers('axis-camera-controls', AxisCamera);
  cameraHandlers('main-camera-controls', MainCamera);
  $('#axis-camera-controls .rotate-main').on('click', function() {
    var phi, theta, _ref;
    _ref = AxisCamera.getRotation(), theta = _ref.theta, phi = _ref.phi;
    return MainCamera.rotateCameraTo(theta, phi);
  });
  showWelcome = function() {
    var seenWelcome;
    seenWelcome = localStorage.getItem("seenWelcome");
    if (seenWelcome) {
      return $("#welcome").modal();
    }
    localStorage.setItem("seenWelcome", true);
  };
  addColorToPalette = function(idx) {
    var base, clone, colorBox;
    colorBox = $("i[data-color=\"" + idx + "\"]");
    if (!colorBox.length) {
      base = $(".colorAddButton");
      clone = base.clone();
      clone.removeClass("colorAddButton");
      clone.addClass("colorPickButton");
      colorBox = clone.find(".colorAdd");
      colorBox.removeClass("colorAdd");
      colorBox.addClass("color");
      colorBox.attr("data-color", idx);
      colorBox.text("");
      base.before(clone);
      clone.click(function(e) {
        pickColor(e);
        e.preventDefault();
      });
      clone.on("contextmenu", changeColor);
    }
    colorBox.parent().attr("data-color", "#" + ColorUtils.rgb2hex(ColorManager.colors[idx]));
    colorBox.css("background", "#" + ColorUtils.rgb2hex(ColorManager.colors[idx]));
    if (ColorManager.currentColor === idx && SceneManager.brush) {
      SceneManager.brush.children[0].material.color.setRGB(ColorManager.colors[idx][0], ColorManager.colors[idx][1], ColorManager.colors[idx][2]);
    }
  };
  addColor = function(e) {
    var idx;
    ColorManager.colors.push([0.0, 0.0, 0.0]);
    idx = ColorManager.colors.length - 1;
    ColorManager.currentColor = idx;
    addColorToPalette(idx);
    HashManager.updateHash();
    updateColor(idx);
  };
  updateColor = function(idx) {
    var picker;
    ColorManager.currentColor = idx;
    picker = $("i[data-color=\"" + idx + "\"]").parent().colorpicker("show");
    picker.on("changeColor", function(e) {
      ColorManager.colors[idx] = ColorUtils.hex2rgb(e.color.toHex());
      addColorToPalette(idx);
      SceneManager.scene.children.filter(function(el) {
        return el.isVoxel;
      }).map(function(mesh) {
        SceneManager.scene.remove(mesh.wireMesh);
        SceneManager.scene.remove(mesh);
      });
      HashManager.buildFromHash();
    });
    picker.on("hide", function(e) {
      picker.unbind("click.colorpicker");
    });
  };
  changeColor = function(e) {
    var idx, targetEl;
    targetEl = $(e.currentTarget);
    idx = +targetEl.find(".color").attr("data-color");
    updateColor(idx);
    return false;
  };
  pickColor = function(e) {
    var idx, sort, targetEl, x, x1, x2, y, y1, y2, z, z1, z2, _i, _j, _k, _ref, _ref1, _ref2, _ref3, _ref4;
    targetEl = $(e.currentTarget);
    idx = +targetEl.find(".color").attr("data-color");
    ColorManager.currentColor = idx;
    SceneManager.brush.children[0].material.color.setRGB(ColorManager.colors[idx][0], ColorManager.colors[idx][1], ColorManager.colors[idx][2]);
    if (Input.startPosition && Input.endPosition) {
      sort = function(a, b) {
        if (a < b) {
          return [a, b];
        }
        return [b, a];
      };
      _ref = Input.startPosition, x1 = _ref.x, y1 = _ref.y, z1 = _ref.z;
      _ref1 = Input.endPosition, x2 = _ref1.x, y2 = _ref1.y, z2 = _ref1.z;
      Input.startPosition = null;
      Input.endPosition = null;
      Interactions.removeRectangle();
      _ref2 = sort(x1, x2), x1 = _ref2[0], x2 = _ref2[1];
      _ref3 = sort(y1, y2), y1 = _ref3[0], y2 = _ref3[1];
      _ref4 = sort(z1, z2), z1 = _ref4[0], z2 = _ref4[1];
      for (x = _i = x1; _i <= x2; x = _i += 50) {
        for (y = _j = y1; _j <= y2; y = _j += 50) {
          for (z = _k = z1; _k <= z2; z = _k += 50) {
            SceneManager.addVoxel(x, y, z, ColorManager.colors[idx]);
          }
        }
      }
    }
  };
  bindEventsAndPlugins = function() {
    var actionsMenu;
    $(window).on("hashchange", function() {
      if (updatingHash) {
        return localStorage.setItem("seenWelcome", true);
      }
      window.location.reload();
    });
    $(".colorPickButton").click(pickColor);
    $(".colorPickButton").on("contextmenu", changeColor);
    $(".colorAddButton").click(addColor);
    $(".toggle input").click(function(e) {
      setTimeout((function() {
        var el, state;
        el = $(e.target).parent();
        state = !el.hasClass("toggle-off");
        exports[el.attr("data-action")](state);
      }), 0);
    });
    actionsMenu = $(".actionsMenu");
    actionsMenu.dropkick({
      change: function(value, label) {
        if (value === "noop") {
          return;
        }
        if (value in exports) {
          exports[value]();
        }
        setTimeout((function() {
          actionsMenu.dropkick("reset");
        }), 0);
      }
    });
    $("[data-toggle=tooltip]").tooltip("show");
    $("#tagsinput").tagsInput();
    $("input, textarea").placeholder();
    $(".btn-group").on("click", "a", function() {
      $(this).siblings().removeClass("active");
      $(this).addClass("active");
    });
    $("a[href='#']").click(function(e) {
      e.preventDefault();
    });
  };
  init = function() {
    bindEventsAndPlugins();
    container = document.getElementById("editor-area");
    SceneManager.init(container);
    container.appendChild(SceneManager.renderer.domElement);
    KeyMouse.attachEvents();
    if (window.location.hash) {
      HashManager.buildFromHash();
    }
    HashManager.updateHash();
  };
  exportFunction = function(voxels) {
    var dimensions, funcString;
    dimensions = getDimensions(voxels);
    voxels = voxels.map(function(v) {
      return [v.x, v.y, v.z, v.c];
    });
    funcString = "var voxels = " + JSON.stringify(voxels) + ";";
    funcString += "var dimensions = " + JSON.stringify(dimensions) + ";";
    funcString += "voxels.map(function(voxel) {" + "if (colorMapper(voxel[3])) { addBlock([position.x + voxel[0], position.y + voxel[1], position.z + voxel[2]], colorMapper(voxel[3])) }" + "});";
    return funcString;
  };
  getDimensions = function(voxels) {
    var high, low;
    low = [0, 0, 0];
    high = [0, 0, 0];
    voxels.map(function(voxel) {
      if (voxel.x < low[0]) {
        low[0] = voxel.x;
      }
      if (voxel.x > high[0]) {
        high[0] = voxel.x;
      }
      if (voxel.y < low[1]) {
        low[1] = voxel.y;
      }
      if (voxel.y > high[1]) {
        high[1] = voxel.y;
      }
      if (voxel.z < low[2]) {
        low[2] = voxel.z;
      }
      if (voxel.z > high[2]) {
        high[2] = voxel.z;
      }
    });
    return [(high[0] - low[0]) || 1, (high[1] - low[1]) || 1, (high[2] - low[2]) || 1];
  };
  c = 0;
  while (c < 12) {
    addColorToPalette(c);
    c++;
  }
  showWelcome();
  init();
  raf(window).on("data", function() {
    return SceneManager.render();
  });
  exports.viewInstructions = function() {
    $("#welcome").modal();
  };
  exports.reset = function() {
    window.location.replace("#/");
    SceneManager.scene.children.filter(function(el) {
      return el.isVoxel;
    }).map(function(mesh) {
      SceneManager.scene.remove(mesh);
    });
  };
  exports.setColor = function(idx) {
    $("i[data-color=\"" + idx + "\"]").click();
  };
  exports.showGrid = function(bool) {
    SceneManager.grid.material.visible = bool;
  };
  $(".play-level").attr("href", "http://philschatz.com/game/" + window.location.hash);
  window.exportMap = function() {
    var voxels, voxelsReal;
    voxels = SceneManager.scene.children.filter(function(el) {
      return el.isVoxel;
    });
    voxelsReal = voxels.map(function(v) {
      return {
        x: (v.position.x - 25) / 50,
        y: (v.position.y - 25) / 50,
        z: (v.position.z - 25) / 50,
        c: v.wireMesh.material.color.getHexString()
      };
    });
    console.log(exportFunction(voxelsReal));
  };
};



},{"./js/exporters/OBJExporter":2,"./js/loaders/OBJLoader":3,"./src/axis-camera":6,"./src/color-manager":8,"./src/color-utils":9,"./src/hash-manager":10,"./src/input-manager":11,"./src/interactions":12,"./src/key-mouse-handlers":13,"./src/main-camera":14,"./src/scene-manager":15,"raf":5}],2:[function(require,module,exports){
/**
 * @author mrdoob / http://mrdoob.com/
 */

THREE.OBJExporter = function () {};

THREE.OBJExporter.prototype = {

	constructor: THREE.OBJExporter,

	parse: function ( geometry ) {

		var output = '';

		for ( var i = 0, l = geometry.vertices.length; i < l; i ++ ) {

			var vertex = geometry.vertices[ i ];
			output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';

		}

		// uvs

		for ( var i = 0, l = geometry.faceVertexUvs[ 0 ].length; i < l; i ++ ) {

			var vertexUvs = geometry.faceVertexUvs[ 0 ][ i ];

			for ( var j = 0; j < vertexUvs.length; j ++ ) {

				var uv = vertexUvs[ j ];
				output += 'vt ' + uv.x + ' ' + uv.y + '\n';

			}

		}

		// normals

		for ( var i = 0, l = geometry.faces.length; i < l; i ++ ) {

			var normals = geometry.faces[ i ].vertexNormals;

			for ( var j = 0; j < normals.length; j ++ ) {

				var normal = normals[ j ];
				output += 'vn ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';

			}

		}

		// faces

		for ( var i = 0, j = 1, l = geometry.faces.length; i < l; i ++, j += 3 ) {

			var face = geometry.faces[ i ];

			output += 'f ';
			output += ( face.a + 1 ) + '/' + ( j ) + '/' + ( j ) + ' ';
			output += ( face.b + 1 ) + '/' + ( j + 1 ) + '/' + ( j + 1 ) + ' ';
			output += ( face.c + 1 ) + '/' + ( j + 2 ) + '/' + ( j + 2 ) + '\n';

		}

		return output;

	}

}

},{}],3:[function(require,module,exports){
/**
 * @author mrdoob / http://mrdoob.com/
 */

THREE.OBJLoader = function ( manager ) {

	this.manager = ( manager !== undefined ) ? manager : THREE.DefaultLoadingManager;

};

THREE.OBJLoader.prototype = {

	constructor: THREE.OBJLoader,

	load: function ( url, onLoad, onProgress, onError ) {

		var scope = this;

		var loader = new THREE.XHRLoader( scope.manager );
		loader.setCrossOrigin( this.crossOrigin );
		loader.load( url, function ( text ) {

			onLoad( scope.parse( text ) );

		} );

	},

	parse: function ( text ) {

		function vector( x, y, z ) {

			return new THREE.Vector3( parseFloat( x ), parseFloat( y ), parseFloat( z ) );

		}

		function uv( u, v ) {

			return new THREE.Vector2( parseFloat( u ), parseFloat( v ) );

		}

		function face3( a, b, c, normals ) {

			return new THREE.Face3( a, b, c, normals );

		}
		
		var object = new THREE.Object3D();
		var geometry, material, mesh;

		function parseVertexIndex( index ) {

			index = parseInt( index );

			return index >= 0 ? index - 1 : index + vertices.length;

		}

		function parseNormalIndex( index ) {

			index = parseInt( index );

			return index >= 0 ? index - 1 : index + normals.length;

		}

		function parseUVIndex( index ) {

			index = parseInt( index );

			return index >= 0 ? index - 1 : index + uvs.length;

		}
		
		function add_face( a, b, c, normals_inds ) {

			if ( normals_inds === undefined ) {

				geometry.faces.push( face3(
					vertices[ parseVertexIndex( a ) ] - 1,
					vertices[ parseVertexIndex( b ) ] - 1,
					vertices[ parseVertexIndex( c ) ] - 1
				) );

			} else {

				geometry.faces.push( face3(
					vertices[ parseVertexIndex( a ) ] - 1,
					vertices[ parseVertexIndex( b ) ] - 1,
					vertices[ parseVertexIndex( c ) ] - 1,
					[
						normals[ parseNormalIndex( normals_inds[ 0 ] ) ].clone(),
						normals[ parseNormalIndex( normals_inds[ 1 ] ) ].clone(),
						normals[ parseNormalIndex( normals_inds[ 2 ] ) ].clone()
					]
				) );

			}

		}
		
		function add_uvs( a, b, c ) {
	  
			geometry.faceVertexUvs[ 0 ].push( [
				uvs[ parseUVIndex( a ) ].clone(),
				uvs[ parseUVIndex( b ) ].clone(),
				uvs[ parseUVIndex( c ) ].clone()
			] );

		}
		
		function handle_face_line(faces, uvs, normals_inds) {

			if ( faces[ 3 ] === undefined ) {
				
				add_face( faces[ 0 ], faces[ 1 ], faces[ 2 ], normals_inds );
				
				if ( uvs !== undefined && uvs.length > 0 ) {

					add_uvs( uvs[ 0 ], uvs[ 1 ], uvs[ 2 ] );

				}

			} else {
				
				if ( normals_inds !== undefined && normals_inds.length > 0 ) {

					add_face( faces[ 0 ], faces[ 1 ], faces[ 3 ], [ normals_inds[ 0 ], normals_inds[ 1 ], normals_inds[ 3 ] ] );
					add_face( faces[ 1 ], faces[ 2 ], faces[ 3 ], [ normals_inds[ 1 ], normals_inds[ 2 ], normals_inds[ 3 ] ] );

				} else {

					add_face( faces[ 0 ], faces[ 1 ], faces[ 3 ] );
					add_face( faces[ 1 ], faces[ 2 ], faces[ 3 ] );

				}
				
				if ( uvs !== undefined && uvs.length > 0 ) {

					add_uvs( uvs[ 0 ], uvs[ 1 ], uvs[ 3 ] );
					add_uvs( uvs[ 1 ], uvs[ 2 ], uvs[ 3 ] );

				}

			}
			
		}

		// create mesh if no objects in text

		if ( /^o /gm.test( text ) === false ) {

			geometry = new THREE.Geometry();
			material = new THREE.MeshLambertMaterial();
			mesh = new THREE.Mesh( geometry, material );
			object.add( mesh );

		}

		var vertices = [];
		var normals = [];
		var uvs = [];

		// v float float float

		var vertex_pattern = /v( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;

		// vn float float float

		var normal_pattern = /vn( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;

		// vt float float

		var uv_pattern = /vt( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;

		// f vertex vertex vertex ...

		var face_pattern1 = /f( +-?\d+)( +-?\d+)( +-?\d+)( +-?\d+)?/;

		// f vertex/uv vertex/uv vertex/uv ...

		var face_pattern2 = /f( +(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+))?/;

		// f vertex/uv/normal vertex/uv/normal vertex/uv/normal ...

		var face_pattern3 = /f( +(-?\d+)\/(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+)\/(-?\d+))( +(-?\d+)\/(-?\d+)\/(-?\d+))?/;

		// f vertex//normal vertex//normal vertex//normal ... 

		var face_pattern4 = /f( +(-?\d+)\/\/(-?\d+))( +(-?\d+)\/\/(-?\d+))( +(-?\d+)\/\/(-?\d+))( +(-?\d+)\/\/(-?\d+))?/

		// fixes

		text = text.replace( /\\\r\n/g, '' ); // handles line continuations \

		var lines = text.split( '\n' );

		for ( var i = 0; i < lines.length; i ++ ) {

			var line = lines[ i ];
			line = line.trim();

			var result;

			if ( line.length === 0 || line.charAt( 0 ) === '#' ) {

				continue;

			} else if ( ( result = vertex_pattern.exec( line ) ) !== null ) {

				// ["v 1.0 2.0 3.0", "1.0", "2.0", "3.0"]

				vertices.push( 
					geometry.vertices.push(
						vector(
							result[ 1 ], result[ 2 ], result[ 3 ]
						)
					)
				);

			} else if ( ( result = normal_pattern.exec( line ) ) !== null ) {

				// ["vn 1.0 2.0 3.0", "1.0", "2.0", "3.0"]

				normals.push(
					vector(
						result[ 1 ], result[ 2 ], result[ 3 ]
					)
				);

			} else if ( ( result = uv_pattern.exec( line ) ) !== null ) {

				// ["vt 0.1 0.2", "0.1", "0.2"]

				uvs.push(
					uv(
						result[ 1 ], result[ 2 ]
					)
				);

			} else if ( ( result = face_pattern1.exec( line ) ) !== null ) {

				// ["f 1 2 3", "1", "2", "3", undefined]

				handle_face_line(
					[ result[ 1 ], result[ 2 ], result[ 3 ], result[ 4 ] ]
				);

			} else if ( ( result = face_pattern2.exec( line ) ) !== null ) {

				// ["f 1/1 2/2 3/3", " 1/1", "1", "1", " 2/2", "2", "2", " 3/3", "3", "3", undefined, undefined, undefined]
				
				handle_face_line(
					[ result[ 2 ], result[ 5 ], result[ 8 ], result[ 11 ] ], //faces
					[ result[ 3 ], result[ 6 ], result[ 9 ], result[ 12 ] ] //uv
				);

			} else if ( ( result = face_pattern3.exec( line ) ) !== null ) {

				// ["f 1/1/1 2/2/2 3/3/3", " 1/1/1", "1", "1", "1", " 2/2/2", "2", "2", "2", " 3/3/3", "3", "3", "3", undefined, undefined, undefined, undefined]

				handle_face_line(
					[ result[ 2 ], result[ 6 ], result[ 10 ], result[ 14 ] ], //faces
					[ result[ 3 ], result[ 7 ], result[ 11 ], result[ 15 ] ], //uv
					[ result[ 4 ], result[ 8 ], result[ 12 ], result[ 16 ] ] //normal
				);

			} else if ( ( result = face_pattern4.exec( line ) ) !== null ) {

				// ["f 1//1 2//2 3//3", " 1//1", "1", "1", " 2//2", "2", "2", " 3//3", "3", "3", undefined, undefined, undefined]

				handle_face_line(
					[ result[ 2 ], result[ 5 ], result[ 8 ], result[ 11 ] ], //faces
					[ ], //uv
					[ result[ 3 ], result[ 6 ], result[ 9 ], result[ 12 ] ] //normal
				);

			} else if ( /^o /.test( line ) ) {

				geometry = new THREE.Geometry();
				material = new THREE.MeshLambertMaterial();

				mesh = new THREE.Mesh( geometry, material );
				mesh.name = line.substring( 2 ).trim();
				object.add( mesh );

			} else if ( /^g /.test( line ) ) {

				// group

			} else if ( /^usemtl /.test( line ) ) {

				// material

				material.name = line.substring( 7 ).trim();

			} else if ( /^mtllib /.test( line ) ) {

				// mtl file

			} else if ( /^s /.test( line ) ) {

				// smooth shading

			} else {

				// console.log( "THREE.OBJLoader: Unhandled line " + line );

			}

		}

		var children = object.children;

		for ( var i = 0, l = children.length; i < l; i ++ ) {

			var geometry = children[ i ].geometry;

			geometry.computeFaceNormals();
			geometry.computeBoundingSphere();

		}
		
		return object;

	}

};

},{}],4:[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      }
      throw TypeError('Uncaught, unspecified "error" event.');
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      if (typeof console.trace === 'function') {
        // not supported in IE 10
        console.trace();
      }
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],5:[function(require,module,exports){
module.exports = raf

var EE = require('events').EventEmitter
  , global = typeof window === 'undefined' ? this : window

var _raf =
  global.requestAnimationFrame ||
  global.webkitRequestAnimationFrame ||
  global.mozRequestAnimationFrame ||
  global.msRequestAnimationFrame ||
  global.oRequestAnimationFrame ||
  (global.setImmediate ? function(fn, el) {
    setImmediate(fn)
  } :
  function(fn, el) {
    setTimeout(fn, 0)
  })

function raf(el) {
  var now = raf.now()
    , ee = new EE

  ee.pause = function() { ee.paused = true }
  ee.resume = function() { ee.paused = false }

  _raf(iter, el)

  return ee

  function iter(timestamp) {
    var _now = raf.now()
      , dt = _now - now
    
    now = _now

    ee.emit('data', dt)

    if(!ee.paused) {
      _raf(iter, el)
    }
  }
}

raf.polyfill = _raf
raf.now = function() { return Date.now() }

},{"events":4}],6:[function(require,module,exports){
var CameraManager;

CameraManager = require('./camera-manager');

window.axisCamera = module.exports = new CameraManager();



},{"./camera-manager":7}],7:[function(require,module,exports){
var MainCamera;

module.exports = MainCamera = (function() {
  function MainCamera() {}

  MainCamera.prototype.radius = 1600;

  MainCamera.prototype._theta = 0;

  MainCamera.prototype._phi = 0;

  MainCamera.prototype._target = null;

  MainCamera.prototype.init = function(_scene, camera, container, _target) {
    this._scene = _scene;
    this.camera = camera;
    this.container = container;
    this._target = _target;
  };

  MainCamera.prototype.getRotation = function() {
    return {
      theta: this._theta,
      phi: this._phi
    };
  };

  MainCamera.prototype.zoom = function(delta) {
    var aspect, distance, origin, tooClose, tooFar;
    origin = {
      x: 0,
      y: 0,
      z: 0
    };
    distance = this.camera.position.distanceTo(origin);
    tooFar = distance > 6000;
    tooClose = Math.abs(this.camera.top) < 500;
    if (delta > 0 && tooFar) {
      return;
    }
    if (delta < 0 && tooClose) {
      return;
    }
    this.radius = distance;
    aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera.top += delta / 2;
    this.camera.bottom -= delta / 2;
    this.camera.left -= delta * aspect / 2;
    this.camera.right += delta * aspect / 2;
    this.camera.updateProjectionMatrix();
    this.camera.translateZ(delta);
  };

  MainCamera.prototype.rotateCameraTo = function(theta, phi) {
    if (theta == null) {
      theta = this._theta;
    }
    if (phi == null) {
      phi = this._phi;
    }
    this._theta = theta;
    this._phi = phi;
    return this.updateCamera();
  };

  MainCamera.prototype.updateCamera = function() {
    this.camera.position.x = this._target.x + this.radius * Math.sin(this._theta * Math.PI / 360) * Math.cos(this._phi * Math.PI / 360);
    this.camera.position.y = this._target.y + this.radius * Math.sin(this._phi * Math.PI / 360);
    this.camera.position.z = this._target.z + this.radius * Math.cos(this._theta * Math.PI / 360) * Math.cos(this._phi * Math.PI / 360);
    return this.camera.updateMatrix();
  };

  MainCamera.prototype.setRaycaster = function(raycaster) {
    this.raycaster = raycaster;
  };

  MainCamera.prototype.getIntersecting = function() {
    var intersect, intersectable, intersections;
    intersectable = [];
    this._scene.children.map(function(c) {
      if (c.isVoxel || c.isPlane) {
        intersectable.push(c);
      }
    });
    if (this.raycaster) {
      intersections = this.raycaster.intersectObjects(intersectable);
      if (intersections.length > 0) {
        intersect = (intersections[0].object.isBrush ? intersections[1] : intersections[0]);
        return intersect;
      }
    }
  };

  return MainCamera;

})();



},{}],8:[function(require,module,exports){
var ColorUtils, colors;

ColorUtils = require('./color-utils');

colors = ['000000', '2ECC71', '3498DB', '34495E', 'E67E22', 'ECF0F1', 'FFF500', 'FF0000', '00FF38', 'BD00FF', '08c9ff', 'D32020'].map(function(c) {
  return ColorUtils.hex2rgb(c);
});

module.exports = {
  colors: colors,
  currentColor: 0
};



},{"./color-utils":9}],9:[function(require,module,exports){
function v2h(value) {
  value = parseInt(value).toString(16)
  return value.length < 2 ? '0' + value : value
}

module.exports = {

  rgb2hex: function (rgb) {
    return v2h( rgb[ 0 ] * 255 ) + v2h( rgb[ 1 ] * 255 ) + v2h( rgb[ 2 ] * 255 );
  },

  hex2rgb: function (hex) {
    if(hex[0]=='#') hex = hex.substr(1)
    return [parseInt(hex.substr(0,2), 16)/255, parseInt(hex.substr(2,2), 16)/255, parseInt(hex.substr(4,2), 16)/255]
  }
}

},{}],10:[function(require,module,exports){
var ColorManager, decode, encode;

ColorManager = require('./color-manager');

decode = function(string) {
  var output;
  output = [];
  string.split('').forEach(function(v) {
    output.push('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.indexOf(v));
  });
  return output;
};

encode = function(array) {
  var output;
  output = '';
  array.forEach(function(v) {
    output += 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.charAt(v);
  });
  return output;
};

module.exports = function(SceneManager) {
  var HashManager;
  return new (HashManager = (function() {
    function HashManager() {}

    HashManager.prototype.updateHash = function() {
      var animationFrames, cData, code, colorString, current, currentFrame, data, i, last, object, outHash, voxels;
      currentFrame = 0;
      animationFrames = [];
      data = [];
      voxels = [];
      code = void 0;
      current = {
        x: 0,
        y: 0,
        z: 0,
        c: 0
      };
      last = {
        x: 0,
        y: 0,
        z: 0,
        c: 0
      };
      for (i in SceneManager.scene.children) {
        object = SceneManager.scene.children[i];
        if (object.isVoxel && object !== SceneManager.plane && object !== SceneManager.brush) {
          current.x = (object.position.x - 25) / 50;
          current.y = (object.position.y - 25) / 50;
          current.z = (object.position.z - 25) / 50;
          colorString = ['r', 'g', 'b'].map(function(col) {
            return object.material.color[col];
          }).join('');
          i = 0;
          while (i < ColorManager.colors.length) {
            if (ColorManager.colors[i].join('') === colorString) {
              current.c = i;
            }
            i++;
          }
          voxels.push({
            x: current.x,
            y: current.y + 1,
            z: current.z,
            c: current.c + 1
          });
          code = 0;
          if (current.x !== last.x) {
            code += 1000;
          }
          if (current.y !== last.y) {
            code += 100;
          }
          if (current.z !== last.z) {
            code += 10;
          }
          if (current.c !== last.c) {
            code += 1;
          }
          code += 10000;
          data.push(parseInt(code, 2));
          if (current.x !== last.x) {
            data.push(current.x - last.x + 32);
            last.x = current.x;
          }
          if (current.y !== last.y) {
            data.push(current.y - last.y + 32);
            last.y = current.y;
          }
          if (current.z !== last.z) {
            data.push(current.z - last.z + 32);
            last.z = current.z;
          }
          if (current.c !== last.c) {
            data.push(current.c - last.c + 32);
            last.c = current.c;
          }
        }
      }
      data = encode(data);
      animationFrames[currentFrame] = data;
      cData = '';
      outHash = '#' + (cData ? 'C/' + cData : '');
      i = 0;
      while (i < animationFrames.length) {
        if (i === 0) {
          outHash = outHash + ':A/' + animationFrames[i];
        } else {
          outHash = outHash + ':A' + i + '/' + animationFrames[i];
        }
        i++;
      }
      window.updatingHash = true;
      window.location.replace(outHash);
      $('.play-level').attr('href', 'http://philschatz.com/game/' + outHash);
      setTimeout((function() {
        window.updatingHash = false;
      }), 1);
      return voxels;
    };

    HashManager.prototype.buildFromHash = function() {
      var animationFrames, c, chunk, chunks, code, current, data, frameMask, hash, hashChunks, hashMask, hex, hexColors, i, j, l, n, nC;
      hashMask = null;
      hash = window.location.hash.substr(1);
      hashChunks = hash.split(':');
      chunks = {};
      animationFrames = [];
      j = 0;
      n = hashChunks.length;
      while (j < n) {
        chunk = hashChunks[j].split('/');
        chunks[chunk[0]] = chunk[1];
        if (chunk[0].charAt(0) === 'A') {
          animationFrames.push(chunk[1]);
        }
        j++;
      }
      if ((!hashMask || hashMask === 'C') && chunks['C']) {
        hexColors = chunks['C'];
        c = 0;
        nC = hexColors.length / 6;
        while (c < nC) {
          hex = hexColors.substr(c * 6, 6);
          ColorManager.colors[c] = ColorUtils.hex2rgb(hex);
          addColorToPalette(c);
          c++;
        }
      }
      frameMask = 'A';
      if ((!hashMask || hashMask === frameMask) && chunks[frameMask]) {
        current = {
          x: 0,
          y: 0,
          z: 0,
          c: 0
        };
        data = decode(chunks[frameMask]);
        i = 0;
        l = data.length;
        while (i < l) {
          code = data[i++].toString(2);
          if (code.charAt(1) === '1') {
            current.x += data[i++] - 32;
          }
          if (code.charAt(2) === '1') {
            current.y += data[i++] - 32;
          }
          if (code.charAt(3) === '1') {
            current.z += data[i++] - 32;
          }
          if (code.charAt(4) === '1') {
            current.c += data[i++] - 32;
          }
          if (code.charAt(0) === '1') {
            while (!ColorManager.colors[current.c]) {
              ColorManager.colors.push([0.0, 0.0, 0.0]);
            }
            SceneManager.addVoxel(current.x * 50 + 25, current.y * 50 + 25, current.z * 50 + 25, ColorManager.colors[current.c]);
          }
        }
      }
      this.updateHash(ColorManager.colors);
    };

    return HashManager;

  })());
};



},{"./color-manager":8}],11:[function(require,module,exports){
module.exports = function(THREE) {
  return {
    isShiftDown: false,
    isCtrlDown: false,
    isMouseRotating: false,
    isMouseDown: false,
    isAltDown: false,
    onMouseDownPosition: new THREE.Vector2(),
    onMouseDownPhi: 60,
    onMouseDownTheta: 45,
    mouse2D: new THREE.Vector3(0, 10000, 0.5),
    startPosition: null,
    endPosition: null
  };
};



},{}],12:[function(require,module,exports){
var ColorManager, MainCamera;

ColorManager = require('./color-manager');

MainCamera = require('./main-camera');

module.exports = function(Input, SceneManager) {
  var Interactions;
  return new (Interactions = (function() {
    function Interactions() {}

    Interactions.prototype.removeRectangle = function() {
      if (this.rectangle) {
        return SceneManager.scene.remove(this.rectangle);
      }
    };

    Interactions.prototype.interact = function() {
      var THREE, bbox, brushMaterials, cube, depth, height, intersect, matrixRotationWorld, newCube, normal, position, updateBrush, width, x1, x2, y1, y2, z1, z2, _ref, _ref1, _ref2;
      if (!MainCamera.raycaster) {
        return;
      }
      if (this._objectHovered) {
        this._objectHovered.material.opacity = 1;
        this._objectHovered = null;
      }
      intersect = MainCamera.getIntersecting();
      if (intersect) {
        normal = intersect.face.normal.clone();
        matrixRotationWorld = new (SceneManager.THREE().Matrix4)();
        matrixRotationWorld.extractRotation(intersect.object.matrixWorld);
        normal.applyMatrix4(matrixRotationWorld);
        position = new (SceneManager.THREE().Vector3)().addVectors(intersect.point, normal);
        updateBrush = function() {
          SceneManager.brush.position.x = Math.floor(position.x / 50) * 50 + 25;
          SceneManager.brush.position.y = Math.floor(position.y / 50) * 50 + 25;
          SceneManager.brush.position.z = Math.floor(position.z / 50) * 50 + 25;
        };
        if (Input.isAltDown) {
          newCube = [Math.floor(position.x / 50), Math.floor(position.y / 50), Math.floor(position.z / 50)];
          if (!SceneManager.brush.currentCube) {
            SceneManager.brush.currentCube = newCube;
          }
          if (SceneManager.brush.currentCube.join('') !== newCube.join('')) {
            if (Input.isShiftDown) {
              if (intersect.object !== SceneManager.plane) {
                SceneManager.scene.remove(intersect.object.wireMesh);
                SceneManager.scene.remove(intersect.object);
              }
            } else {
              if (SceneManager.brush.position.y !== 2000) {
                SceneManager.addVoxel(SceneManager.brush.position.x, SceneManager.brush.position.y, SceneManager.brush.position.z, ColorManager.colors[ColorManager.currentColor]);
              }
            }
          }
          updateBrush();
          HashManager.updateHash();
          SceneManager.brush.currentCube = newCube;
          return;
        } else if (Input.isShiftDown) {
          if (intersect.object !== SceneManager.plane) {
            this._objectHovered = intersect.object;
            this._objectHovered.material.opacity = 0.5;
            SceneManager.brush.position.y = 2000;
            return;
          }
        } else if (Input.startPosition && Input.isMouseDown) {
          this.removeRectangle();
          THREE = SceneManager.THREE();
          x1 = Math.floor(Input.startPosition.x / 50) * 50 + 25;
          y1 = Math.floor(Input.startPosition.y / 50) * 50 + 25;
          z1 = Math.floor(Input.startPosition.z / 50) * 50 + 25;
          x2 = Math.floor(position.x / 50) * 50 + 25;
          y2 = Math.floor(position.y / 50) * 50 + 25;
          z2 = Math.floor(position.z / 50) * 50 + 25;
          Input.endPosition = {
            x: x2,
            y: y2,
            z: z2
          };
          bbox = function(x1, x2) {
            if (x1 <= x2) {
              return [x1 - 25, x2 + 25];
            } else {
              return [x1 + 25, x2 - 25];
            }
          };
          _ref = bbox(x1, x2), x1 = _ref[0], x2 = _ref[1];
          _ref1 = bbox(y1, y2), y1 = _ref1[0], y2 = _ref1[1];
          _ref2 = bbox(z1, z2), z1 = _ref2[0], z2 = _ref2[1];
          width = Math.abs(x2 - x1);
          height = Math.abs(y2 - y1);
          depth = Math.abs(z2 - z1);
          cube = new THREE.BoxGeometry(width, height, depth);
          brushMaterials = [
            new THREE.MeshBasicMaterial({
              vertexColors: THREE.VertexColors,
              opacity: 0.5,
              transparent: true
            }), new THREE.MeshBasicMaterial({
              color: 0x000000,
              wireframe: true
            })
          ];
          brushMaterials[0].color.setRGB(0, 0, 0);
          this.rectangle = THREE.SceneUtils.createMultiMaterialObject(cube, brushMaterials);
          this.rectangle.position = {
            x: (x2 - x1) / 2 + x1,
            y: (y2 - y1) / 2 + y1,
            z: (z2 - z1) / 2 + z1
          };
          SceneManager.scene.add(this.rectangle);
        } else {
          updateBrush();
          return;
        }
      }
      SceneManager.brush.position.y = 2000;
    };

    return Interactions;

  })());
};



},{"./color-manager":8,"./main-camera":14}],13:[function(require,module,exports){
var ColorManager, MainCamera;

ColorManager = require('./color-manager');

MainCamera = require('./main-camera');

module.exports = function(SceneManager, Interactions, Input, HashManager) {
  var KeyMouseHandlers, setIsometricAngle;
  setIsometricAngle = function() {
    var phi, theta;
    theta = Math.floor((MainCamera.getRotation().theta + 180) / 180) * 180;
    phi = 0;
    MainCamera.rotateCameraTo(theta, phi);
  };
  return new (KeyMouseHandlers = (function() {
    function KeyMouseHandlers() {}

    KeyMouseHandlers.prototype.mousewheel = function(event) {
      if ($('.modal').hasClass('in')) {
        return;
      }
      return MainCamera.zoom(event.wheelDeltaY || event.detail);
    };

    KeyMouseHandlers.prototype.onWindowResize = function() {
      MainCamera.camera.aspect = MainCamera.container.clientWidth / MainCamera.container.clientHeight;
      MainCamera.camera.updateProjectionMatrix();
      SceneManager.renderer.setSize(MainCamera.container.clientWidth, MainCamera.container.clientHeight);
      Interactions.interact();
    };

    KeyMouseHandlers.prototype.onDocumentMouseMove = function(event) {
      var intersecting, phi, theta;
      event.preventDefault();
      if (!Input.isMouseRotating) {
        intersecting = MainCamera.getIntersecting();
        if (!intersecting) {
          MainCamera.container.classList.add('rotatable');
        } else {
          MainCamera.container.classList.remove('rotatable');
        }
      }
      if (Input.isMouseRotating) {
        if (!intersecting) {
          theta = -((event.clientX - Input.onMouseDownPosition.x) * 0.5) + Input.onMouseDownTheta;
          phi = ((event.clientY - Input.onMouseDownPosition.y) * 0.5) + Input.onMouseDownPhi;
          phi = Math.min(180, Math.max(-90, phi));
          MainCamera.rotateCameraTo(theta, phi);
        }
      }
      Input.mouse2D.x = (event.clientX / MainCamera.container.clientWidth) * 2 - 1;
      Input.mouse2D.y = -(event.clientY / MainCamera.container.clientHeight) * 2 + 1;
      Interactions.interact();
    };

    KeyMouseHandlers.prototype.onDocumentMouseDown = function(event) {
      var intersect, matrixRotationWorld, normal, phi, position, theta, _ref;
      event.preventDefault();
      Input.isMouseDown = event.which;
      _ref = MainCamera.getRotation(), theta = _ref.theta, phi = _ref.phi;
      Input.onMouseDownTheta = theta;
      Input.onMouseDownPhi = phi;
      Input.onMouseDownPosition.x = event.clientX;
      Input.onMouseDownPosition.y = event.clientY;
      Input.startPosition = null;
      Input.endPosition = null;
      Interactions.removeRectangle();
      intersect = MainCamera.getIntersecting();
      if (intersect) {
        normal = intersect.face.normal.clone();
        matrixRotationWorld = new (SceneManager.THREE().Matrix4)();
        matrixRotationWorld.extractRotation(intersect.object.matrixWorld);
        normal.applyMatrix4(matrixRotationWorld);
        position = new (SceneManager.THREE().Vector3)().addVectors(intersect.point, normal);
        position.x = Math.floor(position.x / 50) * 50 + 25;
        position.y = Math.floor(position.y / 50) * 50 + 25;
        position.z = Math.floor(position.z / 50) * 50 + 25;
        Input.startPosition = position;
        Input.isMouseRotating = false;
      } else {
        Input.startPosition = null;
        Input.isMouseRotating = Input.isMouseDown === 1;
      }
    };

    KeyMouseHandlers.prototype.onDocumentMouseUp = function(event) {
      var color, intersect, x, y, z, _ref;
      event.preventDefault();
      Input.isMouseDown = false;
      Input.isMouseRotating = false;
      Input.onMouseDownPosition.x = event.clientX - Input.onMouseDownPosition.x;
      Input.onMouseDownPosition.y = event.clientY - Input.onMouseDownPosition.y;
      if (Input.onMouseDownPosition.length() > 5) {
        return;
      }
      intersect = MainCamera.getIntersecting();
      if (intersect) {
        if (Input.isShiftDown) {
          if (intersect.object !== SceneManager.plane) {
            SceneManager.scene.remove(intersect.object.wireMesh);
            SceneManager.scene.remove(intersect.object);
          }
        } else {
          _ref = SceneManager.brush.position, x = _ref.x, y = _ref.y, z = _ref.z;
          color = ColorManager.colors[ColorManager.currentColor];
          if (y !== 2000) {
            SceneManager.addVoxel(x, y, z, color);
          }
        }
      }
      HashManager.updateHash();
      SceneManager.render();
      Interactions.interact();
    };

    KeyMouseHandlers.prototype.onDocumentKeyDown = function(event) {
      switch (event.keyCode) {
        case 189:
          return MainCamera.zoom(100);
        case 187:
          return MainCamera.zoom(-100);
        case 16:
          return Input.isShiftDown = true;
        case 17:
          return Input.isCtrlDown = true;
        case 18:
          return Input.isAltDown = true;
        case 65:
          return setIsometricAngle();
      }
    };

    KeyMouseHandlers.prototype.onDocumentKeyUp = function(event) {
      switch (event.keyCode) {
        case 16:
          return Input.isShiftDown = false;
        case 17:
          return Input.isCtrlDown = false;
        case 18:
          return Input.isAltDown = false;
      }
    };

    KeyMouseHandlers.prototype.attachEvents = function() {
      SceneManager.renderer.domElement.addEventListener('mousemove', this.onDocumentMouseMove, false);
      SceneManager.renderer.domElement.addEventListener('mousedown', this.onDocumentMouseDown, false);
      SceneManager.renderer.domElement.addEventListener('mouseup', this.onDocumentMouseUp, false);
      document.addEventListener('keydown', this.onDocumentKeyDown, false);
      document.addEventListener('keyup', this.onDocumentKeyUp, false);
      window.addEventListener('DOMMouseScroll', this.mousewheel, false);
      window.addEventListener('mousewheel', this.mousewheel, false);
      return window.addEventListener('resize', this.onWindowResize, false);
    };

    return KeyMouseHandlers;

  })());
};



},{"./color-manager":8,"./main-camera":14}],14:[function(require,module,exports){
var CameraManager, MainCamera,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CameraManager = require('./camera-manager');

window.mainCamera = module.exports = new (MainCamera = (function(_super) {
  __extends(MainCamera, _super);

  function MainCamera() {
    return MainCamera.__super__.constructor.apply(this, arguments);
  }

  MainCamera.prototype._theta = 90;

  MainCamera.prototype._phi = 60;

  return MainCamera;

})(CameraManager));



},{"./camera-manager":7}],15:[function(require,module,exports){
var AxisCamera, MainCamera;

MainCamera = require('./main-camera');

AxisCamera = require('./axis-camera');

module.exports = function(THREE, Input) {
  var SceneManager;
  return new (SceneManager = (function() {
    function SceneManager() {}

    SceneManager.prototype.THREE = function() {
      return THREE;
    };

    SceneManager.prototype.renderer = null;

    SceneManager.prototype.brush = null;

    SceneManager.prototype.scene = null;

    SceneManager.prototype.plane = null;

    SceneManager.prototype._container = null;

    SceneManager.prototype._camera = null;

    SceneManager.prototype._target = new THREE.Vector3(0, 200, 0);

    SceneManager.prototype._CubeMaterial = THREE.MeshBasicMaterial;

    SceneManager.prototype._cube = new THREE.BoxGeometry(50, 50, 50);

    SceneManager.prototype._axisCamera = null;

    SceneManager.prototype._projector = null;

    SceneManager.prototype._size = 500;

    SceneManager.prototype._step = 50;

    SceneManager.prototype._showWireframe = true;

    SceneManager.prototype.init = function(_container) {
      var ambientLight, brushMaterials, directionalLight, geometry, hasWebGL, i, material;
      this._container = _container;
      window.scene = this.scene = new THREE.Scene();
      this._camera = new THREE.OrthographicCamera(this._container.clientWidth / -1, this._container.clientWidth / 1, this._container.clientHeight / 1, this._container.clientHeight / -1, 1, 10000);
      MainCamera.init(this.scene, this._camera, this._container, this._target);
      MainCamera.updateCamera({
        x: 0,
        y: 0,
        z: 0
      });
      this._axisCamera = new THREE.OrthographicCamera(this._container.clientWidth / -2, this._container.clientWidth / 2, this._container.clientHeight / 2, this._container.clientHeight / -2, 1, 10000);
      this._axisCamera = new THREE.OrthographicCamera(this._container.clientWidth / -2, this._container.clientWidth / 2, this._container.clientHeight / 2, this._container.clientHeight / -2, 1, 10000);
      AxisCamera.init(this.scene, this._axisCamera, this._container, this._target);
      AxisCamera.updateCamera({
        x: 0,
        y: 0,
        z: 0
      });
      geometry = new THREE.Geometry();
      i = -this._size;
      while (i <= this._size) {
        geometry.vertices.push(new THREE.Vector3(-this._size, 0, i));
        geometry.vertices.push(new THREE.Vector3(this._size, 0, i));
        geometry.vertices.push(new THREE.Vector3(i, 0, -this._size));
        geometry.vertices.push(new THREE.Vector3(i, 0, this._size));
        i += this._step;
      }
      material = new THREE.LineBasicMaterial({
        color: 0x000000,
        opacity: 0.2
      });
      this.grid = new THREE.Line(geometry, material);
      this.grid.type = THREE.LinePieces;
      this.scene.add(this.grid);
      this._projector = new THREE.Projector();
      this.plane = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), new THREE.MeshBasicMaterial());
      this.plane.rotation.x = -Math.PI / 2;
      this.plane.visible = false;
      this.plane.isPlane = true;
      this.scene.add(this.plane);
      brushMaterials = [
        new this._CubeMaterial({
          vertexColors: THREE.VertexColors,
          opacity: 0.5,
          transparent: true
        }), new THREE.MeshBasicMaterial({
          color: 0x000000,
          wireframe: true
        })
      ];
      brushMaterials[0].color.setRGB(0, 0, 0);
      this.brush = THREE.SceneUtils.createMultiMaterialObject(this._cube, brushMaterials);
      this.brush.isBrush = true;
      this.brush.position.y = 2000;
      this.brush.overdraw = false;
      this.scene.add(this.brush);
      ambientLight = new THREE.AmbientLight(0x606060);
      this.scene.add(ambientLight);
      directionalLight = new THREE.DirectionalLight(0xffffff);
      directionalLight.position.set(1, 0.75, 0.5).normalize();
      this.scene.add(directionalLight);
      hasWebGL = (function() {
        var e;
        try {
          return !!window.WebGLRenderingContext && !!document.createElement('canvas').getContext('experimental-webgl');
        } catch (_error) {
          e = _error;
          return false;
        }
      })();
      if (hasWebGL) {
        this.renderer = new THREE.WebGLRenderer({
          antialias: true
        });
      } else {
        this.renderer = new THREE.CanvasRenderer();
      }
      return this.renderer.setSize(this._container.clientWidth, this._container.clientHeight);
    };

    SceneManager.prototype.addVoxel = function(x, y, z, col) {
      var cubeMaterial, voxel, wireframeCube, wireframeMaterial, wireframeOptions;
      cubeMaterial = new this._CubeMaterial({
        vertexColors: THREE.VertexColors,
        transparent: true
      });
      wireframeCube = new THREE.BoxGeometry(50.5, 50.5, 50.5);
      wireframeOptions = {
        color: 0x000000,
        wireframe: true,
        wireframeLinewidth: 1,
        opacity: 0.8
      };
      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions);
      cubeMaterial.color.setRGB(col[0], col[1], col[2]);
      wireframeMaterial = new THREE.MeshBasicMaterial(wireframeOptions);
      wireframeMaterial.color.setRGB(col[0] - 0.05, col[1] - 0.05, col[2] - 0.05);
      voxel = new THREE.Mesh(this._cube, cubeMaterial);
      voxel.wireMesh = new THREE.Mesh(wireframeCube, wireframeMaterial);
      voxel.isVoxel = true;
      voxel.position.x = x;
      voxel.position.y = y;
      voxel.position.z = z;
      voxel.wireMesh.position.copy(voxel.position);
      voxel.wireMesh.visible = this._showWireframe;
      voxel.matrixAutoUpdate = false;
      voxel.updateMatrix();
      voxel.name = x + ',' + y + ',' + z;
      voxel.overdraw = true;
      this.scene.add(voxel);
      this.scene.add(voxel.wireMesh);
    };

    SceneManager.prototype.render = function() {
      var bottom, height, left, view, width, windowHeight, windowWidth;
      if (!this._camera) {
        return console.warn('Trying to render scene before initialized');
      }
      windowWidth = this._container.clientWidth;
      windowHeight = this._container.clientHeight;
      this._camera.lookAt(this._target);
      MainCamera.setRaycaster(this._projector.pickingRay(Input.mouse2D.clone(), this._camera));
      this.renderer.setViewport(0, 0, windowWidth, windowHeight);
      this.renderer.setScissor(0, 0, windowWidth, windowHeight);
      this.renderer.enableScissorTest(false);
      this.renderer.setClearColor(new THREE.Color().setRGB(1, 1, 1));
      this.renderer.render(this.scene, this._camera);
      view = {
        left: 3 / 4,
        bottom: 0,
        width: 1 / 4,
        height: 1 / 3,
        background: new THREE.Color().setRGB(0.5, 0.5, 0.7)
      };
      left = Math.floor(windowWidth * view.left);
      bottom = Math.floor(windowHeight * view.bottom);
      width = Math.floor(windowWidth * view.width);
      height = Math.floor(windowHeight * view.height);
      this.renderer.setViewport(left, bottom, width, height);
      this.renderer.setScissor(left, bottom, width, height);
      this.renderer.enableScissorTest(true);
      this.renderer.setClearColor(view.background);
      this._axisCamera.lookAt(this._target);
      this.renderer.render(this.scene, this._axisCamera);
    };

    return SceneManager;

  })());
};



},{"./axis-camera":6,"./main-camera":14}]},{},[1]);
