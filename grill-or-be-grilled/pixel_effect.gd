extends Node2D

const Sprites = preload("res://scripts/sprites.gd")
## Folha Artes/gerado/corte.png (tools/arte/efeitos.py).
const QUADROS_DE_CORTE := 4

var kind := "slash"
var direction := 1.0
var tint := Color("ffe18b")
var age := 0.0
var duration := 0.25
var sparks: Array[Vector2] = []
var reach_onda := 150.0
var _corte: Sprite2D

func _ready() -> void:
	if kind == "onda":
		duration = 0.4
	elif kind == "burst":
		duration = 1.5
		for i in 34:
			var angle := TAU * float(i) / 34.0 + randf_range(-0.12, 0.12)
			sparks.append(Vector2.from_angle(angle) * randf_range(20.0, 125.0))
	elif kind == "corte":
		duration = 0.16
		_corte = Sprites.montar_centrado(self, "corte", QUADROS_DE_CORTE)
		Sprites.virar(_corte, direction)
	else:
		duration = 0.2

func _process(delta: float) -> void:
	age += delta
	if _corte:
		_corte.frame = mini(int(age / duration * QUADROS_DE_CORTE), QUADROS_DE_CORTE - 1)
	queue_redraw()
	if age >= duration:
		queue_free()

func _draw() -> void:
	var progress := clampf(age / duration, 0.0, 1.0)
	if kind == "corte":
		return
	if kind == "onda":
		# Onda de choque rente ao chao: dois arcos que correm para os lados ate o
		# alcance real do golpe, para o jogador ver onde ela pega.
		var frente := reach_onda * progress
		for lado in [-1.0, 1.0]:
			draw_rect(Rect2(lado * frente - 4, -10, 8, 10), Color(0.87, 0.44, 0.15, 1.0 - progress), true)
			draw_rect(Rect2(minf(0.0, lado * frente), -2, absf(frente), 2), Color(0.98, 0.95, 0.21, 0.6 * (1.0 - progress)), true)
	elif kind == "burst":
		var radius := 18.0 + progress * 85.0
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.88, 0.48, 0.30 * (1.0 - progress)))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.96, 0.72, 0.95 * (1.0 - progress)), 5.0)
		for point in sparks:
			var p := point * progress
			draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color(1.0, 0.75 + randf() * 0.2, 0.35, 1.0 - progress), true)
	else:
		var reach := 8.0 + progress * 28.0
		draw_arc(Vector2.ZERO, reach, -1.2, 1.2, 12, Color(tint.r, tint.g, tint.b, 1.0 - progress), 5.0)
		draw_rect(Rect2(-3, -3, 7, 7), Color(1, 1, 1, 1.0 - progress), true)
