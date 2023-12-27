extends PointLight2D

@onready var lightanimation:AnimationPlayer = $AnimationPlayer2

func _ready():
	lightanimation.play("light")
