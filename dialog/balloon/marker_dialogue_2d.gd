class_name MarkerDialogue2D extends Marker2D

var marker_offset: Marker2D
var being_used: bool
var markers_being_used: Array

@export var automatic_direction: bool = true
@export var dialogue_offset: Vector2 = Vector2(100, 100):
	get:
		var offset: Vector2 = dialogue_offset
		if marker_offset: 
			offset = marker_offset.global_position - self.global_position
		if automatic_direction:
			for mark in markers_being_used:
				if self.global_position.x - mark.global_position.x < 0:
					offset.x = -offset.x
				else: 
					offset.x = abs(offset.x)
		return offset 

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	var children: Array[Node] = self.get_children().filter(func (c): return c as Marker2D)
	if not children: return
	marker_offset = children[0]

func _on_dialogue_started(resource: DialogueResource) -> void:
	if resource.character_names.has(self.name) and automatic_direction:
		being_used = true
		var set_markers_being_used :Callable = func():
			markers_being_used = get_tree().get_nodes_in_group("balloon_marker").filter(
			func(c): return c.being_used and not c == self
			)
		set_markers_being_used.call_deferred()
		

func _on_dialogue_ended(resource: DialogueResource) -> void: 
	being_used = false
