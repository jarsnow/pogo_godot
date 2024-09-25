extends Camera2D

var cam_speed: int = 500

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# movement
	if Input.is_action_pressed("move_camera_left"):
		position.x -= cam_speed * delta
	if Input.is_action_pressed("move_camera_right"):
		position.x += cam_speed * delta
	if Input.is_action_pressed("move_camera_up"):
		position.y -= cam_speed * delta
	if Input.is_action_pressed("move_camera_down"):
		position.y += cam_speed * delta
		
	if Input.is_action_just_released("zoom_in"):
		zoom += Vector2(0.1, 0.1)
	if Input.is_action_just_released("zoom_out"):
		zoom -= Vector2(0.1, 0.1)
