extends RigidBody3D

var health: HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	
	health = HealthComponent.new()
	health.max_health = 100.0 
	
	health.init_health()
	health.died.connect(_on_death)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_death():
	queue_free()
