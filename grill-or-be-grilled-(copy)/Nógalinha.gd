extends Node2D

@export var speed: float = 60.0
@export var tempo_virar: float = 2.0
@export var vida: int = 2

var direcao: float = 1.0
var esta_invulneravel: bool = false
var temporizador: float = 0.0

@onready var sprite: CanvasItem = get_node_or_null("AnimatedSprite2D") if has_node("AnimatedSprite2D") else get_node_or_null("Sprite2D")

func _ready() -> void:
	print("--- GALINHA CRIADA COM SUCESSO ---")
	if sprite is AnimatedSprite2D and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("andar"):
			sprite.play("andar")

func _process(delta: float) -> void:
	position.x += direcao * speed * delta

	temporizador += delta
	if temporizador >= tempo_virar:
		direcao *= -1.0
		temporizador = 0.0

	if sprite and "flip_h" in sprite:
		sprite.flip_h = (direcao < 0)

func levar_dano(quantidade: int) -> void:
	if esta_invulneravel:
		return

	vida -= quantidade
	print("Dano recebido! Vida agora: ", vida)

	if vida <= 0:
		print("Galinha a ser destruída com queue_free()!")
		queue_free()
		return

	esta_invulneravel = true
	modulate = Color(2.0, 0.2, 0.2)
	await get_tree().create_timer(0.12).timeout
	modulate = Color.WHITE
	esta_invulneravel = false
