class_name MarkerDialogue2D extends Marker2D

## this will be the children Marker2D were we will get the offset of the balloon
var marker_offset: Marker2D

## we will use it to know if the marker is being used or not to exclude it or take it
var being_used: bool

## this will be an array of MarkerDialogue2D
var markers_being_used: Array


@export var custom_theme: Theme
## This option will be overrided by the child position and 
## changued if automatic direction is enabled.
@export var dialogue_offset: Vector2 = Vector2(100, -100):
	get:
		var offset: Vector2 = dialogue_offset
		# if we have a marker offset we will changue the dialogue_offset to the next calculation
		if marker_offset: 
			offset = marker_offset.global_position - self.global_position
		
		# If we have automatic_direction enabled we will do the next thing
		if automatic_direction and markers_being_used:
			# we set the closest_mark_distance to infinite to make the first comparation allways true
			var closest_mark_distance :float = INF
			
			# we will use this to save the closest_mark
			var closest_mark_distance_x: float = 0
			
			for mark in markers_being_used:
				# we take the distance of the mark
				var mark_distance:float = self.global_position.distance_to(mark.global_position)
				# we compare the distance of the mark with the closest_mark_distace
				if closest_mark_distance > mark_distance:
					# we overried if its true to the new closest_mark_distance and closes_mark
					closest_mark_distance = mark_distance
					closest_mark_distance_x = self.global_position.x - mark.global_position.x
				
			# we check if its at the left or right of us
			if closest_mark_distance_x < 0: offset.x = -offset.x
			elif closest_mark_distance_x < 0: offset.x = abs(offset.x)
			
		return offset 

## This option will be used for automatic position of the balloon based on the marker_offset
## swiping it in the right or left dynamically 
@export var automatic_direction: bool = true


func _ready() -> void:
	# we connect the dialogue started and ended
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# we get all children if exist and they have to be Marker2D class nodes 
	var children: Array[Node] = self.get_children().filter(func (c): return c as Marker2D)
	# if children is empty we stop the _ready process
	if not children: return
	# we save just the first children in node hiearchy
	marker_offset = children[0]

func _on_dialogue_started(resource: DialogueResource) -> void:
	# if our marker name has the same name as a character in the resource 
	# and the automatic direction is enabled
	if resource.character_names.has(self.name) and automatic_direction:
		# we set the marker as being true
		being_used = true
		
		# we set the markers being used by filtering
		var set_markers_being_used :Callable = func():
			markers_being_used = get_tree().get_nodes_in_group("balloon_marker").filter(
			func(c): return c.being_used and not c == self
			) 
		# we call it in deferred mode to wait all markers being true
		set_markers_being_used.call_deferred()
		

func _on_dialogue_ended(resource: DialogueResource) -> void: being_used = false
