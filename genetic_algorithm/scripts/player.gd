extends RigidBody2D

signal ground_player
signal unground_player

# information used for functions of the player
var grounded: bool = false
var boosted: bool = false
var currently_colliding_ground: bool = false
var rotation_for_boost: float = 0
var y_velocity_before_ground: float = 0
var last_touched_ground_normal: Vector2 = Vector2.ZERO
var last_rotation: float = 0

var fitness: float = 0
var engine_frame_created: int = 0
var boosted_jump_count: int = 0

# the force at which a full power jump propels the player
@export var base_jump_power: int = 500

# the float that is multiplied to the bonus jump boost difference
@export var rotation_power: int = 40000

var chromosome: String = ""
var max_path_dist = 0

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
	
	engine_frame_created = Engine.get_physics_frames()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	$ChargedPogoVFX.set_emitting(boosted)
		
	
func handle_input(delta):
	# check for body collision if grounded OR
	# check for body and pogo collision if ungrounded
	
	# read each gene from chromosome
	var index = Engine.get_physics_frames() - engine_frame_created
	
	if index >= chromosome.length():
		printerr("game has ran longer than chromosome length")
		return
	
	# can either be L, R, N
	# for LEFT, RIGHT, or NO rotation
	var gene = chromosome[index] 
	
	# rotation
	var turn_dir = 0
	
	if gene == "r":
		turn_dir = 1
	elif gene == "l":
		turn_dir = -1
	elif gene == "n":
		turn_dir = 0
	else:
		printerr("invalid gene in chromosome!")
	
	turn_dir *= rotation_power
	apply_torque(turn_dir) 
	
	# assume jump is always pressed for easy chromosome analysis

	# handle jumps, three cases, auto, half, or full jump
	if ((grounded and $AutoJumpTimer.is_stopped()) and # a jump is available
		($PlayerJumpTimer.is_stopped())): # checks for a fully charged jump
		
		jump()

# TODO: implement jump dampening
# should push the player in that direction slightly
# jump power can be modified by three variables:
#	impact velocity
#	whether the player has a charge
#	how long the player has held the jump button for (up to a certain point)
func jump():
	var local_up = Vector2.UP.rotated(rotation)
	
	# mid section represents the set section of time left after the autojump timer has stopped
	var player_timer_midsection = $PlayerJumpTimer.wait_time - $AutoJumpTimer.wait_time
	
	# midsection_elapsed represents the amount of real time passed since the autojump timer has passed
	var midsection_elapsed = player_timer_midsection - $PlayerJumpTimer.time_left
	
	# force for an autojump
	const auto_jump_multiplier = 0.5
	
	# linearly increases until 1 
	const manual_jump_y_intercept = 0.5
	const manual_jump_slope = 1 - manual_jump_y_intercept
	
	const boost_multiplier = 1.4
	const full_jump_multiplier = 1.1
	
	var jump_multiplier = 1
	
	if (midsection_elapsed < 0.05): # check for autojump, 0.05 is just a small number to help pick between auto and manual
		jump_multiplier = auto_jump_multiplier
	elif ($PlayerJumpTimer.is_stopped()): # check for full jump
		if (boosted):
			jump_multiplier = boost_multiplier
			boosted_jump_count += 1
		else:
			jump_multiplier = full_jump_multiplier
	else:
		# equation to find the force of a partially charged jump
		var progress_ratio = midsection_elapsed / player_timer_midsection
		jump_multiplier = manual_jump_slope * progress_ratio + manual_jump_y_intercept
		
	boosted = false
	
	unground()
	
	var jump_force = base_jump_power * jump_multiplier
	
	# calculate the realistic resulting force vector of pushing off a sloped surface
	# add the normalized vectors of local up and the ground's normal vector
	# then apply the force in that direction
	
	# represents how much more the player's local upwards direction should be
	# taken into consideration over the ground normal vector
	const player_jump_bias = 2
	var jump_dir: Vector2 = player_jump_bias * local_up.normalized() + last_touched_ground_normal.normalized()
	jump_dir = jump_dir.normalized()
	
	# use impulse, as it is frame independent (should only be applied once)
	apply_central_impulse(jump_dir * jump_force)
	
func _physics_process(delta):
	handle_input(delta)
	
	# keep track of y velocity, used for jumping and bonk
	if !grounded:
		y_velocity_before_ground = linear_velocity.y
	
	# check if the player should recieve a boost
	rotation_for_boost += angle_difference(last_rotation, rotation)
	last_rotation = rotation
	
	if(abs(rotation_for_boost) >= PI * (3/2)):
		boosted = true

func handle_grounded_change(colliding_shape:String, is_jump=false):
	
	# normal bonk (was in air and then body hit the ground)
	# or grounded bonk (was grounded / charging a jump and then the body hit the ground)
	if (currently_colliding_ground and !grounded and colliding_shape == "body") or (grounded and colliding_shape == "body"):
		bonk()
		return
		
	# set a cooldown on attaching the player to the ground after bonking
	if (colliding_shape == "pogo" and $BonkCooldown.is_stopped()):
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
	
	# set value for rotation boost
	rotation_for_boost = 0
	
	# set rotational velocity to zero
	angular_velocity = 0
	
	# don't have gravity, makes turning weird
	set_gravity_scale(0)
	
	# move joint and anchor to the foot position
	get_node("../PlayerPinJoint").set_global_position($FootPoint.get_global_position())
	get_node("../FootAnchor").set_global_position($FootPoint.get_global_position())
	
	# renable pin joint
	get_node("../PlayerPinJoint").set_node_a(NodePath("../Player"))
	get_node("../PlayerPinJoint").set_node_b(NodePath("../FootAnchor"))

func unground():
	grounded = false
	# stop autojumptimer
	$AutoJumpTimer.stop()
	$PlayerJumpTimer.stop()
	
	set_gravity_scale(0.7)
	
	# change center of mass
	set_center_of_mass($BodyHitbox.get_position())
	
	# disable the pin joint for the player
	get_node("../PlayerPinJoint").set_node_a(NodePath(""))
	get_node("../PlayerPinJoint").set_node_b(NodePath(""))
	
# TODO: make bonk force scale with velocity before impact
func bonk():
	unground()
	
	if $BonkCooldown.is_stopped():
		const bonk_force = 350
		
		# apply rotational force
		const torque_mult = 1250
		const torque_min = 5000
		
		# rotate 
		var torque_power = -torque_mult * rotation
		
		if(rotation > 0):
			torque_power -= torque_min
		else:
			torque_power += torque_min
			
		# apply force and torque
		# there is an issue where jumping and bonking at around the same time
		# launches the player further than normal, so reset velocity before bonking
		linear_velocity = Vector2.ZERO
		apply_central_impulse(bonk_force * last_touched_ground_normal)
		apply_torque_impulse(torque_power)
		
		# reset the rotation for charge
		rotation_for_boost = 0
		boosted = false
		
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
