extends Area2D

@export var sprite_show: Sprite2D
@export var dialogue: DialogueResource
var is_inside: bool
var is_in_dialogue: bool

func _on_body_entered(body: Node2D) -> void:
	sprite_show.show()
	is_inside = true

func _on_body_exited(body: Node2D) -> void:
	sprite_show.hide()
	is_inside = false
	
func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_started(_resource: DialogueResource) -> void: is_in_dialogue = true
func _on_dialogue_ended(_resource: DialogueResource) -> void: is_in_dialogue = false

func _input(event: InputEvent) -> void:
	if is_inside and event.is_action_pressed("game_dialog") and not is_in_dialogue:
		sprite_show.hide()
		DialogueManager.show_dialogue_balloon_scene("res://dialog/balloon/bubble_balloon.tscn", dialogue)
