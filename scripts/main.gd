extends Node2D

# used to attach the player to the ground
var pin_joint
var pin_helper

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass	

func _on_player_ground_player():
	# move joint and anchor to the foot position
	$PlayerPinJoint.set_global_position($Player/FootPoint.get_global_position())
	$FootAnchor.set_global_position($Player/FootPoint.get_global_position())
	
	# renable pin joint
	$PlayerPinJoint.set_node_a(NodePath("../Player"))
	$PlayerPinJoint.set_node_b(NodePath("../FootAnchor"))

func _on_player_unground_player():	
	# disable the pin joint for the player
	$PlayerPinJoint.set_node_a(NodePath(""))
	$PlayerPinJoint.set_node_b(NodePath(""))
