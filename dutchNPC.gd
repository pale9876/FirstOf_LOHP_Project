extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D
@onready var animationPlayer = $AnimationPlayer

var playerPosition = Vector2.ZERO

func _physics_process(delta):
	look_player()
		
func look_player():
	playerPosition = player.position
	if playerPosition > position:
		animationPlayer.play("IdleRight")
	elif playerPosition < position:
		animationPlayer.play("IdleLeft")
