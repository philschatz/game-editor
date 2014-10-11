PlayerManager = require './actions/player-manager'

max = Math.max
min = Math.min
sin = Math.sin
abs = Math.abs
floor = Math.floor
PI = Math.PI

clamp = (value, to) ->
  if isFinite(to) then max(min(value, to), -to) else value


# From voxel-control but changed forward to mean up in the y axis (not z)
# Also, when climbing, gravity does not apply
module.exports = tick = (dt) ->
  return  unless @_target
  state = @state
  target = @_target
  speed = @speed
  jump_speed = @jump_speed

  if PlayerManager.isClimbing()
    target.resting.y = true

  okay_z = abs(target.velocity.z) < @max_speed
  okay_x = abs(target.velocity.x) < @max_speed
  at_rest = target.atRestY()
  return  unless @_target
  @z_accel_timer = max(0, @z_accel_timer - dt)  if state.forward or state.backward
  if state.backward
    target.velocity.y = -@max_speed
  else if state.forward
    target.velocity.y = @max_speed
  else
    @z_accel_timer = @accel_max_timer
  @x_accel_timer = max(0, @x_accel_timer - dt)  if state.left or state.right
  if state.right
    target.velocity.x = max(min(@max_speed, speed * dt * @acceleration(@x_accel_timer, @accel_max_timer)), target.velocity.x)  if target.velocity.x < @max_speed
  else if state.left
    target.velocity.x = min(max(-@max_speed, -speed * dt * @acceleration(@x_accel_timer, @accel_max_timer)), target.velocity.x)  if target.velocity.x > -@max_speed
  else
    @x_accel_timer = @accel_max_timer
  if state.jump
    if not @jumping and not at_rest
      # we're falling, we can't jump
    else if at_rest > 0
      # we hit our head
      @jumping = false
    else
      @jumping = true
      target.velocity.y = min(target.velocity.y + jump_speed * min(dt, @jump_timer), @jump_max_speed)  if @jump_timer > 0
      @jump_timer = max(@jump_timer - dt, 0)
  else
    @jumping = false
  @jump_timer = (if at_rest < 0 then @jump_max_timer else @jump_timer)
  can_fire = true
  if state.fire or state.firealt
    if @firing and @needs_discrete_fire
      @firing += dt
    else
      @onfire state  if not @fire_rate or floor(@firing / @fire_rate) isnt floor((@firing + dt) / @fire_rate)
      @firing += dt
  else
    @firing = 0
  x_rotation = @state.x_rotation_accum * @rotation_scale
  y_rotation = @state.y_rotation_accum * @rotation_scale
  z_rotation = @state.z_rotation_accum * @rotation_scale
  pitch_target = @_pitch_target
  yaw_target = @_yaw_target
  roll_target = @_roll_target
  pitch_target.rotation.x = clamp(pitch_target.rotation.x + clamp(x_rotation, @x_rotation_per_ms), @x_rotation_clamp)
  yaw_target.rotation.y = clamp(yaw_target.rotation.y + clamp(y_rotation, @y_rotation_per_ms), @y_rotation_clamp)
  roll_target.rotation.z = clamp(roll_target.rotation.z + clamp(z_rotation, @z_rotation_per_ms), @z_rotation_clamp)
  @emitUpdate()  if @listeners("data").length
  @state.x_rotation_accum = @state.y_rotation_accum = @state.z_rotation_accum = 0
  return
