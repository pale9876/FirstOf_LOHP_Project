extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	pass

func _process(_delta):
	move_marker2d()

func move_marker2d():
	var marker2d = get_tree().get_first_node_in_group("marker")
	if Input.is_action_just_pressed("ui_accept"):
		player.global_position = marker2d.global_position
