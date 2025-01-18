extends VBoxContainer

func _process(_delta: float) -> void:
	$Fps.text = "fps: {count}".format({"count": Engine.get_frames_per_second()})
	$GlobalPos.text = "g: %.1v" % (%Player.position - %Origin.position)
	$Pos.text = "p: %.2v" % %Player.position
	$Origin.text = "o: %.v" % %Origin.position
