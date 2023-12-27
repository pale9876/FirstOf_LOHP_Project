extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D
@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree

@export var health:int = 999

enum {
	idle,
	interact
}

var state = idle
var playerPosition = Vector2.ZERO 
var suffix:String = "Left"

func _ready():
	
	animationPlayer.play("Idle" + suffix)
	animationTree.active = true

func _physics_process(delta):
	
	match state:
		idle:
			look_at_player()
			update_facing()
		interact:
			pass
			

#func _on_interact_area_body_entered(body):
#	if body.name == "player":
#		animationPlayer.play("toDialogue_Right")
#		state = interact
#
#func _on_animation_player_animation_finished(anim_name):
#	if anim_name == "toDialogue_Right":
#		animationPlayer.play("Dialogue_Right")
#
#func _on_interact_area_body_exited(body):
#	if body.name == "player":
#		animationPlayer.play("Idle" + suffix)
#		state = idle

func look_at_player():
	playerPosition = player.position
	if playerPosition > position:
		animationPlayer.play("Idle" + suffix)
	elif playerPosition < position:
		animationPlayer.play("Idle" + suffix)
		
func interact_with_player():
	pass


func update_facing():
	playerPosition = player.position
	if playerPosition > position:
		suffix = "Right"
	elif playerPosition < position:
		suffix = "Left"
