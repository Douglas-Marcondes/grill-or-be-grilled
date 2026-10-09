extends CharacterBody2D

var speed := 270.0
var jump_velocity := -520.0
var gravity := 1300.0
var max_health := 50
var health := 50
var facing := 1.0
var attack_timer := 0.0
var invulnerability := 0.0
var attack_color := Color("f7da7a")
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
	capsule.radius = 11
	capsule.height = 34
	shape.shape = capsule
	shape.position.y = -17
	add_child(shape)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -150)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	max_health += GameData.health_bonus
	health = max_health
	attack_color = Color("f7da7a")

func configure(class_name_value: String) -> void:
	class_name_game = class_name_value
	if GameData.equipped_weapon.is_empty():
		GameData.equipped_weapon = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}.get(class_name_game, "Espada")

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
		animation_time += delta * 13.0
	queue_redraw()

func attack() -> void:
	attack_timer = 0.38
	var damage := 1 + int(GameData.strength_bonus / 5)
	if GameData.equipped_weapon == "Espada":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and absf(enemy.global_position.x - global_position.x - facing * 26.0) < 67.0 and absf(enemy.global_position.y - global_position.y) < 54.0:
				enemy.take_damage(damage + 1)
		$"..".slash_effect(global_position + Vector2(facing * 31.0, -23.0), facing, false)
	else:
		var shot := Area2D.new()
		shot.set_script(preload("res://projectile.gd"))
		shot.global_position = global_position + Vector2(facing * 23.0, -23.0)
		shot.direction = Vector2(facing, 0)
		shot.damage = damage
		shot.speed = 570.0 if GameData.equipped_weapon == "Arco" else 430.0
		shot.color = Color("b4e17b") if GameData.equipped_weapon == "Arco" else Color("bd9aff")
		get_tree().current_scene.add_child(shot)
		$"..".slash_effect(global_position + Vector2(facing * 23.0, -23.0), facing, true)

func take_damage(amount: int) -> void:
	if invulnerability > 0.0:
		return
	health -= maxi(1, amount - GameData.armor_bonus)
	invulnerability = 0.9
	$"..".update_hud()
	if health <= 0:
		$"..".player_died()
		set_physics_process(false)

func _draw() -> void:
	var bob := -absf(sin(animation_time)) * 2.0 if absf(velocity.x) > 1.0 and is_on_floor() else 0.0
	var step := sin(animation_time) * 3.0 if absf(velocity.x) > 1.0 and is_on_floor() else 0.0
	var body_color := Color("486ba8")
	if class_name_game == "Arqueiro":
		body_color = Color("70964f")
	elif class_name_game == "Mago":
		body_color = Color("7654a0")
	if invulnerability > 0.0 and int(Time.get_ticks_msec() / 100) % 2 == 0:
		return
	draw_rect(Rect2(-9, -37 + bob, 18, 14), Color("f2c7a3"), true)
	draw_rect(Rect2(-10, -40 + bob, 20, 6), body_color.darkened(0.25), true)
	draw_rect(Rect2(-10, -23 + bob, 20, 20), body_color, true)
	draw_rect(Rect2(-9 - step, -4, 7, 9), Color("563f50"), true)
	draw_rect(Rect2(2 + step, -4, 7, 9), Color("563f50"), true)
	draw_rect(Rect2(4 if facing > 0.0 else -7, -33 + bob, 3, 3), Color("30273a"), true)
	if GameData.owns_chicken_armor:
		draw_rect(Rect2(-7, -43 + bob, 14, 5), Color("e0524b"), true)
		draw_rect(Rect2(9, -37 + bob, 7, 4), Color("efa34f"), true)
	if GameData.equipped_weapon == "Espada":
		draw_rect(Rect2(11 if facing > 0 else -31, -21 + bob, 20, 4), Color("d9e3ed"), true)
		draw_rect(Rect2(facing * 10.0, -24, 4, 11), Color("8d6345"), true)
	elif GameData.equipped_weapon == "Arco":
		draw_rect(Rect2(facing * 13.0, -30, 3, 19), Color("c39158"), true)
		draw_line(Vector2(facing * 12.0, -30), Vector2(facing * 12.0, -11), Color("e4d2ad"), 1.0)
	else:
		draw_rect(Rect2(-12, -44, 24, 5), Color("b88aeb"), true)
		draw_rect(Rect2(facing * 14.0, -29, 5, 5), Color("aee8fd"), true)
