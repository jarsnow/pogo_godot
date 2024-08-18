extends Node2D

# used to attach the player to the ground
var pin_joint
var pin_helper

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# connect ground / unground of the player to functions in the main script
	$Player.ground_player.connect(_on_player_ground)
	$Player.unground_player.connect(_on_player_unground)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_ground():
	print("grounded!")
	
	# attach player to ground
	pin_joint = PinJoint2D.new()
	add_child(pin_joint)
	
	pin_joint.position = $Player/FootPoint.position
	
	# make a temporary rigidbody 2d to attach
	pin_helper = StaticBody2D.new()
	add_child(pin_helper)
	
	
func _on_player_unground():
	print("ungrounded!")
	
