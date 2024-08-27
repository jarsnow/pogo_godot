extends RigidBody2D

signal ground_player
signal unground_player

var grounded: bool = false

var rotation_before_jump: float = 0

var y_velocity_before_ground: float = 0

# the force at which a full power jump propels the player
@export var jump_power: int = 500

# the float that is multiplied to the bonus jump boost difference
@export var jump_boost_dampening: float = 0.9
@export var rotation_power: int = 40000

# Called when the node enters the scene tree for the first time.
func _ready():
	grounded = false
	emit_signal("unground_player")
	
	# set to true in order to differentiate between body/pogo collisions
	# max_contacts_reported needs to also be >= 1
	contact_monitor = true
	max_contacts_reported = 2
	
	# set center of mass mode to custom, so that it will be the origin point (center of player body) by default
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	
	# set timer nodes to adhere to physics time, instead of process time
	$AutoJumpTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	$PlayerJumpTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	
	# set angular dampening here because it doesn't work in the inspector
	set_angular_damp(10)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# test reset
	if Input.is_action_just_pressed("reset"):
		handle_grounded_change(true)
		
	#print($AutoJumpTimer.time_left)
	
func handle_input(delta):
	# check for body collision if grounded OR
	# check for body and pogo collision if ungrounded
	
	# rotation
	var turn_dir = 0
	if Input.is_action_pressed("turn_clockwise"):
		turn_dir += 1
	if Input.is_action_pressed("turn_counterclockwise"):
		turn_dir -= 1
	
	turn_dir *= rotation_power
	apply_torque(turn_dir) 
	

	if grounded:
		# manual jump
		if Input.is_action_just_released("jump"):
			jump(jump_power)
			
		# auto jump
		elif ($AutoJumpTimer.is_stopped() and not Input.is_action_pressed("jump")):
			#
			jump(jump_power * 0.55)
		# jump
		
	return
	

# TODO: take into consideration the angle of the floor the player is on at the time of the jump
# should push the player in that direction slightly
func jump(force):
	var local_up = Vector2.UP.rotated(rotation)
	handle_grounded_change(false)
	
	# use impulse, as it is frame independent (should only be applied once)
	apply_central_impulse(local_up * force)
	
func _physics_process(delta):
	handle_input(delta)
	
	if !grounded:
		y_velocity_before_ground = linear_velocity.y
	

func handle_grounded_change(new_grounded):
	
	# there actually is no grounded change, do nothing
	if grounded == new_grounded:
		return
	
	# emit signal to attach player to the ground
	if new_grounded:
		# ground
		print(y_velocity_before_ground)
		# reset timers
		$AutoJumpTimer.start()
		$PlayerJumpTimer.start()
		
		# change center of mass
		set_center_of_mass($FootPoint.get_position())
		
		# disable the hitbox for the pogo
		#$PogoHitbox.set_deferred("disabled", true)
		set_gravity_scale(0)
		
		emit_signal("ground_player")
	else:
		# unground
		
		# stop autojumptimer
		$AutoJumpTimer.stop()
		$PlayerJumpTimer.stop()
		
		#$PogoHitbox.set_deferred("disabled", false)
		set_gravity_scale(0.7)
		
		# change center of mass
		set_center_of_mass($BodyHitbox.get_position())
		
		emit_signal("unground_player")
	
	# update player
	grounded = new_grounded

# is called when there is a new collision
func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	# local_shape_index returns the index of the child CollisionShape2D that was last collided
	# local_shape_index = 0 -> body collision
	# local_shape_index = 1 -> pogo collision
	handle_grounded_change(local_shape_index == 1)
