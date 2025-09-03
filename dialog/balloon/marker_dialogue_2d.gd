class_name MarkerDialogue2D extends Marker2D

var marker_offset: Marker2D
@export var automatic_direction: bool = true
var being_used: bool:
	set(value):
		being_used = value
@export var dialogue_offset: Vector2 = Vector2(100, 100):
	get:
		var offset: Vector2 = dialogue_offset
		if automatic_direction:
			var markers = get_tree().get_nodes_in_group("balloon_marker").filter(
				func (c): return (c as MarkerDialogue2D).being_used
			)
			
			for mark in markers.filter(func (c): return not c == self):
				if self.global_position.direction_to(mark.global_position).x > 0:
					offset.x = -offset.x
				elif offset.x < 0: 
					offset.x = -offset.x
		
		if marker_offset: 
			offset = marker_offset.global_position - self.global_position
		return offset

func _ready() -> void:
	var children: Array[Node] = self.get_children().filter(func (c): return c as Marker2D)
	if not children: return
	marker_offset = children[0]
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_started(resource: DialogueResource) -> void:
	if not resource.character_names.has(self.name) and not automatic_direction: return
	being_used = true
func _on_dialogue_ended(resource: DialogueResource) -> void: 
	being_used = false
