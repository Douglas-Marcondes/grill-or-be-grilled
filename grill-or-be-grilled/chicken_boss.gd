extends CharacterBody2D

var health := 24
var max_health := 24
var gravity := 1300.0
var target: CharacterBody2D
var attack_timer := 1.3
var attack_kind := 0
var attack_windup := 0.0
var facing := -1.0
var flash := 0.0
var defeated := false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 27
	capsule.height = 68
	shape.shape = capsule
	shape.position.y = -34
	add_child(shape)

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
	queue_redraw()
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.update_boss_health(health, max_health)

func perform_attack() -> void:
	if attack_kind == 0:
		velocity.x = facing * 560.0
		if is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 105.0 and absf(target.global_position.y - global_position.y) < 80.0:
			target.take_damage(2)
	elif attack_kind == 1:
		if is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 135.0:
			target.take_damage(2)
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

func take_damage(amount: int) -> void:
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

func _draw() -> void:
	var feathers := Color("fff0ce") if flash <= 0.0 else Color.WHITE
	draw_rect(Rect2(-33, -56, 66, 48), feathers, true)
	draw_rect(Rect2(-42, -38, 15, 19), Color("d6ad7b"), true)
	draw_rect(Rect2(27, -38, 15, 19), Color("d6ad7b"), true)
	draw_rect(Rect2(-27, -68, 54, 30), Color("fff5dc"), true)
	draw_rect(Rect2(-18, -64, 6, 7), Color("302738"), true)
	draw_rect(Rect2(12, -64, 6, 7), Color("302738"), true)
	var beak_x := 21.0 if facing > 0.0 else -41.0
	draw_rect(Rect2(beak_x, -57, 20, 10), Color("ed7652"), true)
	draw_rect(Rect2(-14, -77, 15, 12), Color("e24e4e"), true)
	draw_rect(Rect2(-7, -88, 13, 12), Color("ef6653"), true)
	draw_rect(Rect2(-23, -8, 14, 12), Color("e2aa58"), true)
	draw_rect(Rect2(9, -8, 14, 12), Color("e2aa58"), true)
	if attack_windup > 0.0:
		var warn_color := Color("ffed78", 0.75 + 0.25 * sin(Time.get_ticks_msec() / 60.0))
		draw_rect(Rect2(-36, -99, 72, 4), warn_color, true)
