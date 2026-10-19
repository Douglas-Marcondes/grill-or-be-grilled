extends CharacterBody2D

const Sprites = preload("res://scripts/sprites.gd")

var sprite: Sprite2D
var arma: Sprite2D
var largura_da_arma := 0.0
var sprite_armadura: Sprite2D

## Onde a arma e segurada, em relacao ao pe do heroi. A mao do sprite fica nas
## linhas 12 a 15 das 26 do corpo, ou seja por volta de -12.
const ALTURA_DA_MAO := -12.0
const ALCANCE_DA_MAO := 5.0

var speed := 270.0
var jump_velocity := -520.0
var gravity := 1300.0
var max_health := 50
var health := 50
var facing := 1.0
var attack_timer := 0.0
var invulnerability := 0.0
var class_name_game := "Guerreiro"
var jump_was_down := false
var attack_was_down := false
var animation_time := 0.0

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
	var camera := Camera2D.new()
	# Viewport de 270px de altura: olhar 120px acima jogaria o personagem para
	# fora do quadro, entao a folga de cima caiu junto com a resolucao.
	camera.position = Vector2(0, -40)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
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
	if not is_on_floor():
		velocity.y += gravity * delta
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		direction = -1.0
	if Input.is_key_pressed(KEY_D):
		direction = 1.0
	if not is_zero_approx(direction):
		facing = direction
	velocity.x = direction * speed
	var jump_down := Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_up")
	if jump_down and not jump_was_down and is_on_floor():
		velocity.y = jump_velocity
	jump_was_down = jump_down
	var attack_down := Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_K) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	attack_timer = maxf(0.0, attack_timer - delta)
	if attack_down and not attack_was_down and attack_timer <= 0.0:
		attack()
	attack_was_down = attack_down
	invulnerability = maxf(0.0, invulnerability - delta)
	move_and_slide()
	if global_position.y > 850.0:
		$"..".player_died()
		set_physics_process(false)
		return
	if is_on_floor() and absf(velocity.x) > 1.0:
		animation_time += delta * 11.0
	_animar()


func _animar() -> void:
	if not sprite:
		return
	# Pisca durante a invulnerabilidade em vez de sumir com o personagem: some
	# o jogador por 0.9s e ele perde a nocao de onde esta.
	var visivel := invulnerability <= 0.0 or int(Time.get_ticks_msec() / 90) % 2 == 0
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
			if is_instance_valid(enemy) and absf(enemy.global_position.x - global_position.x - facing * 26.0) < 67.0 and absf(enemy.global_position.y - global_position.y) < 54.0:
				enemy.take_damage(damage + 1)
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

func take_damage(amount: int) -> void:
	if invulnerability > 0.0:
		return
	health -= maxi(1, amount - GameData.armor_bonus)
	invulnerability = 0.9
	$"..".update_hud()
	if health <= 0:
		$"..".player_died()
		set_physics_process(false)
