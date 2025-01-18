extends Node3D

var marker_scene = preload("res://scenes/marker.tscn")

func _ready() -> void:
	process_priority = 100

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mark_position"):
		var marker = marker_scene.instantiate()
		add_child(marker)
		marker.global_position = %Player.global_position

func reposition() -> void:
	var snap: int = 2**8
	var d = ($Player.position / snap).round() * snap
	$Player.position -= d
	$Origin.position -= d
	#print($Player.position, " ", $Origin.position)
	#$Player.move()
	#var new_origin: Vector3 = $Player.position.round()
	#$Player.position -= new_origin - $Origin.position
	#$Origin.position = new_origin
	
var just_updated = false
func _physics_process(delta: float) -> void:
	#$Player.move()
	if $Player.position.length_squared() > 1024 ** 2:
		print("a ", $Player.position - $Origin.position, $Player.rotation, $Player.get_gravity())
		reposition()
		print("b ", $Player.position - $Origin.position, $Player.rotation, $Player.get_gravity())
		#$Player.adjust_direction()
		print("c ", $Player.position - $Origin.position, $Player.rotation, $Player.get_gravity())
		just_updated = true
	else:
		if just_updated:
			print("d ", $Player.position - $Origin.position, $Player.rotation, $Player.get_gravity())
		else:
			$Player.adjust_direction()
		if just_updated:
			print("e ", $Player.position - $Origin.position, $Player.rotation, $Player.get_gravity())
			print("")
			just_updated = false
