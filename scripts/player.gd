extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var can_move: bool = true

func _ready() -> void:
	DialogueManager.dialogue_started.connect(on_dialogue_started_ended)
	DialogueManager.dialogue_ended.connect(on_dialogue_started_ended)

func on_dialogue_started_ended(resource: DialogueResource) -> void: can_move = not can_move

func _physics_process(delta: float) -> void:
	if not can_move: return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y > 0: %AnimatedSprite2D.play("fall")
		elif velocity.y < 0: %AnimatedSprite2D.play("jump")

	# Handle jump.
	if Input.is_action_just_pressed("game_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction > 0: %AnimatedSprite2D.flip_h = false
	elif direction < 0: %AnimatedSprite2D.flip_h = true
	
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor(): %AnimatedSprite2D.play("walk")
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor(): %AnimatedSprite2D.play("idle")
	move_and_slide()
