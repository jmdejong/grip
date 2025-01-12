extends CharacterBody3D


const MOUSE_SENSITIVITY = 0.003
const speed = 10
const sprint_speed = 300
const jump_speed = 10

var gravity_enabled: bool = false



signal viewpoint_changed(pos: Vector3)

func _physics_process(delta):
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var s: float = speed if not Input.is_action_pressed("sprint") else sprint_speed
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * s)
	if gravity_enabled:
		pass
		#movement.y = velocity.y - get_gravity().length()*delta
		#if Input.is_action_pressed("up") and is_on_floor():
			#movement.y = s
	else:
		movement.y = s * (float(Input.is_action_pressed("up")) - float(Input.is_action_pressed("down")))
	velocity = quaternion * movement
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(get_gravity()), -get_gravity().normalized())
	move_and_slide()
	
	viewpoint_changed.emit(position)

func _input(event):
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
