extends CharacterBody2D

const Movement = preload("res://scripts/character_movement.gd")

## Chicken patrol policy. Shared physical behavior lives in CharacterMovement.

@export var speed: float = 60.0
@export var gravidade: float = 980.0

var direcao: float = 1.0

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("andar"):
			sprite.play("andar")

func _physics_process(delta: float) -> void:
	Movement.apply_gravity(self, delta, gravidade)

	if is_on_wall():
		direcao *= -1.0

	Movement.set_horizontal_speed(self, direcao, speed)
	Movement.face_direction(self, direcao)

	move_and_slide()
