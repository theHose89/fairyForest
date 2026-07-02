extends CharacterBody3D


@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var head := $Head
@onready var camera := $Head/Camera3D

#rotate head when mouse moved
func _unhandled_input(event: InputEvent) -> void:
	# Check if the event is mouse movement and mouse is locked in game
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate the entire player body left/right (Y Axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate the neck up/down (X Axis)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp vertical looking so the camera doesn't flip upside down
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# Toggle mouse visibility with Escape key for menus
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backwards")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized().rotated(Vector3.RIGHT, head.rotation.y)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
