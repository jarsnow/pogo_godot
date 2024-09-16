extends Node2D

const agent_count: int = 1
const chromosome_length: int = 60 * 20
const gene_choices = ['l', 'r', 'n']

const Player = preload("res://scenes/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# change the alpha value of the background
	$Background.modulate.a = 0.2
	
	initialize_map_collision()
	
	initialize_agents()
	
	
# assign collision to the map
func initialize_map_collision():
	
	for map_polygon in $CollisionMap.get_children():
		# skip over the path node
		if map_polygon.get_class() != "Polygon2D":
			continue
			
		# create the children nodes for the polygon
		var static_body = StaticBody2D.new()
		var collision_shape = CollisionPolygon2D.new()
		
		# link collision shape to static body
		static_body.add_child(collision_shape)
		
		# copy the current polygon shape over to the collision polygon
		collision_shape.set_polygon(map_polygon.get_polygon())
		
		# add static body to map tile
		map_polygon.add_child(static_body)
	
	
func initialize_agents():
	for i in range(agent_count):
		
		var new_agent = Player.instantiate()
		generate_new_chromosome(new_agent)
		
		add_child(new_agent)

func generate_new_chromosome(agent):
	
	var new_chromosome: String = ""
	for i in range(chromosome_length):
		new_chromosome = new_chromosome + gene_choices.pick_random()
		
	agent.get_node("Player").chromosome = new_chromosome
	
func get_agent_score(agent):
	var path: Path2D = $CollisionMap/Path2D
	var agent_pos: Vector2 = agent.get_global_position()
	var closestOffset = path.curve.get_closest_offset(path.to_local(agent_pos))

func select_surviving_agents():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_ground_player():
	## move joint and anchor to the foot position
	#$PlayerPinJoint.set_global_position($Player/FootPoint.get_global_position())
	#$FootAnchor.set_global_position($Player/FootPoint.get_global_position())
	#
	## renable pin joint
	#$PlayerPinJoint.set_node_a(NodePath("../Player"))
	#$PlayerPinJoint.set_node_b(NodePath("../FootAnchor"))
	pass

func _on_player_unground_player():	
	## disable the pin joint for the player
	#$PlayerPinJoint.set_node_a(NodePath(""))
	#$PlayerPinJoint.set_node_b(NodePath(""))
	pass
