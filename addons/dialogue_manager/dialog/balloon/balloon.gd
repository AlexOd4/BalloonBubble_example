extends Node2D
## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## The offset of the balloon from the point of talk (both must be in positive)
@export var fixed_balloon_offset: Vector2 = Vector2(100, 100)

@export_group("Tween Animation", "tween_")
@export var tween_time: float = 0.5:
	get:
		return tween_time/2
	set(value):
		tween_time = value
@export var tween_transition_type : Tween.TransitionType = Tween.TRANS_SPRING
@export var tween_ease_type : Tween.EaseType = Tween.EASE_OUT

## the direction of the balloon
var direction: Vector2 = Vector2(1, -1)

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			queue_free()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## this is the tween we are going to use to animate the balloon
var tween: Tween

## it will be the start position of the balloon
var balloon_position_start: Vector2

## it will be the end position of the balloon
var balloon_position_end: Vector2

## we are going to use this as a trigger to start the animation
var start_animation: bool

## marks the start position of the ballonon
var balloon_marker: Marker2D

## the character name identifier of the speaker in scene
var character_name : String = ""


## The base input_catcher
@onready var input_catcher: Control = %InputCatcher

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## The response example of response menu
@onready var response_example_size: Vector2 = %ResponseExample.size

## The balloon it's self
@onready var balloon: Control = %Bubble

## The part of the balloon were the text is placed
@onready var text_box: PanelContainer = %TextBox

## The VBoxContainer of the text_box
@onready var text_box_vertical: VBoxContainer = %TextBoxVertical

## Our Line2D node to connect character to it's balloon
@onready var line: Line2D = %BubbleLine

## Current active camera
@onready var camera : Camera2D = get_viewport().get_camera_2d()



func _ready() -> void:
	input_catcher.hide()
	input_catcher.focus_mode = Control.FOCUS_NONE
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


func _process(_delta: float) -> void:
	#we set the size to zero to resize it to its minimun size
	#balloon.size = Vector2.ONE
	
	# we check if balloon_marker its asigned, Then take the position of it with a offset to make it match with the center of the textbox
	# if there is not a balloon_marker we set any position (prefferred for example the center of the screen) 
	if balloon_marker: balloon_position_start = balloon_marker.global_position - balloon.size/2
	else: balloon_position_start = Vector2.ZERO
	
	# we set the real viewport of the screen calculating it with camera position in mind
	var real_viewport_rect:Rect2 = self.get_viewport_rect()
	
	# we get the zoom of the camera for future calculates
	var zoom := Vector2.ONE
	if camera: 
		real_viewport_rect = Rect2(camera.global_position - camera.get_viewport_rect().get_center() / camera.zoom, 
			camera.get_viewport_rect().size / camera.zoom)
		zoom = camera.zoom
	
	# this will be the target position with our offset and direction
	var balloon_position_target = balloon_position_start + fixed_balloon_offset * direction
	# calculate the offset of the balloon based on the screen viewport to make the balloon allways visible inside the viewport
	var screen_offset :Vector2 = get_offset_of_rect_outside_screen(real_viewport_rect, balloon.get_rect(), balloon_position_target)
	# we set the balloon_position_end to be the current postion of the balloon
	balloon_position_end = balloon_position_target + screen_offset
	
	if start_animation :
		start_animation = false
		# we set the positions to its "default"
		balloon.global_position = balloon_position_start 
		balloon.scale = Vector2.ZERO
		line.scale = Vector2.ZERO
		
		# if there is a tween created, kill it to reasing it again 
		if tween: tween.kill()
		# tween properties
		tween = get_tree().create_tween().set_ease(tween_ease_type).set_trans(tween_transition_type)
		# animating the balloon and line
		tween.tween_property(balloon, "global_position", balloon_position_end, tween_time)
		tween.parallel().tween_property(text_box, "scale", Vector2.ONE/zoom, tween_time).set_delay(tween_time)
		tween.parallel().tween_property(line, "scale", Vector2.ONE, tween_time)
		# we wait until the tween is finished to continue the process
		await tween.finished
		# you can delete this line if you dont want input to wait the animation 
		is_waiting_for_input = true
	else:
		# we set the end positions if the camera moves
		balloon.global_position = balloon_position_end
		
		# this will scale the balloon to keep allways the same size in screen
		balloon.scale = (Vector2.ONE/zoom)
	
	# we create and make the calculations curve the line until it reaches the balloon balloon
	var curve := Curve2D.new()
	# we set the line position to balloon_marker position
	line.global_position = balloon_position_start + balloon.size/2
	# This will be the start position of the point of the line 
		# (we set it to Vector2.ZERO because it will be the same as line.global_positoin)
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(0, balloon_position_end.y-balloon_position_start.y)*-.2)
	# This will be the end position of the point of the line we set it to be inside the balloon
	curve.add_point(balloon.get_rect().get_center() - line.global_position)
	# we asign the curve to the points array of line 
	line.points = curve.tessellate(5)
	# we changue the width of the line to adapt balloon size
	line.width = balloon.get_rect().size.x * 0.25
	
	
func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)

## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	balloon_marker = null
	
	# We look if there is markers in scene and we asign balloon_marker to the marker that has the same name as dialogue character
	for marker in get_tree().get_nodes_in_group("balloon_marker") as Array[Marker2D]:
		if dialogue_line.character == marker.name: 
			balloon_marker = marker
			break
	
	# We get the minimum size of the balloon
	var balloon_size: Vector2 = balloon.custom_minimum_size
	# We positionate the text in the center of the box
	text_box_vertical.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# We resize the balloon with the responses that will appear
	if not dialogue_line.responses == []:
		# We positionate the text in top of the textbox to make space for responses
		text_box_vertical.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if balloon_size.x < response_example_size.x:
			balloon_size.x = response_example_size.x
		balloon_size.y += response_example_size.y * dialogue_line.responses.size()
	
	balloon.size = balloon_size
	
	# we changue character_name to make it the same as the one who is talking in the dialogue
	if not dialogue_line.character == character_name:
		character_name = dialogue_line.character
		# we start the animation in process
		start_animation = true
		# we wait delta process time to sync this function to process 
		await get_tree().create_timer(self.get_process_delta_time()).timeout
	
	is_waiting_for_input = false
	
	# this make characters names able to have emojis
	dialogue_line.character = Global.character_to_emoji(dialogue_line.character) 
	
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")
	
	dialogue_label.hide()
	
	# this make text able to have emojis
	dialogue_line.text = IconsFonts.parse_text(dialogue_line.text) 
	dialogue_label.dialogue_line = dialogue_line
	responses_menu.hide()
	responses_menu.modulate = Color.TRANSPARENT
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	input_catcher.show()
	input_catcher.focus_mode = Control.FOCUS_ALL
	input_catcher.grab_focus()
	
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing
	
	# Wait for input
	if dialogue_line.responses.size() > 0:
		input_catcher.hide()
		input_catcher.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		responses_menu.modulate = Color.WHITE
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true

## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)

## it will get the offset of a rect from another taking the farthes point in x and y to return a 
## vector2 taking the distance to make the rect be inside the principal rect
func get_offset_of_rect_outside_screen(screen_rect: Rect2, rect: Rect2, other_position: Vector2 = rect.position):
	rect.position = other_position
	var rect_points: Array =[
		rect.position,
		Vector2(rect.end.x,rect.position.y),
		rect.end,
		Vector2(rect.position.x,rect.end.y)
	]
	var farthest_point: Vector2
	var max_distance := Vector2(-INF, -INF)
	
	for point in rect_points:
		var distance: Vector2
		var closest_point: Vector2
		## if screen_rect.has_point(point) does not work as intended use this:
			#if not ((point.x > screen_rect.position.x and point.x < screen_rect.end.x) and (point.y > screen_rect.position.y and point.y < screen_rect.end.y)):
		if not screen_rect.has_point(point):
			closest_point = Vector2(
				clampf(point.x, screen_rect.position.x, screen_rect.end.x),
				clampf(point.y, screen_rect.position.y, screen_rect.end.y)
			)
			distance = Vector2(
				abs(point.x - closest_point.x), 
				abs(point.y - closest_point.y)
			)
		if distance.x > max_distance.x:
			max_distance.x = distance.x
			farthest_point.x = point.x
		if distance.y > max_distance.y:
			max_distance.y = distance.y
			farthest_point.y = point.y
	return Vector2(clampf(farthest_point.x, screen_rect.position.x, screen_rect.end.x),
		clampf(farthest_point.y, screen_rect.position.y, screen_rect.end.y)
		) - farthest_point

#region Signals

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		input_catcher.hide()

func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)

func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == input_catcher:
		next(dialogue_line.next_id)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

#endregion
