extends PointLight2D

@onready var blinkAnimation: AnimationPlayer = $AnimationPlayer

func _ready():
	blinkAnimation.play("blink")
