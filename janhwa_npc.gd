extends CharacterBody2D

@onready var animationPlayer = $AnimationPlayer

func _ready():
	animationPlayer.play("IdleLeft")
