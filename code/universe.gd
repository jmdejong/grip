extends Node3D

var marker_scene = preload("res://scenes/marker.tscn")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mark_position"):
		var marker = marker_scene.instantiate()
		marker.global_position = %Player.global_position
		add_child(marker)
