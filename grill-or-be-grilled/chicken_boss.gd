extends CharacterBody2D

const Sprites = preload("res://scripts/sprites.gd")

var sprite: Sprite2D
var aviso: Node2D
var health := 24
var max_health := 24
var gravity := 1300.0
var target: CharacterBody2D
var attack_timer := 1.3
var attack_kind := 0
var attack_windup := 0.0
var facing := -1.0
var flash := 0.0
var balanco := 0.0
var defeated := false

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
	aviso = AvisoDeInvestida.new()
	add_child(aviso)

func _physics_process(delta: float) -> void:
	if defeated:
		return
	if not target or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0]
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	# O boss aguarda na arena final e só começa o combate quando o jogador se aproxima.
	if absf(target.global_position.x - global_position.x) > 620.0:
		velocity.x = 0.0
		move_and_slide()
		return
	facing = signf(target.global_position.x - global_position.x)
	if is_zero_approx(facing):
		facing = -1.0
	attack_timer -= delta
	if attack_windup > 0.0:
		attack_windup -= delta
		if attack_windup <= 0.0:
			perform_attack()
	elif attack_timer <= 0.0:
		attack_kind = randi_range(0, 2)
		attack_windup = 0.55
		attack_timer = 2.5
		if attack_kind == 1 and is_on_floor():
			velocity.y = -560.0
	velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
	if attack_windup > 0.0:
		velocity.x = 0.0
	move_and_slide()
	flash = maxf(0.0, flash - delta)
	_animar(delta)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.update_boss_health(health, max_health)

func perform_attack() -> void:
	if attack_kind == 0:
		velocity.x = facing * 560.0
		if is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 105.0 and absf(target.global_position.y - global_position.y) < 80.0:
			target.take_damage(2, global_position)
	elif attack_kind == 1:
		if is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 135.0:
			target.take_damage(2, global_position)
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.slash_effect(global_position + Vector2(0, -9), 1.0, true, Color("ffb94f"))
	else:
		for i in 3:
			var shot := Area2D.new()
			shot.set_script(preload("res://projectile.gd"))
			shot.global_position = global_position + Vector2(facing * 28.0, -43.0)
			shot.direction = Vector2(facing, (i - 1) * 0.28).normalized()
			shot.speed = 350.0
			shot.damage = 1
			shot.color = Color("f7a14c")
			shot.target_mask = 1
			get_tree().current_scene.add_child(shot)

func take_damage(amount: int, _origem: Vector2 = Vector2.INF) -> void:
	if defeated:
		return
	health -= amount
	flash = 0.12
	if health <= 0:
		defeated = true
		collision_layer = 0
		collision_mask = 0
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.boss_defeated(global_position)
		queue_free()

func _animar(delta: float) -> void:
	if not sprite:
		return
	# Respiracao lenta parada, batida rapida durante o preparo do golpe: e o que
	# avisa o jogador que vem investida antes de ela sair.
	balanco += delta * (14.0 if attack_windup > 0.0 else 3.0)
	sprite.frame = int(balanco) % 2
	Sprites.virar(sprite, facing)
	Sprites.piscar(sprite, flash)
	if aviso:
		aviso.ativo = attack_windup > 0.0
		aviso.queue_redraw()


## Faixa piscante acima da Galinha Real durante o preparo do ataque. Fica em no
## proprio para nao reintroduzir um _draw no corpo do boss, que agora e sprite.
class AvisoDeInvestida extends Node2D:
	## Logo acima da cabeca: o sprite da Galinha Real tem 46px de altura.
	const ALTURA_DO_AVISO := -52

	var ativo := false

	func _draw() -> void:
		if not ativo:
			return
		var pulso := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 60.0)
		draw_rect(Rect2(-24, ALTURA_DO_AVISO, 48, 3), Color("fbf236", pulso), true)
