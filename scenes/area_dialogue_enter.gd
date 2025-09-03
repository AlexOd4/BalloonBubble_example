extends Area2D

@export var sprite_show: Sprite2D
@export var dialogue: DialogueResource
var is_inside: bool

func _on_body_entered(body: Node2D) -> void:
	sprite_show.show()
	is_inside = true

func _on_body_exited(body: Node2D) -> void:
	sprite_show.hide()
	is_inside = false

func _input(event: InputEvent) -> void:
	if is_inside and event.is_action_pressed("game_dialog"):
		DialogueManager.show_dialogue_balloon_scene("res://dialog/balloon/bubble_balloon.tscn", dialogue)
