extends CharacterBody3D

signal sword_hit
signal sword_recalled

@export var SPEED = 60
@export var stiffness = 6.0
@export var damping = 0.2

@onready var playerHands = get_tree().current_scene.get_node("Player/Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera")
@onready var player = get_tree().current_scene.get_node("Player")


var dir : Vector2
var spawnPos : Vector3
var spawnRot : Vector3
var resting_length := 0.0
var starting_position
var final_position := Vector3.ZERO
var attached := false
var crank_amount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = spawnPos
	rotation =  spawnRot
	rotation.x = dir.y
	starting_position = player.global_position
	player.return_sword.connect(_kill_sword)
	add_collision_exception_with(player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if attached:
		if player.is_on_floor() or crank_amount >= 0:
			var old_length = resting_length
			resting_length = player.global_position.distance_to(final_position)
			crank(resting_length - player.global_position.distance_to(final_position))
		else:
			grapple(delta)
		return
	var movement_vector = Vector3(0, dir.y * SPEED, -SPEED).rotated(Vector3.UP, dir.x) * delta
	var collision_check = move_and_collide(movement_vector)
	
	
	if collision_check:
		attached = true
		final_position = global_position
		resting_length = starting_position.distance_to(final_position)
		sword_hit.emit()

func _input(event: InputEvent) -> void:
	print("Crank: ")
	print(crank_amount)
	if event.is_action("Wheel Up"):
		crank(-0.1)
	elif event.is_action("Wheel Down"):
		crank(0.1)

func grapple(delta : float):
	var chain_dist = player.global_position.distance_to(final_position)
	var chain_dir =  player.global_position.direction_to(final_position)
	
	
	var displacment = resting_length - chain_dist + crank_amount
	print(displacment)
	
	if displacment < 0:
		var force = Vector3.ZERO
		
		var spring_force_mag = stiffness * displacment
		var spring_force = chain_dir * spring_force_mag
			
		var vel_dot = player.velocity.dot(chain_dir)
		var damping_value = damping * vel_dot * chain_dir
	
		force = -spring_force + damping_value
		player.velocity += force * delta

func crank(crank : float):
	print(crank)

func _kill_sword() -> void:
	sword_recalled.emit()
	queue_free() 
