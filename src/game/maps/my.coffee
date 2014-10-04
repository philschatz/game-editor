lighthouseMap = require("./lighthouse")
mapFromHash = require("./from-hash")
if window.location.hash.length > 2
  mapInfo =
    map: mapFromHash()
    textures: lighthouseMap.textures
else
  mapInfo = lighthouseMap.build()

module.exports = mapInfo
