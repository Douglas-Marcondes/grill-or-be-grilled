extends CharacterBody2D

@export var speed: float = 60.0
@export var gravidade: float = 980.0

var direcao: float = 1.0

# Usar get_node_or_null para evitar travamento caso o nó tenha outro nome
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("andar"):
			sprite.play("andar")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta

	if is_on_wall():
		direcao *= -1.0

	velocity.x = direcao * speed

	if sprite:
		if direcao > 0:
			sprite.flip_h = false
		elif direcao < 0:
			sprite.flip_h = true

	move_and_slide()
