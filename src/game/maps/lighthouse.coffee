fromHash = require './from-hash'

hash =  ':A/aWpaieaePaiiaiiammaiiakkaiiaSdaoYakcaieaXoShahfbbhhYhShYfShYhShYfShYhYhSfYhShYhSfYhShYhSfYhShYhSfYhShSeYfSfYhSfYfSfYhSfYfSfYhSfYfahfYfYfShYfSfYfShYfSfYfShYfSfYfShYfSfSiYhShYfShYhWhhYfYfShYhYhShYfYfShYhYhShYfYfShYhYhYhSfSfYhShShYhSfSfYhShShYhSfaihSfSfahhSfaffYhSfYfSfYhaffYhaffYhaffYhSfYfahfYfafhSfYfShYfSfYfShYfSfYfShaffShaffSiafeahhYfaihYeaihShYfSfYfShaqmfYhbiShShYhYhYhYhYhYhaadSfSfSfamlSfSfSfSfabfYhYhYhYhYhcahShShShShShShYhYhYhYhYhYhSfSfSfSfSfSfYfYfYfYfYfbeifSfSfSfSfahhSfahhSfajhSfahhSfahhSfahhSfSiShShSkShShffeffShShafefhihhSfYcShaffShaffShafeShShUhSfSfbhfhSfSfbfffSfSfSfSfYhYhYjYhYhYhaahYhYhYhaefYhakhShShShShShShShShShaffShbfehYfThfShaffShYfYfYfcfhSfSfSfSfSfSfSfSfSfSfYhYhYhYhYhYhYhYhShShShShShShShShShShaffYfahhYfYfYfYfYfYfbfhfShYfSfSfSeSfSfSbSfSfYhYhYmaXtSfSfSeSfSfSbSfSfYoajhSfYhafiShSkShShShShShShYhaefShaffShaffShaffShadfShaffShddhjSfSfSfSfSfSfSfSfSfSfSfSfSfYhYhYhYhYhYhYhYhYhYhYhYhYhShShShShShShShShShShShShShYfYfYfYfYfYfYfYfYfYfYfYfSfSfSfSfSfSfSfSfSfSfSfSfahrSfSfSfSfSfSfSfSfSfSfSfahrSfSfSfSfSfSfSfSfSfSfSffaalcYhYhShYfYfappYhfYmVmYfYfYfTfhVheVeiUfUfUfUfUfUfUfdcpefjfhhYfYfYfXYfhUhUhUhUhUhUhUhUhccYUhUhUhUhUhUhUhUhVhefjfhhYfYfYfShYhYhYhYhYhYhYhYhYhYhYhShYfYfYfYfYfYfYfYfYfYfYffoYihUhUhUhUhUhUhUhUhVhedcXiUhUhUhUhUhUhUhUhVhedcYiUfUiUhUhUhUhUhUhVheXZhbShShShShShShShShShShShShShYfYfYfYfYfUhUhUhUhVikShShShShShXfbdShShShShShfehbjYfYfYfdkfdYfYeYfajhZfhUfYhYhYdajhYfYfYfajhYeYfajhYeYffiffhYfahfYfehhhfehffbfffbhihZffShShYkYfYfYfffhcjYhYhYhYhShYfYfYfYfShYhYhYhYhShYfYfYfYfShYhYhYhYhfehekVhhVhhfiddabmRiYhYhYhYhYhYhYhYhYhYhYhblkeSfSfSfSfSfSfSfSfSfSfSfYhShShShShShShShShShShShahVShShShShShShShShShShShYhSfSfSfSfSfSfSfSfSfSfSfYhShShShShShShShShShShShYhSfSfSfSfSfSfSfSfSfSfSfYhShShShShShShShShShShShYhSfSfSfSfSfSfSfSfSfSfSfYhShShShShShShShShShShShfahZnYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShShXhhhYfYfYfSfSfSfYhYhYhShShXhhfYfYfYfSfSfSfYhYhYhShSh'


collisionTypes = [
  null
  null
  null
  null
  'top'
  'top'
  'top'
  null
  null
  null
  'top'
  null
  null
  null
]

textures = [
  'stone' # This one should never be used since it is the black
  ['grass', 'grass', 'square-light-pyramid-in'] # ['grass', 'dirt', 'grass_dirt'],
  'square-medium-pyramid-in'
  'square-dark-pyramid-in'
  ['grass', 'grass', 'square-grasstop-light-pyramid-out']
  'bridge-post-top'
  'bridge'
  'bridge-post-1'
  'obelisk-3'
  'obelisk-2'
  'obelisk-1'
  'lighthouse-red'
  'lighthouse-white'
]

textureVariants = [
  null
  ['square-light-pyramid-in', 'square-light-pyramid-out', 'square-light-square-in', 'square-light-square-out']
  ['square-medium-pyramid-in', 'square-medium-pyramid-out', 'square-medium-square-in', 'square-medium-square-out']
  ['square-dark-pyramid-in', 'square-dark-pyramid-out', 'square-dark-square-big', 'square-dark-square-in']
  ['square-grasstop-light-pyramid-out', 'square-grasstop-light-square-out']
  null
  null
  ['bridge-post-1', 'bridge-post-2']
]

textureVariants = []


textureVariantColors = []
newColor = textures.length
for variantNames, origColor in textureVariants
  if variantNames
    textureVariantAry = []
    for variantName in variantNames
      textures.push(variantName)
      textureVariantAry.push(newColor)
      newColor++

    textureVariantColors.push(textureVariantAry)
  else
    textureVariantColors.push(null)

playerPosition = [1, 7, 3]

variantMapper = (c) ->
  # Generates variants randomly
  variants = textureVariantColors[c]
  return c unless variants
  return variants[Math.floor(Math.random() * variants.length)]


module.exports =
  textures: textures
  build: () ->

    map = fromHash(hash, variantMapper)
    {map, textures, collisionTypes, playerPosition}
