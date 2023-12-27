extends CharacterBody2D
class_name Unit

signal health_updated(current_health)

@export var jumpVelocity:float = -300.0
@export var doubleJumpVelocity:float = -300.0
@export var friction:float = 1000.0 #마찰력
@export var acceleration:float = 2000.0 #가속
@export var hard_landing_air_to_ground:float= 7.5
@export var hard_landing_wall_to_ground:float = 9.5

@export var able_move: bool = true 
@export var is_downed: bool = false 
@export var is_grabbed: bool = false 
@export var is_stun: bool= false 

@export var is_superArmored: bool = false
@export var is_invincible: bool = false

@export var max_health: int = 100

@export var health: int = 100:
	set(current_health):
		health = clamp(current_health, 0, max_health)
		emit_signal("health_updated", current_health)


@export_enum("stand", "down", "stun", "grabbed") var UnitState: int #유닛상태()

@onready var animationTree:AnimationTree = $AnimationTree
@onready var playback = $AnimationTree.get("parameters/playback")
@onready var leftRayCast = $LeftRayCast
@onready var rightRayCast = $RightRayCast
@onready var stateLabel = $stateLabel
@onready var sprite = $UnitSprite
@onready var speed_scale = $AnimationPlayer.speed_scale
@onready var LineColor = $UnitSprite.get("shader_parameter/line_color")
@onready var camera:Camera2D = $Camera2D

var dash_attacking:bool = true

enum { #state
	ground,
	air,
	doublejump,
	landing,
	hangingWall,
	from_wall_to_ground,
	attack,
	dashattack_ready,
	dashattack_active,
	crouch,
	straight_attack,
	guard,
	knockedAirborne
}

var state

const MAX_FALL_SPEED = 800

var speed:float = 200.0
var max_height:float = 0.0
var hasDoubleJump : bool = false
var can_chargeAttacking: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var y_global_position
var direction:Vector2 = Vector2.ZERO
var player_direction:float = 0

var suffix:String = ""

func _ready():

	animationTree.active = true
	UnitState = 0
	state = ground

func _process(_delta):
	pass

func _physics_process(delta):

	direction = Input.get_vector("move_left", "move_right", "jump", "crouch")

	var input_dir_axis = Input.get_axis("move_left", "move_right")

	match state: # stateMachine
		ground:
			if able_move:
				character_fall(gravity, delta)
				ground_state(delta)
				move_character(true, direction, speed, delta, input_dir_axis)
				update_facing_direction(delta)
				if Input.is_action_just_pressed("DashAttack") and Input.is_action_pressed("shift") and dash_attacking:
					dash_attacking = false
					playback.travel("dash_attack_ready")
					state = dashattack_ready
				if Input.is_action_pressed("crouch") and is_on_floor():
					can_chargeAttacking = true
				else:
					can_chargeAttacking = false
				
				if can_chargeAttacking and is_on_floor() and Input.is_action_pressed("crouch"):
					pass
				
			else:
				character_fall(gravity,delta)
		air:
			if able_move:
				character_fall(gravity, delta)
				max_fall_height_check(delta)
				air_state(delta)
				move_character(true, direction, speed, delta, input_dir_axis)
				update_facing_direction(delta)

			else:
				character_fall(gravity,delta)
		landing:
			if able_move:
				character_fall(gravity, delta)
				landing_state(delta)
		hangingWall:
			if able_move:
				max_fall_height_check(delta)
				hangingWall_state(delta)
				move_character(true, direction, speed, delta, input_dir_axis)
				update_facing_direction(delta)

		dashattack_ready:
			able_move = false
			dashattack_physics(delta)

		dashattack_active:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	update_animation()
	character_state_label()
	_animation_update()
	
	move_and_slide()

func dashattack_physics(delta:float):

	velocity.x = move_toward(300 * player_direction, 0, delta)

func character_fall(_gravity, delta): #중력 적용

	if !is_on_floor():
		velocity.y += _gravity * delta

func max_fall_height_check(delta): #땅에 닿을 때의 속력 체크 

	if max_height > velocity.y * delta:
		max_height = max_height
	else:
		max_height = velocity.y * delta

func character_state_label(): #상태레이블 
	stateLabel.text = "state: " + str(state_string_label(state))

func state_string_label(_state): #상태표시
	match _state:
		0:
			return "ground"
		1:
			return "air"
		2:
			return "doublejump"
		3:
			return "landing"
		4:
			return "hangingWall" 

func move_character(can_move, direction, speed, delta, input_dir_axis): #캐릭터 이동 

	if can_move:
		if direction.x != 0:
			velocity.x = move_toward(velocity.x, speed * input_dir_axis, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		if direction.x != 0 and Input.is_action_pressed("shift"):
			velocity.x = move_toward(velocity.x, speed * input_dir_axis * 1.2, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)


func update_facing_direction(delta): #좌우 이동방향 바뀔 때 캐릭터 스프라이트 반전

	var player_face = direction.x

	if player_face > 0:
		sprite.flip_h = true
		player_direction = 1
		
	elif player_face < 0 :
		player_direction = -1
		sprite.flip_h = false


func update_suffix_direction(): #(미구현) 공격할 때 왼쪽 스프라이트 또는 오른쪽 스프라이트 출력
	var player_face = direction.x

	if player_face > 0:
		player_direction = 1
		suffix = "_right"
		
	elif player_face < 0 :
		player_direction = -1
		suffix = "_left"

func update_animation(): #애니메이션 트리 move 블렌드 포지션 적용 
	animationTree.set("parameters/move/blend_position",direction.x)

func ground_state(_delta): #캐릭터가 지면에 닿아있음

	hasDoubleJump = false
	max_height = 0.0

	jump()
	check_chara_on_ground()


func check_chara_on_ground() -> void: #지면에 발이 닿아있는지 확인 

	if !is_on_floor() and velocity.y > 0:
		state = air

func jump(): #도약  

	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = jumpVelocity
			state = air


func air_state(delta): #캐릭터의 상태가 공중에 떠있음 

	double_jump()
	max_fall_speed_controll()

	landing_or_ground(delta)
	is_hanging_on_wall()


func is_hanging_on_wall(): # 지면에 발이 떠있고 캐릭터가 벽에 붙어있는지 확인 
	if (rightRayCast.is_colliding() and !is_on_floor() and is_on_wall() and Input.is_action_pressed("move_right"))|| (leftRayCast.is_colliding() and !is_on_floor() and is_on_wall() and Input.is_action_pressed("move_left")) :
		max_height = 0.0
		state = hangingWall


func max_fall_speed_controll(): # 떨어지는 최대 속력 조정

	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED


func double_jump(): #2단도약  
	if(Input.is_action_just_pressed("jump") and !hasDoubleJump and !is_on_floor()):
		velocity.y = doubleJumpVelocity
		hasDoubleJump = true
		max_height = 0


func landing_or_ground(_delta): # 지면에 착지했을 때에 착지하기 전 속력값의 크기에 따라 착지모션 출력 

	if max_height < hard_landing_air_to_ground and is_on_floor():
		state = ground

	elif max_height > hard_landing_air_to_ground and is_on_floor():
		animationTree["parameters/conditions/hardLanding"] = true
		state = landing


func landing_state(delta): # 착지

	velocity.y = 0
	velocity.x = move_toward(velocity.x, 0, friction * delta)


func hangingWall_state(delta): #캐릭터가 벽에 매달려 있을 때
	
	velocity.y = move_toward(velocity.y, lerp(int(round(velocity.y)), 10, int(friction * delta)), delta * gravity) #캐릭터가 벽에 붙어있을 때에 지면으로 자연스럽게 미끄러짐. 
	
	if !is_on_floor() and !is_on_wall() or Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right")  :
		state = air
		animationTree["parameters/conditions/isHangWall"] = false
		max_height = 0

	from_wall_to_ground_state()



func from_wall_to_ground_state():

	if max_height < hard_landing_wall_to_ground and is_on_floor() :
		state = ground

	if max_height > hard_landing_wall_to_ground and is_on_floor():
		state = landing
		animationTree["parameters/conditions/hardLanding"] = true


func _landing_animation_finished(anim_name): 
	match anim_name:
		"landing":
			state = ground
			animationTree["parameters/conditions/hardLanding"] = false
		"dash_attack_ready":
			state = dashattack_active
			
		"dash_attack_active":
			able_move = true
			dash_attacking = true
			state = ground


func on_superArmored() -> void:
	is_superArmored = true
	print(is_superArmored)


func off_superArmored() -> void:
	is_superArmored = false
	print(is_superArmored)


func on_invincible() ->void:
	is_invincible = true


func off_invincible() -> void:
	is_invincible = false


func _animation_update() -> void:
	if is_on_floor():
		animationTree["parameters/conditions/isHangWall"] = false
		animationTree["parameters/conditions/fall"] = false
		animationTree["parameters/conditions/isOnFloor"] = true
	if velocity.y < 0 and !is_on_floor() :
		animationTree["parameters/conditions/isOnFloor"] = false
		animationTree["parameters/conditions/jump"] = true
		animationTree["parameters/conditions/fall"] = false
	elif velocity.y > 0 and !is_on_floor():
		animationTree["parameters/conditions/isOnFloor"] = false
		animationTree["parameters/conditions/fall"] = true
		animationTree["parameters/conditions/jump"] = false

	if !is_on_floor() and state == hangingWall:
		animationTree["parameters/conditions/fall"] = false
		animationTree["parameters/conditions/jump"] = false
		animationTree["parameters/conditions/isHangWall"] = true
