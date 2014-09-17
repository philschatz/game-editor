# https://gist.github.com/665235
decode = (string) ->
  output = []
  string.split("").forEach (v) ->
    output.push "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(v)
    return
  output

encode = (array) ->
  output = ""
  array.forEach (v) ->
    output += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(v)
    return
  output


module.exports = (SceneManager) ->
  new class HashManager

    updateHash: (colors) ->
      currentFrame = 0
      animationFrames = []
      data = []
      voxels = []
      code = undefined
      current =
        x: 0
        y: 0
        z: 0
        c: 0

      last =
        x: 0
        y: 0
        z: 0
        c: 0

      for i of SceneManager.scene.children
        object = SceneManager.scene.children[i]
        if object.isVoxel and object isnt SceneManager.plane and object isnt SceneManager.brush
          current.x = (object.position.x - 25) / 50
          current.y = (object.position.y - 25) / 50
          current.z = (object.position.z - 25) / 50
          colorString = [
            "r"
            "g"
            "b"
          ].map((col) ->
            object.material.color[col]
          ).join("")

          # this string matching of floating point values to find an index seems a little sketchy
          i = 0

          while i < colors.length
            current.c = i  if colors[i].join("") is colorString
            i++
          voxels.push
            x: current.x
            y: current.y + 1
            z: current.z
            c: current.c + 1

          code = 0
          code += 1000  unless current.x is last.x
          code += 100  unless current.y is last.y
          code += 10  unless current.z is last.z
          code += 1  unless current.c is last.c
          code += 10000
          data.push parseInt(code, 2)
          unless current.x is last.x
            data.push current.x - last.x + 32
            last.x = current.x
          unless current.y is last.y
            data.push current.y - last.y + 32
            last.y = current.y
          unless current.z is last.z
            data.push current.z - last.z + 32
            last.z = current.z
          unless current.c is last.c
            data.push current.c - last.c + 32
            last.c = current.c
      data = encode(data)
      animationFrames[currentFrame] = data
      cData = ""

      # ignore color data
      # for (var i = 0; i < colors.length; i++){
      #   cData += ColorUtils.rgb2hex(colors[i]);
      # }
      outHash = "#" + ((if cData then ("C/" + cData) else ""))
      i = 0

      while i < animationFrames.length
        if i is 0
          outHash = outHash + ":A/" + animationFrames[i]
        else
          outHash = outHash + ":A" + i + "/" + animationFrames[i]
        i++

      # hack to ignore programmatic hash changes
      window.updatingHash = true
      window.location.replace outHash

      # Update the Play Level link
      $(".play-level").attr "href", "http://philschatz.com/game/" + outHash
      setTimeout (->
        window.updatingHash = false
        return
      ), 1
      voxels


    buildFromHash: (colors) ->
      hashMask = null
      hash = window.location.hash.substr(1)
      hashChunks = hash.split(":")
      chunks = {}
      animationFrames = []
      j = 0
      n = hashChunks.length

      while j < n
        chunk = hashChunks[j].split("/")
        chunks[chunk[0]] = chunk[1]
        animationFrames.push chunk[1]  if chunk[0].charAt(0) is "A"
        j++
      if (not hashMask or hashMask is "C") and chunks["C"]

        # decode colors
        hexColors = chunks["C"]
        c = 0
        nC = hexColors.length / 6

        while c < nC
          hex = hexColors.substr(c * 6, 6)
          colors[c] = ColorUtils.hex2rgb(hex)
          addColorToPalette c
          c++
      frameMask = "A"
      if (not hashMask or hashMask is frameMask) and chunks[frameMask]

        # decode geo
        current =
          x: 0
          y: 0
          z: 0
          c: 0

        data = decode(chunks[frameMask])
        i = 0
        l = data.length
        while i < l
          code = data[i++].toString(2)
          current.x += data[i++] - 32  if code.charAt(1) is "1"
          current.y += data[i++] - 32  if code.charAt(2) is "1"
          current.z += data[i++] - 32  if code.charAt(3) is "1"
          current.c += data[i++] - 32  if code.charAt(4) is "1"
          SceneManager.addVoxel current.x * 50 + 25, current.y * 50 + 25, current.z * 50 + 25, colors[current.c]  if code.charAt(0) is "1"
      @updateHash(colors)
      return
