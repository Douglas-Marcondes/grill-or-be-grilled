extends Area2D

var direction := Vector2.RIGHT
var speed := 480.0
var damage := 1
var color := Color("ffe38a")
var lifetime := 2.0
var target_mask := 2

func _ready() -> void:
	collision_layer = 0
	collision_mask = target_mask
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-8, -3, 16, 6), color, true)
	draw_rect(Rect2(-3, -6, 6, 12), color.lightened(0.3), true)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
