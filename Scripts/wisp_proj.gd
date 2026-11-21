extends CharacterBody3D

@onready var particles := $GPUParticles3D
@onready var player := get_tree().current_scene.get_node("Player")
@onready var hitbox := $CollisionShape3D

@export var lifetime := 10.0
@export var speed := 3.0

var time := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	
	move_and_slide()
	
func _process(delta: float) -> void:
	time += delta
	#kill proj after 10 secs
	if time >= lifetime:
		particles.emitting = false
	if time >= lifetime + 0.5:
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body.name == "Player"):
		print("!!!!!")
		player.health.damage(50)
		queue_free()
