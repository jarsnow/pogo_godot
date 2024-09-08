extends RigidBody2D

signal ground_player
signal unground_player

var grounded: bool = false
var boosted: bool = false
var currently_colliding_ground: bool = false

var rotation_before_jump: float = 0

var y_velocity_before_ground: float = 0

var last_touched_ground_normal: Vector2 = Vector2.ZERO

# the force at which a full power jump propels the player
@export var base_jump_power: int = 500

# the float that is multiplied to the bonus jump boost difference
@export var jump_boost_dampening: float = 0.9
@export var rotation_power: int = 40000

# used to determine the 

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
		unground()
		
	
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
	
	# handle jumps, three cases, auto, half, or full jump
	if ((grounded and $AutoJumpTimer.is_stopped()) and # a jump is available
		(not Input.is_action_pressed("jump") or # checks for auto jumps or manually released jumps
		$PlayerJumpTimer.is_stopped())): # checks for a fully charged jump
			
		jump()
		
	

# TODO: take into consideration the angle of the floor the player is on at the time of the jump
# TODO: implement jump dampening
# should push the player in that direction slightly
# jump power can be modified by three variables:
#	impact velocity
#	whether the player has a charge
#	how long the player has held the jump button for (up to a certain point)
func jump():
	var local_up = Vector2.UP.rotated(rotation)
	
	# elapsed 
	
	# mid section represents the set section of time left after the autojump timer has stopped
	var player_timer_midsection = $PlayerJumpTimer.wait_time - $AutoJumpTimer.wait_time
	
	# midsection_elapsed represents the amount of real time passed since the autojump timer has passed
	var midsection_elapsed = player_timer_midsection - $PlayerJumpTimer.time_left
	
	# force for an autojump
	const auto_jump_multiplier = 0.5
	
	# linearly increases until 1 
	const manual_jump_y_intercept = 0.5
	const manual_jump_slope = 1 - manual_jump_y_intercept
	
	const boost_multiplier = 1.3
	const full_jump_multiplier = 1.2
	
	var jump_multiplier = 1
	
	if (midsection_elapsed < 0.05): # check for autojump, 0.05 is just a small number to help pick between auto and manual
		jump_multiplier = auto_jump_multiplier
	elif ($PlayerJumpTimer.is_stopped()): # check for full jump
		if (boosted):
			jump_multiplier = boost_multiplier
		else:
			jump_multiplier = full_jump_multiplier
	else:
		# equation to find the force of a partially charged jump
		var progress_ratio = midsection_elapsed / player_timer_midsection
		jump_multiplier = manual_jump_slope * progress_ratio + manual_jump_y_intercept
		
	unground()
	
	var jump_force = base_jump_power * jump_multiplier
	# use impulse, as it is frame independent (should only be applied once)
	apply_central_impulse(local_up * jump_force)
	
func _physics_process(delta):
	handle_input(delta)
	
	# keep track of y velocity, used for jumping and bonk
	if !grounded:
		y_velocity_before_ground = linear_velocity.y
		
	# sometimes the player will hit the ground again before the bonk cooldown is over
	# when the timer has just ended, check if the player is on the ground
	# if so, bonk the player
	if $BonkCooldown.is_stopped() and currently_colliding_ground and !grounded:
		bonk()
	

func handle_grounded_change(colliding_shape:String, is_jump=false):
	
	# normal bonk (was in air and then body hit the ground)
	if (currently_colliding_ground and !grounded and colliding_shape == "body"):
		bonk()
		return
	
	# grounded bonk (was grounded / charging a jump and then the body hit the ground)
	if (grounded and (colliding_shape == "body")):
		bonk()
		return
		
	# go from ungrounded to grounded
	# emit signal to attach player to the ground
	if colliding_shape == "pogo":
		ground()
	else:
		unground()

func ground():
	grounded = true
	# reset timers
	$AutoJumpTimer.start()
	$PlayerJumpTimer.start()
	
	# change center of mass
	set_center_of_mass($FootPoint.get_position())
	
	# disable the hitbox for the pogo
	#$PogoHitbox.set_deferred("disabled", true)
	set_gravity_scale(0)
	
	emit_signal("ground_player")

func unground():
	grounded = false
	# stop autojumptimer
	$AutoJumpTimer.stop()
	$PlayerJumpTimer.stop()
	
	#$PogoHitbox.set_deferred("disabled", false)
	set_gravity_scale(0.7)
	
	# change center of mass
	set_center_of_mass($BodyHitbox.get_position())
	
	# bounce the player off the ground
	
	#last_touched_ground_normal = Vector2.ZERO
	
	emit_signal("unground_player")
	
# TODO: make bonk force scale with velocity before impact
# TODO: set a slight cooldown for being able to bonk 
func bonk():
	unground()
	
	if $BonkCooldown.is_stopped():
		const bonk_force = 300
		
		# apply bonk force
		apply_central_impulse(bonk_force * last_touched_ground_normal)
		
		$BonkCooldown.start()

# is called when there is a new collision
func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	# local_shape_index returns the index of the child CollisionShape2D that was last collided
	# local_shape_index = 0 -> body collision
	# local_shape_index = 1 -> pogo collision
	
	var colliding_shape = ""
	if local_shape_index == 0:
		colliding_shape = "body"
	elif local_shape_index == 1:
		colliding_shape = "pogo"
	else:
		printerr("what is colliding here?")
		
	handle_grounded_change(colliding_shape)
	
func _integrate_forces(state):
	
	if state.get_contact_count() > 0:
		currently_colliding_ground = true
		var normal_vector = state.get_contact_local_normal(0)
	
		if normal_vector != Vector2.ZERO:
			last_touched_ground_normal = normal_vector
	else:	
		currently_colliding_ground = false
