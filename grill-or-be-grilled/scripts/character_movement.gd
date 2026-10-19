extends RefCounted

## Shared movement primitives for top-down and platforming character bodies.
## Callers own their input/AI policy; this module owns the physical rules.

static func apply_gravity(body: CharacterBody2D, delta: float, gravity: float) -> void:
	if not body.is_on_floor():
		body.velocity.y += gravity * delta


static func set_horizontal_speed(body: CharacterBody2D, direction: float, speed: float) -> void:
	body.velocity.x = direction * speed


static func stop_horizontal(body: CharacterBody2D, deceleration: float, delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, deceleration * delta)


static func face_direction(actor: Node, direction: float) -> void:
	if direction == 0.0:
		return

	var sprite := actor.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = direction < 0.0
		return

	var animated_sprite := actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.flip_h = direction < 0.0


static func accelerate_horizontal(body: CharacterBody2D, direction: float, speed: float, rate: float, delta: float) -> void:
	## One primitive covers both acceleration and friction: direction 0.0 makes
	## the target 0.0, so the caller only has to pick the rate.
	body.velocity.x = move_toward(body.velocity.x, direction * speed, rate * delta)
