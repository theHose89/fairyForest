# health_component.gd
class_name HealthComponent
extends Resource

@export var max_health: float = 100.0
var current_health: float

signal health_changed(new_health: float)
signal died

# Instead of _ready(), initialize health manually or via an init function
func init_health() -> void:
	current_health = max_health

func damage(amount: float) -> void:
	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health)
	print("took %f damage" %[amount])
	
	if current_health <= 0:
		died.emit()
