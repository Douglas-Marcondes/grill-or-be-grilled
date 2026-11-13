extends Area2D

## Projetil reto (flecha, magia, pena do chefe) ou em arco (ovo da atiradeira).
##
## `target_mask` diz quem ele fere: 2 = inimigos (tiro do heroi), 1 = heroi.
## A camada 1 tambem e a do terreno; com `quebra_no_terreno` o projetil some ao
## bater numa plataforma em vez de atravessar a fase.

const Impacto = preload("res://scripts/impacto.gd")
const Sprites = preload("res://scripts/sprites.gd")
const Iluminacao = preload("res://scripts/iluminacao.gd")
const CAMADA_DOS_INIMIGOS := 2
## Quadros de Artes/gerado/projeteis.png (tools/arte/projeteis.py), nessa ordem.
const TIPOS := ["flecha", "magia", "pena", "ovo"]
const COR_DA_MAGIA := Color(0.85, 0.6, 1.0)

var direction := Vector2.RIGHT
var speed := 480.0
var damage := 1
var lifetime := 2.0
var target_mask := 2
var gravidade := 0.0
## Um de TIPOS: escolhe o sprite e o comportamento (so o ovo quebra no chao).
var tipo := "flecha"
var _velocidade := Vector2.ZERO
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = target_mask
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5 if tipo == "ovo" else 9
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_velocidade = direction * speed
	_montar_visual()


func _montar_visual() -> void:
	var quadro := TIPOS.find(tipo)
	if quadro < 0:
		push_error("tipo de projetil desconhecido: \"%s\"; esperado um de %s" % [tipo, TIPOS])
		return
	_sprite = Sprites.montar_centrado(self, "projeteis", TIPOS.size())
	if _sprite:
		_sprite.frame = quadro
		_sprite.rotation = _velocidade.angle()
	if tipo == "magia":
		# A magia brilha: no porao escuro o orbe ilumina o caminho que faz.
		add_child(Iluminacao.luz(COR_DA_MAGIA, 0.8, 0.5))


func _physics_process(delta: float) -> void:
	_velocidade.y += gravidade * delta
	global_position += _velocidade * delta
	if _sprite and tipo != "magia":
		_sprite.rotation = _velocidade.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		if target_mask == CAMADA_DOS_INIMIGOS:
			Impacto.golpe(get_tree(), Impacto.ACERTO)
		queue_free()
	elif tipo == "ovo":
		# Ovo quebra no chao; flecha e pena seguem como antes, atravessando a
		# fase -- mudar isso mexeria no alcance das classes de tiro.
		queue_free()
