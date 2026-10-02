extends CharacterBody3D

signal sword_hit
signal sword_recalled


@export var SPEED = 60
@export var stiffness = 6.0
@export var damping = 0.0
@export var scroll_speed = 0.1
@export var max_chain_length = 25
@export var initial_short = 2

@onready var player = get_tree().current_scene.get_node("Player")
@onready var playerHands = player.get_node("Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera")
@onready var reel = playerHands.get_node("Hands/Reel/woodReel")
@onready var audio_player = $AudioStreamPlayer3D

#var cooldown_timer: float = 0.0
var dir : Vector2
var spawnPos : Vector3
var spawnRot : Vector3
var ray_vec : Vector3
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
	if !attached:
		return
	
	if Input.is_action_pressed("Wheel Up") and !(player.is_moving and player.is_on_floor()):
		change_crank(-scroll_speed)
		if resting_length + crank_amount + -scroll_speed > 0 and resting_length + crank_amount + -scroll_speed < max_chain_length:
			scroll_offset += scroll_speed
	elif Input.is_action_pressed("Wheel Down") and !(player.is_moving and player.is_on_floor()):
		change_crank(scroll_speed)
		if resting_length + crank_amount + scroll_speed > 0 and resting_length + crank_amount + scroll_speed < max_chain_length:
			scroll_offset -= scroll_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#print(snappedf(get_chain_length(), 1))
	
	if attached:
		if player.is_on_floor() and player.is_moving:
			if resting_length + crank_amount + scroll_offset != player.global_position.distance_to(final_position):
				scroll_offset = 0
				if player.global_position.distance_to(final_position) > max_chain_length:
					#play snap sound
					_kill_sword()
					return
				if player.global_position.distance_to(final_position) - resting_length - crank_amount > 0:
					change_crank(player.global_position.distance_to(final_position) - resting_length - crank_amount)
		grapple(delta)
		return
	else:
		player.grappel_point = global_position
	
	var movement_vector = ray_vec * SPEED * delta
	var collision = move_and_collide(movement_vector)
	
	if collision:
		start_grapple(collision.get_collider())
	else:
		resting_length = starting_position.distance_to(global_position)
		if resting_length > max_chain_length:
			#throw sowrd without grapple
			_kill_sword()
			return


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

func start_grapple(collider : Node3D):
	if collider.is_in_group("Enemy"):
		collider.health.damage(50)
		if collider.health.current_health == 0:
			return
	
	
	attached = true
	final_position = global_position
	#helps out player a bit by shorting chian if in airs
	if player.is_on_floor():
		resting_length = starting_position.distance_to(final_position)
	else:
		resting_length = starting_position.distance_to(final_position) - initial_short
		if resting_length < 0:
			resting_length = 0
	#resting_length = snappedf(resting_length, 0.01)
	

	
	sword_hit.emit()



func change_crank(cranked : float):
	if resting_length + crank_amount + cranked > 0 and resting_length + crank_amount + cranked < max_chain_length:
		crank_amount += cranked
		reel.rotation.z += sign(cranked) * 0.1


func _kill_sword() -> void:
	sword_recalled.emit()
	set_physics_process(false)
	queue_free() 

func is_moving() -> bool:
	if Input.is_action_pressed("Forward") or Input.is_action_pressed("Backwards") or Input.is_action_pressed("Right") or Input.is_action_pressed("Left"):
		return true
	return false
	
func get_chain_length() -> float:
	return resting_length + crank_amount
