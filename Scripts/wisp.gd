extends RigidBody3D

@export var bob_intensiy = 0.75

var health: HealthComponent
var bob_time := 0.0
var base_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	
	health = HealthComponent.new()
	health.max_health = 100.0 
	health.init_health()
	health.died.connect(_on_death)
	
	base_position = global_position
	
	#wisps dont all bob in paralell
	bob_time += randi() % 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bob_time += delta
	position.y = base_position.y + sin(bob_time) * bob_intensiy
	
func _on_death():
	queue_free()
