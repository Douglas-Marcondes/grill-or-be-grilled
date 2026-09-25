extends CharacterBody2D

var health := 3
var speed := 92.0
var gravity := 1000.0
var target: CharacterBody2D
var attack_cooldown := 0.0
var flash := 0.0
var facing := 1.0
var animation_time := 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16
	capsule.height = 36
	shape.shape = capsule
	shape.position.y = -17
	add_child(shape)

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0]
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	var distance := target.global_position.x - global_position.x
	if absf(distance) < 470.0:
		facing = signf(distance) if not is_zero_approx(distance) else facing
		velocity.x = facing * speed
		if is_on_floor() and target.global_position.y < global_position.y - 45:
			velocity.y = -440.0
		elif is_on_floor():
			var ray_start := global_position + Vector2(facing * 28.0, 0.0)
			var query := PhysicsRayQueryParameters2D.create(ray_start, ray_start + Vector2(0.0, 65.0), 1)
			if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				velocity.y = -420.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and global_position.distance_to(target.global_position) < 48.0:
		target.take_damage(1)
		attack_cooldown = 1.1
	move_and_slide()
	if is_on_floor() and absf(velocity.x) > 1.0:
		animation_time += delta * 13.0
	flash = maxf(0.0, flash - delta)
	queue_redraw()

func take_damage(amount: int) -> void:
	health -= amount
	flash = 0.14
	if health <= 0:
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.spawn_egg(global_position + Vector2(0, -14))
			game.enemy_defeated()
		queue_free()

func _draw() -> void:
	var bob := -absf(sin(animation_time)) * 2.0 if absf(velocity.x) > 1.0 and is_on_floor() else 0.0
	var step := sin(animation_time) * 3.0 if absf(velocity.x) > 1.0 and is_on_floor() else 0.0
	var white := Color("fff0cf") if flash <= 0.0 else Color.WHITE
	draw_rect(Rect2(-18, -30 + bob, 36, 25), white, true)
	draw_rect(Rect2(-22, -20 + bob, 8, 12), Color("dfb884"), true)
	draw_rect(Rect2(10, -20 + bob, 8, 12), Color("dfb884"), true)
	draw_rect(Rect2(-14, -36 + bob, 28, 19), Color("fff4db"), true)
	draw_rect(Rect2(-9, -33 + bob, 4, 5), Color("382a38"), true)
	draw_rect(Rect2(5, -33 + bob, 4, 5), Color("382a38"), true)
	var beak_x := 11.0 if facing > 0.0 else -21.0
	draw_rect(Rect2(beak_x, -30 + bob, 10, 6), Color("ed7956"), true)
	draw_rect(Rect2(-5, -41 + bob, 7, 7), Color("e65550"), true)
	draw_rect(Rect2(-14 - step, -3, 9, 8), Color("e5a454"), true)
	draw_rect(Rect2(5 + step, -3, 9, 8), Color("e5a454"), true)
