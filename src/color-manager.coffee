ColorUtils = require './color-utils'

colors = [
  '000000'
  '2ECC71'
  '3498DB'
  '34495E'
  'E67E22'
  'ECF0F1'
  'FFF500'
  'FF0000'
  '00FF38'
  'BD00FF'
  '08c9ff'
  'D32020'
].map((c) ->
  ColorUtils.hex2rgb c
)


module.exports = {
  colors: colors
  currentColor: 0
}
