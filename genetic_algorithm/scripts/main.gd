extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# change the alpha value of the background
	$Background.modulate.a = 0.2
	
	initialize_map_collision()
	
	$AgentContainer.start()
	
# assign collision to the map
func initialize_map_collision():
	
	for map_polygon in $SmallerStairsMap.get_children():
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
