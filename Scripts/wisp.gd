extends RigidBody3D

@onready var player = get_tree().current_scene.get_node("Player")

@export var bob_intensiy = 0.75
@export var wisp_speed = 3
@export var wisp_idle_dist = 15

var health: HealthComponent
var bob_time := 0.0
var bob_amount := 0.0
var target_velocity := Vector3.ZERO
var not_ready = true


func _ready() -> void:
	gravity_scale = 0.0
	
	health = HealthComponent.new()
	health.max_health = 100.0 
	health.init_health()
	health.died.connect(_on_death)
	
	#wisps dont all bob in paralell
	bob_time += randi() % 10


func _physics_process(delta: float) -> void:
	if not_ready:
		return
	
	#handle bobbing
	position.y -= bob_amount
	bob_time += delta
	bob_amount = sin(bob_time) * bob_intensiy
	position.y += bob_amount
	
	var dir_to_player = player.global_position - global_position
	var distance_from_player = dir_to_player.length()
	
	if abs(distance_from_player - wisp_idle_dist) < 0.1:
		target_velocity = Vector3.ZERO
	elif distance_from_player < wisp_idle_dist:
		target_velocity = dir_to_player.normalized() * -wisp_speed
	else:
		target_velocity = dir_to_player.normalized() * wisp_speed

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.linear_velocity = target_velocity


func _on_death():
	queue_free()


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	not_ready = false
