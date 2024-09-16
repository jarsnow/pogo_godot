extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# change the alpha value of the background
	$Background.modulate.a = 0.2
	
	# assign collision to the map
	for map_polygon:Polygon2D in $CollisionMap.get_children():
		
		# create the children nodes for the polygon
		var static_body = StaticBody2D.new()
		var collision_shape = CollisionPolygon2D.new()
		
		# link collision shape to static body
		static_body.add_child(collision_shape)
		
		# copy the current polygon shape over to the collision polygon
		collision_shape.set_polygon(map_polygon.get_polygon())
		
		# add static body to map tile
		map_polygon.add_child(static_body)
		

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
