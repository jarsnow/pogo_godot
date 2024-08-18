extends Polygon2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# create the rigid body 2d node for the polygon
	var collision_shape = CollisionPolygon2D.new()
	
	# copy the current polygon shape over to the collision polygon
	collision_shape.polygon = polygon
	
	# add shape to the static body
	$StaticBody2D.add_child(collision_shape)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
