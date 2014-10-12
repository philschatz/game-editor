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
