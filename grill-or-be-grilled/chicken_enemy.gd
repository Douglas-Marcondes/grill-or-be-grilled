extends CharacterBody2D

const Sprites = preload("res://scripts/sprites.gd")

var sprite: Sprite2D
var health := 3
var speed := 92.0
var gravity := 1000.0
var target: CharacterBody2D
var attack_cooldown := 0.0
var flash := 0.0
var facing := 1.0
var animation_time := 0.0
var jumping_gap := false
var last_safe_position := Vector2.ZERO
var home_position := Vector2.ZERO
var patrol_direction := 1.0

const EDGE_CHECK_DISTANCE := 28.0
const LANDING_CHECK_DISTANCE := 175.0
const GAP_JUMP_VELOCITY := -520.0
const GAP_JUMP_SPEED := 175.0
const THREAT_RANGE := 320.0
const PATROL_RADIUS := 135.0

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
	sprite = Sprites.montar(self, Sprites.GALINHA, 4)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if not target or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0]
	if target and is_instance_valid(target):
		var distance := target.global_position.x - global_position.x
		var vertical_distance := absf(target.global_position.y - global_position.y)
		if absf(distance) < THREAT_RANGE and vertical_distance < 150.0:
			facing = signf(distance) if not is_zero_approx(distance) else facing
			if is_on_floor() and not _has_floor_ahead(facing):
				if _has_landing_ahead(facing):
					velocity.y = GAP_JUMP_VELOCITY
					velocity.x = facing * GAP_JUMP_SPEED
					jumping_gap = true
				else:
					# Para no cair quando não há uma superfície alcançável à frente.
					velocity.x = 0.0
					move_and_slide()
					# Mesmo parada a galinha precisa atualizar o visual: sem isto,
					# uma galinha atingida na beirada fica branca de clarao para
					# sempre e nao vira de lado.
					flash = maxf(0.0, flash - delta)
					_animar()
					return
			else:
				velocity.x = facing * (GAP_JUMP_SPEED if jumping_gap else speed)
		else:
			_patrol()
	else:
		_patrol()
	attack_cooldown -= delta
	if target and is_instance_valid(target) and attack_cooldown <= 0.0 and absf(global_position.x - target.global_position.x) < 48.0 and absf(global_position.y - target.global_position.y) < 48.0:
		target.take_damage(1)
		attack_cooldown = 1.1
	move_and_slide()
	if is_on_floor():
		last_safe_position = global_position
		jumping_gap = false
		if absf(velocity.x) > 1.0:
			animation_time += delta * 13.0
	flash = maxf(0.0, flash - delta)
	_animar()
	if global_position.y > 850.0:
		# Se um impulso externo ainda a derrubar, deixa o drop na última plataforma segura.
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.spawn_egg(last_safe_position + Vector2(0, -14))
			game.enemy_defeated()
		queue_free()

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

func take_damage(amount: int) -> void:
	health -= amount
	flash = 0.14
	if health <= 0:
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.spawn_egg(global_position + Vector2(0, -14))
			game.enemy_defeated()
		queue_free()

func _animar() -> void:
	if not sprite:
		return
	Sprites.virar(sprite, facing)
	Sprites.piscar(sprite, flash)
	sprite.frame = Sprites.quadro_do_passo(animation_time, 4)
