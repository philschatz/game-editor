THREE = require '../../three'
PlayerManager = require '../actions/player-manager'
aabb = require 'aabb-3d'

physical = (avatar, collidables, dimensions, terminal) ->
  new Physical(avatar, collidables, dimensions, terminal)
Physical = (avatar, collidables, dimensions, terminal) ->
  @avatar = avatar
  @terminal = terminal or new THREE.Vector3(30, 5.6, 30)
  @dimensions = dimensions = dimensions or [1, 1, 1]
  @_aabb = aabb([0, 0, 0], dimensions)
  @resting =
    x: false
    y: false
    z: false

  @collidables = collidables
  @friction = new THREE.Vector3(1, 1, 1)
  @rotation = @avatar.rotation
  @default_friction = 1

  # default yaw/pitch/roll controls to the avatar
  @yaw = @pitch = @roll = avatar
  @forces = new THREE.Vector3(0, 0, 0)
  @attractors = []
  @acceleration = new THREE.Vector3(0, 0, 0)
  @velocity = new THREE.Vector3(0, 0, 0)
  return @


# make these *once*, so we're not generating
# garbage for every object in the game.
applyTo = (which) ->
  (world) ->
    local = @avatar.worldToLocal(world)
    this[which].x += local.x
    this[which].y += local.y
    this[which].z += local.z
    return
module.exports = physical
cons = Physical
proto = cons::
axes = ['x', 'y', 'z']
abs = Math.abs
WORLD_DESIRED = new THREE.Vector3(0, 0, 0)
DESIRED = new THREE.Vector3(0, 0, 0)
START = new THREE.Vector3(0, 0, 0)
END = new THREE.Vector3(0, 0, 0)
DIRECTION = new THREE.Vector3()
LOCAL_ATTRACTOR = new THREE.Vector3()
TOTAL_FORCES = new THREE.Vector3()
proto.applyWorldAcceleration = applyTo('acceleration')
proto.applyWorldVelocity = applyTo('velocity')
proto.tick = (dt) ->
  forces = @forces
  acceleration = @acceleration
  velocity = @velocity
  terminal = @terminal
  friction = @friction
  desired = DESIRED
  world_desired = WORLD_DESIRED
  bbox = undefined
  pcs = undefined
  TOTAL_FORCES.multiplyScalar 0
  desired.x = desired.y = desired.z = world_desired.x = world_desired.y = world_desired.z = 0
  i = 0

  while i < @attractors.length
    distance_factor = @avatar.position.distanceToSquared(@attractors[i])
    LOCAL_ATTRACTOR.copy @attractors[i]
    LOCAL_ATTRACTOR = @avatar.worldToLocal(LOCAL_ATTRACTOR)
    DIRECTION.sub LOCAL_ATTRACTOR, @avatar.position
    DIRECTION.divideScalar DIRECTION.length() * distance_factor
    DIRECTION.multiplyScalar @attractors[i].mass
    TOTAL_FORCES.addSelf DIRECTION
    i++
  unless @resting.x
    acceleration.x /= 8 * dt
    acceleration.x += TOTAL_FORCES.x * dt
    acceleration.x += forces.x * dt
    velocity.x += acceleration.x * dt
    velocity.x *= friction.x
    if abs(velocity.x) < terminal.x
      desired.x = (velocity.x * dt)
    else desired.x = (velocity.x / abs(velocity.x)) * terminal.x  if velocity.x isnt 0
  else
    acceleration.x = velocity.x = 0
  unless @resting.y
    acceleration.y /= 8 * dt
    acceleration.y += TOTAL_FORCES.y * dt
    acceleration.y += forces.y * dt

    if PlayerManager.isClimbing()
      acceleration.y = 0

    velocity.y += acceleration.y * dt
    velocity.y *= friction.y
    if abs(velocity.y) < terminal.y
      desired.y = (velocity.y * dt)
    else desired.y = (velocity.y / abs(velocity.y)) * terminal.y  if velocity.y isnt 0
  else
    acceleration.y = velocity.y = 0
  unless @resting.z
    acceleration.z /= 8 * dt
    acceleration.z += TOTAL_FORCES.z * dt
    acceleration.z += forces.z * dt
    velocity.z += acceleration.z * dt
    velocity.z *= friction.z
    if abs(velocity.z) < terminal.z
      desired.z = (velocity.z * dt)
    else desired.z = (velocity.z / abs(velocity.z)) * terminal.z  if velocity.z isnt 0
  else
    acceleration.z = velocity.z = 0

  # Make sure we never fall/move too fast for the collision detector
  desired.x = 1 if desired.x > 1
  desired.x = -1 if desired.x < -1
  desired.y = 1 if desired.y > 1
  desired.y = -1 if desired.y < -1
  desired.z = 1 if desired.z > 1
  desired.z = -1 if desired.z < -1


  START.copy @avatar.position
  @avatar.translateX desired.x
  @avatar.translateY desired.y
  @avatar.translateZ desired.z
  END.copy @avatar.position
  @avatar.position.copy START
  world_desired.x = END.x - START.x
  world_desired.y = END.y - START.y
  world_desired.z = END.z - START.z
  @friction.x = @friction.y = @friction.z = @default_friction

  # run collisions
  @resting.x = @resting.y = @resting.z = false
  bbox = @aabb()
  pcs = @collidables
  i = 0
  len = pcs.length

  while i < len
    pcs[i].collide this, bbox, world_desired, @resting  if pcs[i] isnt this
    ++i

  # apply translation
  @avatar.position.x += world_desired.x
  @avatar.position.y += world_desired.y
  @avatar.position.z += world_desired.z
  return

proto.subjectTo = (force) ->
  @forces.x += force[0]
  @forces.y += force[1]
  @forces.z += force[2]
  this

proto.attractTo = (vector, mass) ->
  vector.mass = mass
  @attractors.push vector
  return

proto.aabb = ->
  aabb [
    @avatar.position.x
    @avatar.position.y
    @avatar.position.z
  ], @dimensions


# no object -> object collisions for now, thanks
proto.collide = (other, bbox, world_vec, resting) ->
  return

proto.atRestX = ->
  @resting.x

proto.atRestY = ->
  @resting.y

proto.atRestZ = ->
  @resting.z
