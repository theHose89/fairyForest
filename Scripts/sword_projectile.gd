extends CharacterBody3D

signal sword_hit
signal sword_recalled


@export var SPEED = 60
@export var stiffness = 6.0
@export var damping = 0.0
@export var scroll_speed = 0.2
@export var max_chain_length = 25
@export var scroll_cooldown: float = 0.02

@onready var player = get_tree().current_scene.get_node("Player")
@onready var playerHands = player.get_node("Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera")
@onready var reel = playerHands.get_node("Hands/Reel/woodReel")
@onready var audio_player = $AudioStreamPlayer3D
@onready var chain = $chain

var cooldown_timer: float = 0.0
var dir : Vector2
var spawnPos : Vector3
var spawnRot : Vector3
var resting_length := 0.0
var starting_position
var final_position := Vector3.ZERO
var attached := false
var crank_amount = 0
var scroll_offset = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = spawnPos
	rotation =  spawnRot
	rotation.x = dir.y
	starting_position = player.global_position
	player.return_sword.connect(_kill_sword)
	add_collision_exception_with(player)

func _process(_delta: float) -> void:
	var chain_vector = reel.global_position
	#chain_vector.y += 0.5
	chain.look_at(chain_vector, Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	
	if attached:
		print(resting_length + crank_amount)
		if player.is_on_floor() and player.is_moving:
			#if resting_length + crank_amount  + scroll_offset != player.global_position.distance_to(final_position):
				#change_crank(player.global_position.distance_to(final_position) - resting_length - crank_amount - scroll_offset)
			if resting_length + crank_amount + scroll_offset != player.global_position.distance_to(final_position):
				change_crank(player.global_position.distance_to(final_position) - resting_length - crank_amount - scroll_offset)
		grapple(delta)
		return
	var movement_vector = Vector3(0, dir.y * SPEED, -SPEED).rotated(Vector3.UP, dir.x) * delta
	var collision = move_and_collide(movement_vector)
	
	
	if collision:
		attached = true
		final_position = global_position
		resting_length = starting_position.distance_to(final_position)
		print(starting_position.distance_to(final_position))
		if starting_position.distance_to(final_position) > max_chain_length:
			#throw sowrd without grapple
			_kill_sword()
			return
		
		sword_hit.emit()
		

func _input(event: InputEvent) -> void:
	if event.is_action("Wheel Up") and !(player.is_moving and player.is_on_floor()):
		change_crank(-scroll_speed)
		scroll_offset += scroll_speed
		if cooldown_timer <= 0.0:
			cooldown_timer += scroll_cooldown
	elif event.is_action("Wheel Down") and !(player.is_moving and player.is_on_floor()):
		change_crank(scroll_speed)
		scroll_offset -= scroll_speed
		if cooldown_timer <= 0.0:
			cooldown_timer += scroll_cooldown
		

func grapple(delta : float):
	var chain_dist = player.global_position.distance_to(final_position)
	var chain_dir =  player.global_position.direction_to(final_position)
	
	if player.is_on_floor():
		pass
	else:
		pass
	
	var displacment = resting_length - chain_dist + crank_amount
	
	if displacment < 0:
		var force = Vector3.ZERO
		
		var spring_force_mag = stiffness * displacment
		var spring_force = chain_dir * spring_force_mag
			
		var vel_dot = player.velocity.dot(chain_dir)
		var damping_value = damping * vel_dot * chain_dir
	
		force = -spring_force + damping_value
		if player.is_on_floor() and force.y < 0:
			force.y = 0
		
		
		player.velocity += force * delta
		
		player.sword_tugging = true
	else:
		player.sword_tugging = false
		player.stopped = false

func change_crank(cranked : float):
	if resting_length + crank_amount + cranked > 0:
		if cooldown_timer <= 0.0:
			crank_amount += cranked
			#cooldown_timer += scroll_cooldown
		reel.rotation.z += sign(cranked) * 0.1

	if resting_length + crank_amount > max_chain_length:
		#snap chain
		print("snap")
		_kill_sword()

func _kill_sword() -> void:
	sword_recalled.emit()
	set_physics_process(false)
	queue_free() 

func is_moving() -> bool:
	if Input.is_action_pressed("Forward") or Input.is_action_pressed("Backwards") or Input.is_action_pressed("Right") or Input.is_action_pressed("Left"):
		return true
	return false
