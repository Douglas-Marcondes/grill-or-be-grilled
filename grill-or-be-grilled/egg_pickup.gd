extends Area2D

const Sprites = preload("res://scripts/sprites.gd")

var sprite: Sprite2D
var egg_kind := 0
var values := [1, 2, 4, 7, 12]
var bob_time := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	# Ovo flutua, entao e ancorado pelo centro e nao pelo pe como os personagens.
	sprite = Sprites.montar_centrado(self, Sprites.OVOS, 5)
	if sprite:
		sprite.frame = egg_kind

func _process(delta: float) -> void:
	bob_time += delta
	if sprite:
		sprite.position.y = roundf(sin(bob_time * 4.0) * 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameData.run_eggs += values[egg_kind]
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.show_message("Ovo %s! +%d" % [ ["comum", "menta", "azul", "rosa", "dourado"][egg_kind], values[egg_kind] ])
		queue_free()
