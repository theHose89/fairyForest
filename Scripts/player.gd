extends CharacterBody3D

signal sword_thrown
signal return_sword
signal swing_sword

@export var SPEED = 5
@export var JUMP_VELOCITY = 4.5
@export var mouse_sensitivity: float = 0.003
@export var KNOCKBACK = 6

@onready var hands := $Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera
@onready var head := $Pivot
@onready var bobber := $Pivot/Bobber
@onready var camera := $Pivot/Bobber/Camera3D
@onready var sword_proj := load("res://Scenes/sword_projectile.tscn")
@onready var main := get_tree().get_root()
@onready var sword_hit_box := $"Pivot/SwordHitBox"


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
		
		hands.sway(Vector2(event.relative.x, event.relative.y))
		
	# Toggle mouse visibility with Escape key for menus
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if(event.is_action_pressed("Special Action")):
		throw_sword()
		sword_thrown.emit()
	elif event.is_action_released("Special Action"):
		return_sword.emit()
	elif(event.is_action_pressed("Action")):
		if Input.is_action_pressed("Special Action"):
			return
		swing_sword.emit()
		for body in sword_hit_box.get_overlapping_bodies():
			if(body.name != "Player"):
				basic_sword_knockback()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
	

func _physics_process(delta: float) -> void:
	$Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera.global_transform = camera.global_transform
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
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			hands.bob(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			bobber.position.y = lerp(bobber.position.y, 0.0, delta*5)
			bobber.position.x = lerp(bobber.position.x, 0.0, delta*5)
	else:
		if direction:
			velocity.x += direction.x * SPEED/100      #speed divied to scale
			velocity.z += direction.z * SPEED/100      #with speed on ground
		else:
			pass
	move_and_slide()

func basic_sword_knockback():
	if is_on_floor():
		return
	
	var max_y = sqrt(velocity.length()) * 3
	var body_angle = deg_to_rad(clamp(60 * (rotation.y + 3), 0, 360))
	var x_dir = -KNOCKBACK * sin(body_angle)
	var y_dir = -KNOCKBACK * clamp(head.rotation.x, -KNOCKBACK, KNOCKBACK)
	var z_dir = -KNOCKBACK * cos(body_angle)
	
	var dir = Vector3(x_dir, y_dir, z_dir)
	
	velocity = dir * velocity.length() / 7      #scale magnitude to work better with velocity
	velocity.y = clamp(velocity.y, -max_y, max_y)
	
func throw_sword():
	var proj = sword_proj.instantiate()
	proj.dir = Vector2(rotation.y, head.rotation.x)
	proj.spawnPos = global_position
	proj.spawnPos.y += 0.5 #offset spawn so sword comes out of faces
	proj.spawnRot = rotation
	
	main.add_child.call_deferred(proj)
	
	
