extends Camera3D

@export var bob_speed = 10
@export var bob_intensity = 0.1
@export var bob_hand_intensity = 0.01

var bob_vector = Vector2.ZERO
var bob_index = 0.0

@onready var hands = $Hands
@onready var sword_animation_player: AnimationPlayer = $Hands/Sword/AnimationPlayer
@onready var reel_animation_player: AnimationPlayer = $Hands/Reel/AnimationPlayer
@onready var player = get_tree().current_scene.get_node("Player")
@onready var playerBobber = get_tree().current_scene.get_node("Player/Pivot/Bobber")
@onready var reel = $Hands/Reel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.sword_thrown.connect(_throw_sword)
	player.return_sword.connect(_reset_sword)
	player.swing_sword.connect(_swing_sword)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hands.position.x = lerp(hands.position.x, 0.0, delta*5)
	hands.position.y = lerp(hands.position.y, 0.0, delta*5)
	

func sway(sway_amount):
	hands.position.x -= sway_amount.x*0.00005
	hands.position.y += sway_amount.y*0.00005
	
func bob(delta: float):
	bob_index += bob_speed * delta
	bob_vector.y = sin(bob_index)
	bob_vector.x = sin(bob_index/2) + 0.5
	
	hands.position.y = lerp(hands.position.y, bob_vector.y * (bob_hand_intensity), delta * 5)
	hands.position.x = lerp(hands.position.x, bob_vector.x * bob_hand_intensity, delta * 5)
	
	playerBobber.position.y = lerp(playerBobber.position.y, bob_vector.y * (bob_intensity), delta * 5)
	playerBobber.position.x = lerp(playerBobber.position.x, bob_vector.x * bob_intensity, delta * 5)
	

func _swing_sword():
	sword_animation_player.play("Swing")

func _throw_sword():
	sword_animation_player.play("Throw")
	reel_animation_player.play("raise")
	
func _reset_sword():
	sword_animation_player.play("RESET")
	reel_animation_player.play("lower")
