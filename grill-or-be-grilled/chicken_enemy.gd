extends CharacterBody2D

## Galinha comum: patrulha perto de casa, persegue o heroi e bica com aviso.
##
## E tambem a base das variantes (galo.gd, galinha_atiradeira.gd): elas trocam
## so o que muda -- `_perseguir` (como se posiciona) e `_atacar` (o golpe) --
## e herdam patrulha, pulo de vao, hitstun, queda e drop de ovo.

const Sprites = preload("res://scripts/sprites.gd")
const Limites = preload("res://scripts/limites.gd")

var sprite: Sprite2D
var health := 3
var speed := 92.0
var gravity := 1000.0
var target: CharacterBody2D
var attack_cooldown := 0.0
var attack_windup := 0.0
var hit_stun := 0.0
var flash := 0.0
var facing := 1.0
var animation_time := 0.0
var jumping_gap := false
var last_safe_position := Vector2.ZERO
var home_position := Vector2.ZERO
var patrol_direction := 1.0
## Definida por quem cria o inimigo, a partir de scripts/bestiario.gd.
var folha_do_sprite := Sprites.GALINHA

const EDGE_CHECK_DISTANCE := 28.0
const LANDING_CHECK_DISTANCE := 175.0
const GAP_JUMP_VELOCITY := -520.0
const GAP_JUMP_SPEED := 175.0
## Menor que a meia tela a frente do heroi (~270px com o olhar da camera): com
## 320px as galinhas comecavam a perseguir de fora do quadro (PENDENCIAS.md).
const THREAT_RANGE := 250.0
const PATROL_RADIUS := 135.0
const PECK_WINDUP := 0.48
const PECK_COOLDOWN := 1.35
## Cor do aviso de golpe, piscando com o branco.
const COR_DO_AVISO := Color("fbf236")


func configure_progression(progress: float) -> void:
	"""Mais vida e velocidade conforme o avanco na fase (0 = inicio, 1 = ninho).

	Pelo X do marcador e nao pela ordem na cena: marcador novo entra no fim da
	lista mesmo quando posto no meio da fase."""
	health = 2 + int(progress * 2.0)
	speed = 78.0 + progress * 38.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 9
	capsule.height = 23
	shape.shape = capsule
	shape.position.y = -11
	add_child(shape)
	last_safe_position = global_position
	home_position = global_position
	sprite = Sprites.montar(self, folha_do_sprite, 4)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	flash = maxf(0.0, flash - delta)
	if hit_stun > 0.0:
		hit_stun = maxf(0.0, hit_stun - delta)
		velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
		move_and_slide()
		_animar()
		return
	_decidir(delta)
	move_and_slide()
	_depois_de_mover(delta)


func _decidir(delta: float) -> void:
	_achar_alvo()
	if _ameacada():
		_perseguir()
	else:
		_patrol()
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	_atacar(delta)


func _achar_alvo() -> void:
	if target and is_instance_valid(target):
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target = players[0]


func _ameacada() -> bool:
	if not target or not is_instance_valid(target):
		return false
	var distance := absf(target.global_position.x - global_position.x)
	return distance < THREAT_RANGE and absf(target.global_position.y - global_position.y) < 150.0


func _virar_para_o_alvo() -> float:
	"""Vira para o heroi e devolve a distancia horizontal ate ele (com sinal)."""
	var distance := target.global_position.x - global_position.x
	if not is_zero_approx(distance):
		facing = signf(distance)
	return distance


func _perseguir() -> void:
	"""Vai direto ao heroi; para enquanto prepara a bicada."""
	_virar_para_o_alvo()
	_andar(facing, 0.0 if attack_windup > 0.0 else speed)


func _andar(direcao: float, rapidez: float) -> void:
	"""Anda em `direcao`; na beira, pula o vao se houver pouso ou para."""
	if not is_on_floor() or _has_floor_ahead(direcao):
		velocity.x = direcao * (GAP_JUMP_SPEED if jumping_gap else rapidez)
		return
	if is_zero_approx(rapidez) or not _has_landing_ahead(direcao):
		velocity.x = 0.0
		return
	velocity.y = GAP_JUMP_VELOCITY
	velocity.x = direcao * GAP_JUMP_SPEED
	jumping_gap = true


func _atacar(delta: float) -> void:
	"""Bicada: aviso piscando por PECK_WINDUP e dano so se o heroi ficou perto."""
	if attack_windup > 0.0:
		attack_windup -= delta
		if attack_windup <= 0.0 and _player_in_peck_range():
			target.take_damage(1, global_position)
			attack_cooldown = PECK_COOLDOWN
	elif attack_cooldown <= 0.0 and _player_in_peck_range():
		attack_windup = PECK_WINDUP


func _depois_de_mover(delta: float) -> void:
	if is_on_floor():
		last_safe_position = global_position
		jumping_gap = false
		if absf(velocity.x) > 1.0:
			animation_time += delta * 13.0
	_animar()
	if global_position.y > Limites.QUEDA_FATAL:
		# Se um impulso externo ainda a derrubar, deixa o drop na última plataforma segura.
		_morrer(last_safe_position)


func _patrol() -> void:
	if global_position.x > home_position.x + PATROL_RADIUS:
		patrol_direction = -1.0
	elif global_position.x < home_position.x - PATROL_RADIUS:
		patrol_direction = 1.0
	facing = patrol_direction
	if is_on_floor() and not _has_floor_ahead(facing):
		if _has_landing_ahead(facing) and absf(global_position.x - home_position.x) < PATROL_RADIUS:
			velocity.y = GAP_JUMP_VELOCITY
			velocity.x = facing * GAP_JUMP_SPEED
			jumping_gap = true
		else:
			patrol_direction *= -1.0
			facing = patrol_direction
			velocity.x = 0.0
	else:
		velocity.x = facing * (GAP_JUMP_SPEED if jumping_gap else speed * 0.55)


func _has_floor_ahead(direction: float) -> bool:
	var start := global_position + Vector2(direction * EDGE_CHECK_DISTANCE, -10.0)
	var finish := start + Vector2(0.0, 140.0)
	var query := PhysicsRayQueryParameters2D.create(start, finish, 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _has_landing_ahead(direction: float) -> bool:
	var start := global_position + Vector2(direction * LANDING_CHECK_DISTANCE, -45.0)
	var finish := start + Vector2(0.0, 170.0)
	var query := PhysicsRayQueryParameters2D.create(start, finish, 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func take_damage(amount: int, origem: Vector2 = Vector2.INF) -> void:
	"""Dano com recuo para longe de `origem`; o golpe cancela o preparo da bicada."""
	health -= amount
	flash = 0.14
	hit_stun = 0.16
	attack_windup = 0.0
	velocity.x = signf(global_position.x - origem.x) * 115.0 if origem.is_finite() else 0.0
	if health <= 0:
		_morrer(global_position)


func _morrer(onde: Vector2) -> void:
	# Golpe e queda podem chegar no mesmo frame; sem a trava a galinha contava
	# duas vezes no placar e soltava dois ovos.
	if is_queued_for_deletion():
		return
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.spawn_egg(onde + Vector2(0, -14))
		game.enemy_defeated()
	queue_free()


func _animar() -> void:
	if not sprite:
		return
	Sprites.virar(sprite, facing)
	Sprites.piscar(sprite, flash)
	sprite.frame = Sprites.quadro_do_passo(animation_time, 4)
	if attack_windup > 0.0 and flash <= 0.0:
		sprite.modulate = COR_DO_AVISO if int(Time.get_ticks_msec() / 90) % 2 == 0 else Color.WHITE


func _player_in_peck_range() -> bool:
	return is_instance_valid(target) and absf(global_position.x - target.global_position.x) < 31.0 and absf(global_position.y - target.global_position.y) < 27.0
