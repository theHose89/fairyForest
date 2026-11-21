extends CharacterBody3D

signal sword_thrown
signal return_sword
signal swing_sword
signal sword_pulled_back
signal player_dashed
signal lower_sword


@export var SPEED = 10
@export var air_speed = 0.4
@export var JUMP_VELOCITY = 4.5
@export var mouse_sensitivity: float = 0.003
@export var KNOCKBACK = 6
@export var dash_intesity = 15
@export var dash_length = 0.5
@export var maxHealth = 150

@onready var hands := $Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera
@onready var head := $Pivot
@onready var bobber := $Pivot/Bobber
@onready var camera := $Pivot/Bobber/Camera3D
@onready var sword_proj := load("res://Scenes/sword_projectile.tscn")
@onready var main := get_tree().get_root()
@onready var sword_hit_box := $"Pivot/SwordHitBox"
@onready var ray_cast := $Pivot/RayCast3D
@onready var handheld_torch := $Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera/Hands/torch/GPUParticles3D

var health: HealthComponent

var grappel_point := Vector3.ZERO
var sword_tugging := false
var is_moving = false
var stopped = true
var dashing := 0
var dash_time := 0.0
var dash_hit := []
var grapeling := false

#rotate head when mouse moved
func _unhandled_input(event: InputEvent) -> void:
	# Check if the event is mouse movement and mouse is locked in game
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate the entire player body left/right (Y Axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate the neck up/down (X Axis)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		#$reel_orgin.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp vertical looking so the camera doesn't flip upside down
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		#$reel_orgin.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		#print($reel_orgin.rotation.x)
		
		hands.sway(Vector2(event.relative.x, event.relative.y))
		
	# Toggle mouse visibility with Escape key for menus
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#if event.is_action_pressed("Dash"):
		#dashing = 1
	if event.is_action_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	
	if dashing == 1:
		return
	
	#handle grapple
	if(event.is_action_pressed("Special Action")):
		throw_sword()
		sword_thrown.emit()
	if event.is_action_released("Special Action"):
		return_sword.emit()
	if Input.is_action_pressed("Special Action"):
		return
	
	#handle swing	
	if event.is_action_pressed("Action") and dashing == 0 and !is_on_floor():
		if event.double_click:
			dash()
	if(event.is_action_pressed("Action")) and dashing != 1:
		sword_swung()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
	health = HealthComponent.new()
	health.max_health = maxHealth
	
	health.init_health()
	health.died.connect(_on_death)

func _physics_process(delta: float) -> void:
	#$Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera.global_transform = camera.global_transform
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if dashing == 1:
			lower_sword.emit()
		if dashing != 0:
			dashing = 0
	
	#checks hitbox for dash
	if dashing == 1:
		for body in sword_hit_box.get_overlapping_bodies():
			if(body.name != "Player"):
				basic_sword_knockback()
			if body.is_in_group("Enemy") and !dash_hit.has(body):
				body.health.damage(100)
				dash_hit.append(body)
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backwards")
	if input_dir.length() > 0:
		is_moving = true
	else: 
		is_moving = false
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized().rotated(Vector3.RIGHT, head.rotation.y)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	
	if is_on_floor():
		if direction:
			stopped = false
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			hands.bob(delta)
			
			#if sword_tugging:
				##if global_position +w direction is closer to grappel_point than global_position:
				#var distance_from_sword = grappel_point - global_position
				#if (distance_from_sword  - direction).length() >  distance_from_sword.length():
					#print(distance_from_sword.length())
					##print(velocity.x)
					##print(velocity.z)
					#velocity.x = velocity.x / (distance_from_sword.length() * distance_from_sword.length())
					#velocity.z = velocity.y / (distance_from_sword.length() * distance_from_sword.length())
					
		else:
			if !stopped:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
			bobber.position.y = lerp(bobber.position.y, 0.0, delta*5)
			bobber.position.x = lerp(bobber.position.x, 0.0, delta*5)
			if velocity == Vector3.ZERO:
				stopped = true
	else:
		if direction:
			stopped = false
			#velocity.x += direction.x * air_speed      
			#velocity.z += direction.z * air_speed 
		if dash_time > 0:
			if dash_time == dash_length:
				var ray_direction = (ray_cast.to_global(ray_cast.target_position) - ray_cast.global_position).normalized()
				velocity = ray_direction * dash_intesity
			dash_time -= delta
		elif dashing == 1:
			lower_sword.emit()
			dashing = -1
	
	
	move_and_slide()
	


func basic_sword_knockback():
	if is_on_floor() or dashing == 1:
		return
	
	var max_y = sqrt(velocity.length()) * KNOCKBACK/2
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
	proj.ray_vec = (ray_cast.to_global(ray_cast.target_position) - ray_cast.global_position).normalized()
	proj.sword_hit.connect(thrown_sword_hit)
	proj.sword_recalled.connect(sword_recall)
	
	main.add_child.call_deferred(proj)

func sword_swung():
	swing_sword.emit()
	for body in sword_hit_box.get_overlapping_bodies():
		if(body.name != "Player"):
			basic_sword_knockback()
		if body.is_in_group("Enemy"):
			body.health.damage(100)
			
func dash():
	dashing = 1
	dash_hit = []
	dash_time = dash_length
	player_dashed.emit()

func thrown_sword_hit():
	grappel_point = main.get_node("Sword Projectile").global_position
	grapeling = true
	dashing = 0

func sword_recall():
	sword_tugging = false
	grappel_point = Vector3.ZERO
	stopped = false
	grapeling = false
	sword_pulled_back.emit()
	
func _on_death():
	print("dead")
