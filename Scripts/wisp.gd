extends RigidBody3D

@onready var player = get_tree().current_scene.get_node("Player")
@onready var main := get_tree().get_root()
@onready var wisp_proj = load("res://Scenes/wispProj.tscn")

@export var bob_intensiy := 0.75
@export var wisp_speed := 3
@export var wisp_idle_dist := 15
@export var attack_freq := 5

var health: HealthComponent
var time := 0.0
var bob_amount := 0.0
var target_velocity := Vector3.ZERO
var start_checking := true
var not_ready := true
var cooldown := 0.0


func _ready() -> void:
	gravity_scale = 0.0
	
	health = HealthComponent.new()
	health.max_health = 100.0 
	health.init_health()
	health.died.connect(_on_death)
	
	#wisps dont all bob in paralell
	time += randi() % 10

 
func _physics_process(delta: float) -> void:
	#check if on screen
	if not_ready:
		if start_checking:
			if not is_instance_valid(player):
				return

			# 2. Access the 3D physics world state
			var space_state = get_world_3d().direct_space_state
			
			# 3. Define the ray coordinates (from this object's origin to the player's origin)
			var origin = global_position
			var target = player.global_position
			
			# 4. Configure the raycast parameters
			var query = PhysicsRayQueryParameters3D.create(origin, target)
			
			# (Optional) Prevent the ray from hitting this object itself
			query.exclude = [get_rid()] 
			
			# 5. Fire the raycast
			var result = space_state.intersect_ray(query)
			
			# 6. Evaluate what the ray hit
			if result:
				var collider = result.collider
				
				# Check if the ray hit the player first (Clear line of sight!)
				if collider == player:
					not_ready = false
			else:
				# The ray hit nothing at all on its way to the player position
				print("Clear line of sight (no colliders encountered).")
				#not_ready = false
		
	else:
		position.y -= bob_amount
		time += delta
		bob_amount = sin(time) * bob_intensiy
		position.y += bob_amount
		
		var dir_to_player = player.global_position - global_position
		var distance_from_player = dir_to_player.length()
		
		if abs(distance_from_player - wisp_idle_dist) < 0.1:
			target_velocity = Vector3.ZERO
		elif distance_from_player < wisp_idle_dist:
			target_velocity = dir_to_player.normalized() * -wisp_speed
		else:
			target_velocity = dir_to_player.normalized() * wisp_speed
		
		#attack sometime
		cooldown -= delta
		if int(time) % (attack_freq) == 0 and cooldown < 0:
			attack()
			cooldown = 1.0
	
	
	
	#handle bobbing

func attack():
	print("!!!")
	var proj = wisp_proj.instantiate()
	proj.position = global_position
	main.add_child.call_deferred(proj)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.linear_velocity = target_velocity


func _on_death():
	queue_free()


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	start_checking = true
	
	


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	start_checking = false
