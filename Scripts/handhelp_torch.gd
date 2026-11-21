extends GPUParticles3D

@onready var proc_material: ParticleProcessMaterial = process_material as ParticleProcessMaterial
@onready var player = get_tree().current_scene.get_node("Player")

# Base gravity pulling down (Y-axis)
var base_gravity: Vector3 = Vector3(0, 1, 0)
# How hard the input pushes the particles horizontally
var push_strength: float = 15.0 

func _process(delta: float) -> void:
	var input_dir: Vector3 = Vector3.ZERO
	
	# Mapping standard 3D horizontal movement (X and Z axes)
	if Input.is_action_pressed("Left"):
		input_dir.x += 1
	if Input.is_action_pressed("Right"):
		input_dir.x -= 1
	if Input.is_action_pressed("Up"): # Standard down key moves "back" (Positive Z)
		input_dir.z += 1
	if Input.is_action_pressed("Down"):   # Standard up key moves "forward" (Negative Z)
		input_dir.z -= 1
		
	if input_dir.length_squared() > 0:
		input_dir = input_dir.normalized()
	
	# Interpolate (lerp) smoothly so the change in direction isn't jarring
	var target_gravity = base_gravity + (input_dir * push_strength)
	proc_material.gravity = proc_material.gravity.lerp(target_gravity, delta * 5.0)
