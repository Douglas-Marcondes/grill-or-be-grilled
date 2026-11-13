extends CharacterBody2D

## Galinha Real: chefe da fase 1, com tres golpes telegrafados e duas fases.
##
## Cada golpe tem uma resposta certa, lida pela cor do aviso acima da cabeca:
## - investida (amarelo): ela dispara pelo chao e machuca no contato -> esquivar
##   atraves dela ou pular por cima;
## - salto (laranja): ela pula e, ao pousar, solta uma onda de choque pelo chao
##   -> estar no ar na hora do pouso;
## - penas (vermelho): leque de projeteis -> esquivar ou ficar abaixo do leque.
## Antes os golpes davam dano por proximidade no fim do preparo, inclusive o
## salto, que acertava com o boss ainda no ar -- nao havia jogada de esquiva.
## Abaixo de metade da vida ela entra na fase 2: ataca mais rapido e com mais penas.

const Sprites = preload("res://scripts/sprites.gd")
const Impacto = preload("res://scripts/impacto.gd")

enum Golpe { INVESTIDA, SALTO, PENAS }

const COR_DO_GOLPE := {
	Golpe.INVESTIDA: Color("fbf236"),
	Golpe.SALTO: Color("df7126"),
	Golpe.PENAS: Color("d95763"),
}
## Ela acorda quando entra no quadro; com 620px acordava antes de aparecer e o
## braseiro da porta da arena caia dentro da luta.
const DISTANCIA_DE_DESPERTAR := 420.0
const VELOCIDADE_DA_INVESTIDA := 470.0
const DURACAO_DA_INVESTIDA := 0.5
const IMPULSO_DO_SALTO := -560.0
const ALCANCE_DA_ONDA := 150.0
const DANO := 2

## Ritmo por fase: [intervalo entre golpes, tempo de preparo, penas por leque].
const RITMO := [[2.4, 0.6, 3], [1.6, 0.45, 5]]

var sprite: Sprite2D
var aviso: Node2D
var health := 24
var max_health := 24
var gravity := 1300.0
var target: CharacterBody2D
var attack_timer := 1.3
var golpe: Golpe = Golpe.INVESTIDA
var attack_windup := 0.0
var investindo := 0.0
var saltando := false
var fase := 0
var facing := -1.0
var flash := 0.0
var balanco := 0.0
var defeated := false
var despertou := false


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 14
	capsule.height = 46
	shape.shape = capsule
	shape.position.y = -23
	add_child(shape)
	sprite = Sprites.montar(self, Sprites.GALINHA_REAL, 2)
	# O boss espera o jogador chegar e so entao entra em _animar; sem virar aqui
	# ele aguarda de costas para quem se aproxima.
	Sprites.virar(sprite, facing)
	aviso = AvisoDeGolpe.new()
	add_child(aviso)


func _physics_process(delta: float) -> void:
	if defeated or not _tem_alvo():
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	if absf(target.global_position.x - global_position.x) > DISTANCIA_DE_DESPERTAR and not despertou:
		velocity.x = 0.0
		move_and_slide()
		return
	despertou = true
	_lutar(delta)
	move_and_slide()
	_pousar_se_saltava()
	flash = maxf(0.0, flash - delta)
	_animar(delta)
	_avisar_vida()


func _tem_alvo() -> bool:
	if target and is_instance_valid(target):
		return true
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target = players[0]
	return false


func _lutar(delta: float) -> void:
	"""Uma decisao por frame: continuar a investida, o preparo ou escolher golpe."""
	if investindo > 0.0:
		_investir(delta)
		return
	if not saltando:
		facing = -1.0 if target.global_position.x < global_position.x else 1.0
	attack_timer -= delta
	if attack_windup > 0.0:
		velocity.x = 0.0
		attack_windup -= delta
		if attack_windup <= 0.0:
			_soltar_golpe()
	elif attack_timer <= 0.0 and is_on_floor():
		_preparar_golpe()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)


func _preparar_golpe() -> void:
	golpe = randi_range(0, 2) as Golpe
	attack_windup = RITMO[fase][1]
	attack_timer = RITMO[fase][0]


func _soltar_golpe() -> void:
	match golpe:
		Golpe.INVESTIDA:
			investindo = DURACAO_DA_INVESTIDA
		Golpe.SALTO:
			velocity.y = IMPULSO_DO_SALTO
			velocity.x = facing * 140.0
			saltando = true
		Golpe.PENAS:
			_lancar_penas(RITMO[fase][2])


func _investir(delta: float) -> void:
	"""Dispara pelo chao e machuca no contato; para na beira da arena."""
	investindo = maxf(0.0, investindo - delta)
	velocity.x = facing * VELOCIDADE_DA_INVESTIDA if _tem_chao_a_frente() else 0.0
	if absf(target.global_position.x - global_position.x) < 26.0 and absf(target.global_position.y - global_position.y) < 40.0:
		target.take_damage(DANO, global_position)


func _pousar_se_saltava() -> void:
	"""A onda de choque sai no pouso e so pega quem esta no chao."""
	if not saltando or not is_on_floor() or velocity.y < 0.0:
		return
	saltando = false
	velocity.x = 0.0
	Impacto.golpe(get_tree(), Impacto.PANCADA_DO_CHEFE)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.shockwave_effect(global_position, ALCANCE_DA_ONDA)
	if target.is_on_floor() and absf(target.global_position.x - global_position.x) < ALCANCE_DA_ONDA:
		target.take_damage(DANO, global_position)


func _lancar_penas(quantas: int) -> void:
	for i in quantas:
		var shot := Area2D.new()
		shot.set_script(preload("res://projectile.gd"))
		shot.global_position = global_position + Vector2(facing * 28.0, -43.0)
		var abertura := (float(i) / maxf(1.0, quantas - 1.0) - 0.5) * 0.56
		shot.direction = Vector2(facing, abertura).normalized()
		shot.speed = 350.0
		shot.damage = 1
		shot.color = Color("f7a14c")
		shot.target_mask = 1
		get_tree().current_scene.add_child(shot)


func _tem_chao_a_frente() -> bool:
	var inicio := global_position + Vector2(facing * 30.0, -10.0)
	var consulta := PhysicsRayQueryParameters2D.create(inicio, inicio + Vector2(0.0, 80.0), 1)
	consulta.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func take_damage(amount: int, _origem: Vector2 = Vector2.INF) -> void:
	if defeated:
		return
	health -= amount
	flash = 0.12
	if fase == 0 and health <= max_health / 2:
		_entrar_na_fase_2()
	if health <= 0:
		_ser_derrotada()


func _entrar_na_fase_2() -> void:
	fase = 1
	attack_timer = minf(attack_timer, 0.8)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.boss_enraged()


func _ser_derrotada() -> void:
	defeated = true
	collision_layer = 0
	collision_mask = 0
	Impacto.golpe(get_tree(), Impacto.QUEDA_DO_CHEFE)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.boss_defeated(global_position)
	queue_free()


func _avisar_vida() -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.update_boss_health(health, max_health)


func _animar(delta: float) -> void:
	if not sprite:
		return
	# Respiracao lenta parada, batida rapida durante o preparo do golpe: e o que
	# avisa o jogador que vem golpe antes de ele sair.
	balanco += delta * (14.0 if attack_windup > 0.0 else 3.0)
	sprite.frame = int(balanco) % 2
	Sprites.virar(sprite, facing)
	Sprites.piscar(sprite, flash, Color(1.0, 0.75, 0.7) if fase == 1 else Color.WHITE)
	aviso.cor = COR_DO_GOLPE[golpe]
	aviso.ativo = attack_windup > 0.0
	aviso.queue_redraw()


## Faixa piscante acima da Galinha Real durante o preparo do golpe, na cor do
## golpe que vem. Fica em no proprio para nao reintroduzir um _draw no corpo do
## boss, que agora e sprite.
class AvisoDeGolpe extends Node2D:
	## Logo acima da cabeca: o sprite da Galinha Real tem 46px de altura.
	const ALTURA_DO_AVISO := -52

	var ativo := false
	var cor := Color("fbf236")

	func _draw() -> void:
		if not ativo:
			return
		var pulso := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 60.0)
		draw_rect(Rect2(-24, ALTURA_DO_AVISO, 48, 3), Color(cor, pulso), true)
		# Exclamacao acima da faixa: haste e ponto.
		draw_rect(Rect2(-1, ALTURA_DO_AVISO - 12, 3, 6), Color(cor, pulso), true)
		draw_rect(Rect2(-1, ALTURA_DO_AVISO - 4, 3, 2), Color(cor, pulso), true)
