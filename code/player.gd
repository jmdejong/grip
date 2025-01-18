extends CharacterBody3D


const MOUSE_SENSITIVITY: float = 0.003
const speed: float = 5
const sprint_speed: float = 500
const ultra_sprint_speed: float = 20000
const jump_speed: float = 10

var gravity_enabled: bool = false



signal viewpoint_changed(pos: Vector3)

func _physics_process(_delta: float) -> void:
	move()

func adjust_direction() -> void:
	var down = get_gravity()
	if down.length_squared() == 0:
		down = Vector3(0, -1, 0)
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(down).normalized(), -down.normalized())
	

func move() -> void:
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var s: float = speed
	if Input.is_action_pressed("sprint"):
		s = sprint_speed
	if Input.is_action_pressed("ultrasprint"):
		s = ultra_sprint_speed
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * s)
	if gravity_enabled:
		pass
		#movement.y = velocity.y - get_gravity().length()*delta
		#if Input.is_action_pressed("up") and is_on_floor():
			#movement.y = s
	else:
		movement.y = s * (float(Input.is_action_pressed("up")) - float(Input.is_action_pressed("down")))
	velocity = quaternion * movement
	move_and_slide()
	
	viewpoint_changed.emit(position)

func _input(event: InputEvent):
	if Input.is_action_just_pressed("toggle_gravity"):
		gravity_enabled = !gravity_enabled
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Head.rotation.x = clamp($Head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -PI/2, PI/2)
		rotate(-get_gravity().normalized(), -event.relative.x * MOUSE_SENSITIVITY)
