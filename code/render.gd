extends WorldEnvironment


func _input(_event):
	if Input.is_action_just_pressed("switch_render"):
		var vp := get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 6 as Viewport.DebugDraw
