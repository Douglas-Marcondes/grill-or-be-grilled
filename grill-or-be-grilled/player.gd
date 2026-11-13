extends CharacterBody2D

const Sprites = preload("res://scripts/sprites.gd")
const Limites = preload("res://scripts/limites.gd")
const Movimento = preload("res://scripts/character_movement.gd")
const Salto = preload("res://scripts/salto.gd")
const Esquiva = preload("res://scripts/esquiva.gd")
const CameraDoHeroi = preload("res://scripts/camera_do_heroi.gd")
const Impacto = preload("res://scripts/impacto.gd")

var sprite: Sprite2D
var arma: Sprite2D
var largura_da_arma := 0.0
var sprite_armadura: Sprite2D

## Onde a arma e segurada, em relacao ao pe do heroi. A mao do sprite fica nas
## linhas 12 a 15 das 26 do corpo, ou seja por volta de -12.
const ALTURA_DA_MAO := -12.0
const ALCANCE_DA_MAO := 5.0

## Chegar aos 270px/s em 0.1s le como resposta imediata sem ser liga/desliga.
## No ar o controle e mais fraco e o atrito quase nulo: o pulo conserva o
## impulso em vez de o heroi parar no lugar quando a direcao e solta.
const ACELERACAO_NO_CHAO := 2700.0
const ATRITO_NO_CHAO := 2300.0
const ACELERACAO_NO_AR := 1500.0
const ATRITO_NO_AR := 500.0

var speed := 270.0
var max_health := 50
var health := 50
var facing := 1.0
var attack_timer := 0.0
var invulnerability := 0.0
var class_name_game := "Guerreiro"
var animation_time := 0.0
var salto := Salto.new()
var knockback := 0.0
var esquiva := Esquiva.new()
var camera: Camera2D

## Empurrao ao tomar dano: para longe de QUEM bateu, nao para tras do heroi --
## virado de costas para a galinha, ele era jogado para dentro dela.
const EMPURRAO := Vector2(190.0, -150.0)
const INVULNERAVEL_APOS_DANO := 0.9
## Ressalto que o heroi sobe sem pular. 8px cobre a quina da capsula (3px) e as
## emendas do layout sem virar escada: degrau de verdade (20px+) ainda exige pulo.
const ALTURA_DO_DEGRAU := 8.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 7
	capsule.height = 26
	shape.shape = capsule
	shape.position.y = -13
	add_child(shape)
	camera = CameraDoHeroi.new()
	add_child(camera)
	max_health += GameData.health_bonus
	health = max_health

func configure(class_name_value: String) -> void:
	class_name_game = class_name_value
	if GameData.equipped_weapon.is_empty():
		GameData.equipped_weapon = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}.get(class_name_game, "Espada")
	_montar_visual()


func _montar_visual() -> void:
	"""Monta corpo, arma e armadura. Chamado depois de configure porque a folha
	do corpo depende da classe e a da arma, do que esta equipado."""
	sprite = Sprites.montar(self, "heroi_%s" % class_name_game.to_lower(), 4)
	var folha_da_arma := "arma_%s" % GameData.equipped_weapon.to_lower()
	largura_da_arma = Sprites.celula(folha_da_arma, 1).x
	arma = Sprites.montar_centrado(self, folha_da_arma, 1)
	if arma:
		arma.position.y = ALTURA_DA_MAO
	if GameData.owns_chicken_armor:
		sprite_armadura = Sprites.montar(self, "armadura_galinha", 1)
		if sprite_armadura:
			sprite_armadura.position = Vector2(0, -24)

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("andar_esquerda", "andar_direita")
	if not is_zero_approx(direction) and not esquiva.ativa():
		facing = signf(direction)
	camera.direcao = facing
	_resolver_horizontal(direction, delta)
	salto.atualizar(self, delta, Input.is_action_just_pressed("pular"), Input.is_action_pressed("pular"))
	attack_timer = maxf(0.0, attack_timer - delta)
	if Input.is_action_just_pressed("atacar") and attack_timer <= 0.0:
		attack()
	invulnerability = maxf(0.0, invulnerability - delta)
	move_and_slide()
	Movimento.climb_step(self, direction, ALTURA_DO_DEGRAU)
	if global_position.y > Limites.QUEDA_FATAL:
		$"..".player_died()
		set_physics_process(false)
		return
	if is_on_floor() and absf(velocity.x) > 1.0:
		animation_time += delta * 11.0
	_animar()


func _resolver_horizontal(direction: float, delta: float) -> void:
	"""Esquiva, empurrao de dano ou corrida normal, nessa prioridade."""
	esquiva.atualizar(delta)
	if Input.is_action_just_pressed("esquivar") and knockback <= 0.0:
		esquiva.iniciar()
	if esquiva.ativa():
		velocity.x = facing * Esquiva.VELOCIDADE
		return
	if knockback > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 380.0 * delta)
		knockback = maxf(0.0, knockback - delta)
		return
	_mover_horizontal(direction, delta)


func _deixar_rastro() -> void:
	"""Copia translucida do corpo que some: e o que mostra que a esquiva saiu."""
	if not sprite:
		return
	var rastro := sprite.duplicate() as Sprite2D
	rastro.global_position = sprite.global_position
	rastro.modulate = Color(0.6, 0.85, 1.0, 0.6)
	get_parent().add_child(rastro)
	var sumir := rastro.create_tween()
	sumir.tween_property(rastro, "modulate:a", 0.0, 0.25)
	sumir.tween_callback(rastro.queue_free)


func _mover_horizontal(direction: float, delta: float) -> void:
	"""Escolhe a taxa pelo par chao/ar e acelerando/freando; quem move e a
	primitiva compartilhada."""
	var acelerando := not is_zero_approx(direction)
	var taxa := ACELERACAO_NO_CHAO if acelerando else ATRITO_NO_CHAO
	if not is_on_floor():
		taxa = ACELERACAO_NO_AR if acelerando else ATRITO_NO_AR
	Movimento.accelerate_horizontal(self, direction, speed, taxa, delta)


func _animar() -> void:
	if not sprite:
		return
	# Pisca durante a invulnerabilidade em vez de sumir com o personagem: some
	# o jogador por 0.9s e ele perde a nocao de onde esta.
	var visivel := invulnerability <= 0.0 or int(Time.get_ticks_msec() / 90) % 2 == 0
	if esquiva.ativa() and sprite:
		_deixar_rastro()
	for parte in [sprite, arma, sprite_armadura]:
		if not parte:
			continue
		Sprites.virar(parte, facing)
		parte.visible = visivel
	sprite.frame = 0 if is_on_floor() and absf(velocity.x) <= 1.0 else Sprites.quadro_do_passo(animation_time, 4)
	if arma:
		# A arma e ancorada pelo CABO na mao, nao pelo centro: centrada, a lamina
		# de 20px da espada atravessava o corpo inteiro do heroi.
		arma.offset.x = 0.0 if facing > 0.0 else -largura_da_arma
		# Avanca no instante do golpe; fora dele volta para o lado do corpo.
		var avanco := 5.0 if attack_timer > 0.24 else 0.0
		arma.position.x = facing * (ALCANCE_DA_MAO + avanco)

func attack() -> void:
	attack_timer = 0.38
	var damage := 1 + int(GameData.strength_bonus / 5)
	if GameData.equipped_weapon == "Espada":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and absf(enemy.global_position.x - global_position.x - facing * 24.0) < 27.0 and absf(enemy.global_position.y - global_position.y) < 27.0:
				enemy.take_damage(damage + 1, global_position)
				Impacto.golpe(get_tree(), Impacto.ACERTO)
		$"..".slash_effect(global_position + Vector2(facing * 26.0, ALTURA_DA_MAO), facing, false)
	else:
		var shot := Area2D.new()
		shot.set_script(preload("res://projectile.gd"))
		shot.global_position = global_position + Vector2(facing * 23.0, ALTURA_DA_MAO)
		shot.direction = Vector2(facing, 0)
		shot.damage = damage
		shot.speed = 570.0 if GameData.equipped_weapon == "Arco" else 430.0
		shot.color = Color("b4e17b") if GameData.equipped_weapon == "Arco" else Color("bd9aff")
		get_tree().current_scene.add_child(shot)
		$"..".slash_effect(global_position + Vector2(facing * 23.0, ALTURA_DA_MAO), facing, true)

func take_damage(amount: int, origem: Vector2 = Vector2.INF) -> void:
	"""Dano vindo de `origem` (posicao de quem bateu). Ignorado durante a
	invulnerabilidade pos-dano e durante a esquiva."""
	if invulnerability > 0.0 or esquiva.protege():
		return
	health -= maxi(1, amount - GameData.armor_bonus)
	invulnerability = INVULNERAVEL_APOS_DANO
	var lado := -facing if not origem.is_finite() else signf(global_position.x - origem.x)
	knockback = 0.22
	velocity = Vector2((lado if not is_zero_approx(lado) else -facing) * EMPURRAO.x, EMPURRAO.y)
	Impacto.golpe(get_tree(), Impacto.DANO_NO_HEROI)
	$"..".update_hud()
	if health <= 0:
		$"..".player_died()
		set_physics_process(false)
