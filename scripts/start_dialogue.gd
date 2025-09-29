extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var res_name: String = "res://dialog/test_dialog_camera_sway.dialogue"
	if self.name == "ZoomExample":  res_name = "res://dialog/test_dialog_camera_zoom.dialogue"
	DialogueManager.show_dialogue_balloon_scene("res://dialog/balloon/bubble_balloon.tscn", load(res_name))
