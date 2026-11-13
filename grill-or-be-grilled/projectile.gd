extends Area2D

## Projetil reto (flecha, magia, pena do chefe) ou em arco (ovo da atiradeira).
##
## `target_mask` diz quem ele fere: 2 = inimigos (tiro do heroi), 1 = heroi.
## A camada 1 tambem e a do terreno; com `quebra_no_terreno` o projetil some ao
## bater numa plataforma em vez de atravessar a fase.

const Impacto = preload("res://scripts/impacto.gd")
const CAMADA_DOS_INIMIGOS := 2

var direction := Vector2.RIGHT
var speed := 480.0
var damage := 1
var color := Color("ffe38a")
var lifetime := 2.0
var target_mask := 2
var gravidade := 0.0
## "barra" para flecha/magia/pena, "ovo" para o ovo arremessado.
var forma := "barra"
var _velocidade := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = target_mask
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9 if forma == "barra" else 5
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_velocidade = direction * speed


func _physics_process(delta: float) -> void:
	_velocidade.y += gravidade * delta
	global_position += _velocidade * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	if forma == "ovo":
		draw_rect(Rect2(-3, -4, 6, 8), color, true)
		draw_rect(Rect2(-2, -5, 4, 10), color, true)
		draw_rect(Rect2(-1, -3, 2, 2), Color.WHITE, true)
		return
	draw_rect(Rect2(-8, -3, 16, 6), color, true)
	draw_rect(Rect2(-3, -6, 6, 12), color.lightened(0.3), true)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		if target_mask == CAMADA_DOS_INIMIGOS:
			Impacto.golpe(get_tree(), Impacto.ACERTO)
		queue_free()
	elif forma == "ovo":
		# Ovo quebra no chao; flecha e pena seguem como antes, atravessando a
		# fase -- mudar isso mexeria no alcance das classes de tiro.
		queue_free()
