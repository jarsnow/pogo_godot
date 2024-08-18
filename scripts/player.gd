extends RigidBody2D

signal ground_player
signal unground_player

var grounded: bool = false
@export var jump_power: int = 500
@export var rotation_power: int = 200000

# Called when the node enters the scene tree for the first time.
func _ready():
	grounded = false
	
	# set to true in order to differentiate between body/pogo collisions
	# max_contacts_reported needs to also be >= 1
	
	contact_monitor = true
	max_contacts_reported = 2
	
	# set center of mass mode to custom, so that it will be the origin point (center of player body) by default
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func handle_input(delta):
	# check for body collision if grounded OR
	# check for body and pogo collision if ungrounded
	
	
	if grounded:
		# jump
		var local_up = Vector2.UP.rotated(rotation)
		if (Input.is_action_just_released("jump")):
			# use impulse, as it is frame independent (should only be applied once)
			handle_grounded_change(false)
			apply_central_impulse(local_up * jump_power)
	return
	
func _physics_process(delta):
	handle_input(delta)
	
	

func handle_grounded_change(new_grounded):
	# there actually is no grounded change, do nothing
	if grounded == new_grounded:
		return
	
	# emit signal to attach player to the ground
	if new_grounded:
		emit_signal("ground_player")
	else:
		emit_signal("unground_player")
	
	# update player
	grounded = new_grounded

# is called when there is a new collision
func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	# local_shape_index returns the index of the child CollisionShape2D that was last collided
	# local_shape_index = 0 -> body collision
	# local_shape_index = 1 -> pogo collision
	handle_grounded_change(local_shape_index == 1)
