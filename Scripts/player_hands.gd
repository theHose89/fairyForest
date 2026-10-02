extends Camera3D

@export var bob_speed = 10
@export var bob_intensity = 0.02
@export var bob_hand_intensity = 0.01

var bob_vector = Vector2.ZERO
var bob_index = 0.0
var reel_up = false

@onready var hands = $Hands
@onready var sword_animation_player: AnimationPlayer = $Hands/Sword/AnimationPlayer
@onready var reel_animation_player: AnimationPlayer = $Hands/Reel/AnimationPlayer
@onready var player = get_tree().current_scene.get_node("Player")
@onready var playerBobber = get_tree().current_scene.get_node("Player/Pivot/Bobber")
@onready var reel = $Hands/Reel
@onready var reel_orgin = get_tree().current_scene.get_node("Player/reel_orgin")
@onready var reel_point = get_tree().current_scene.get_node("Player/reel_orgin/reeling_point")
@onready var chain = player.get_node("Pivot/Bobber/Camera3D/SubViewportContainer/SubViewport/HandsCamera/Hands/Reel/chain")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.sword_thrown.connect(_throw_sword)
	player.sword_pulled_back.connect(_reset_sword)
	player.swing_sword.connect(_swing_sword)
	chain.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hands.position.x = lerp(hands.position.x, 0.0, delta*5)
	hands.position.y = lerp(hands.position.y, 0.0, delta*5)
	
	playerBobber.position.y = lerp(playerBobber.position.y, 0.0, delta * 5)
	playerBobber.position.x = lerp(playerBobber.position.x, 0.0, delta * 5)
	
	if reel_up:
		update_chain(reel_point.global_position, player.grappel_point)
		
	#print(reel_point.position)
	#if !player.is_moving || !player.is_on_floor():
		#reel_point.position.x = lerp(reel_point.position.x, reel_orgin.position.x, delta*5)
		#reel_point.position.y = lerp(reel_point.position.y, reel_orgin.position.y, delta*5)
	

func sway(sway_amount):
	hands.position.x -= sway_amount.x*0.00005
	hands.position.y += sway_amount.y*0.00005
	
func bob(delta: float):
	bob_index += bob_speed * delta
	bob_vector.y = sin(bob_index)
	bob_vector.x = sin(bob_index/2) + 0.5
	
	hands.position.y = lerp(hands.position.y, -bob_vector.y * (bob_hand_intensity), delta * 5)
	hands.position.x = lerp(hands.position.x, -bob_vector.x * bob_hand_intensity, delta * 5)
	
	#var old_position = playerBobber.position
	playerBobber.position.y = lerp(playerBobber.position.y, bob_vector.y * (bob_intensity), delta * 5)
	playerBobber.position.x = lerp(playerBobber.position.x, bob_vector.x * bob_intensity, delta * 5)
	
	#reel_point.position.y -= old_position.y - playerBobber.position.y
	#reel_point.position.x -= old_position.x - playerBobber.position.x
	#reel_point.position.y = lerp(reel_point.position.y, bob_vector.y * (bob_hand_intensity), delta * 5)
	#reel_point.position.x = lerp(reel_point.position.x, bob_vector.x * bob_hand_intensity, delta * 5)

func update_chain(start: Vector3, end: Vector3):
	start.y = start.y + 0.6
	
	var diff = end - start
	var dist = diff.length()
	if dist < 0.001:
		return
	
	chain.global_position = start.lerp(end, 0.5)
	#chain.global_position = (start + end) / 2
	chain.scale = Vector3.ONE        # reset FIRST
	chain.look_at(end, Vector3.UP)
	chain.rotate_object_local(Vector3.RIGHT, PI / 2)
	chain.scale.y = dist 


func _swing_sword():
	sword_animation_player.play("Swing")

func _throw_sword():
	sword_animation_player.play("Throw")
	reel_animation_player.play("raise")
	reel_up = true
	chain.show()
	
func _reset_sword():
	sword_animation_player.play("RESET")
	reel_animation_player.play("lower")
	reel_up = false
	chain.hide()
