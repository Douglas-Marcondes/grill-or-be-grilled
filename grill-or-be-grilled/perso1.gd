extends CharacterBody2D

const Movement = preload("res://scripts/character_movement.gd")

## Player input policy. Shared physical behavior lives in CharacterMovement.

@export var speed: float = 500.0
@export var jump_velocity: float = -600.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	Movement.apply_gravity(self, delta, gravity)

	# Pulo com a SETA PARA CIMA quando pisando no chão
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# Movimento horizontal com as setas esquerda e direita
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		Movement.set_horizontal_speed(self, direction, speed)
		Movement.face_direction(self, direction)
	else:
		Movement.stop_horizontal(self, speed * 60.0, delta)

	move_and_slide()
