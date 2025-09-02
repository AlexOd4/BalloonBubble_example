class_name MarkerDialogue2D extends Marker2D

@export var dialogue_offset: Vector2 = Vector2(100, 100)

var marker_offset: Marker2D

func _ready() -> void:
	var children: Array = self.get_children().filter(func (c): return c as Marker2D)
	if not children: return
	
	marker_offset = children[0]
	dialogue_offset = abs(marker_offset.position)
