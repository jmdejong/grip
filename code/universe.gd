extends Node3D

var marker_scene = preload("res://scenes/marker.tscn")

func _ready() -> void:
	process_priority = 100

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mark_position"):
		var marker = marker_scene.instantiate()
		%Origin.add_child(marker)
		marker.global_position = %Player.global_position

	
var just_updated: bool = false
const reposition_distance: int = 2048 ** 2
const reposition_snap: int = 2**8

func _physics_process(_delta: float) -> void:
	if $Player.position.length_squared() > reposition_distance:
		reposition()
		$Player.adjust_direction()
		just_updated = true
	else:
		if not just_updated:
			$Player.adjust_direction()
		just_updated = false


func reposition() -> void:
	var d = ($Player.position / reposition_snap).round() * reposition_snap
	$Player.position -= d
	$Origin.position -= d
