extends Node2D

@onready var blinkAnime:AnimationPlayer = $AnimationPlayer

func _ready():
	blinkAnime.play("blink")
