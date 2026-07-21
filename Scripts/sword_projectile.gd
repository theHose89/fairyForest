extends CharacterBody3D

@export var SPEED = 60
@export var stiffness = 10.0
@export var damping = 2.0

@onready var playerHands = get_tree().current_scene.get_node("Player/Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera")
@onready var player = get_tree().current_scene.get_node("Player")

var dir : Vector2
var spawnPos : Vector3
var spawnRot : Vector3
var resting_length := 0.0
var starting_position
var final_position := Vector3.ZERO
var attached := false

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
		grapple()
		return
	var movement_vector = Vector3(0, dir.y * SPEED, -SPEED).rotated(Vector3.UP, dir.x) * delta
	var collision_check = move_and_collide(movement_vector)
	
	
	if collision_check:
		attached = true
		final_position = global_position
		resting_length = starting_position.distance_to(final_position)

func grapple():
	var chain_dist = player.global_position.distance_to(final_position)
	var chain_dir =  player.global_position.direction_to(final_position)
	
	var displacment = resting_length - chain_dist
	print(displacment)

func _kill_sword() -> void:
	queue_free() 
