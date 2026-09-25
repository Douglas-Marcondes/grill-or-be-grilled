extends Area2D

var egg_kind := 0
var values := [1, 2, 4, 7, 12]
var colors := [Color("fff1b5"), Color("9fe6d2"), Color("a9c7ff"), Color("f2a6d4"), Color("ffd05a")]
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

func _process(delta: float) -> void:
	bob_time += delta
	queue_redraw()

func _draw() -> void:
	var lift := sin(bob_time * 4.0) * 2.0
	draw_rect(Rect2(-7, -8 + lift, 14, 16), colors[egg_kind], true)
	draw_rect(Rect2(-4, -11 + lift, 8, 3), colors[egg_kind].lightened(0.3), true)
	draw_rect(Rect2(-3, -4 + lift, 3, 5), Color(1, 1, 1, 0.75), true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameData.run_eggs += values[egg_kind]
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.show_message("Ovo %s! +%d" % [ ["comum", "menta", "azul", "rosa", "dourado"][egg_kind], values[egg_kind] ])
		queue_free()
