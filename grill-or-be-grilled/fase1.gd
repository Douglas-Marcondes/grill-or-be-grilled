extends Node2D

const PlayerScript = preload("res://player.gd")
const ChickenScript = preload("res://chicken_enemy.gd")
const BossScript = preload("res://chicken_boss.gd")
const EggScript = preload("res://egg_pickup.gd")
const EffectScript = preload("res://pixel_effect.gd")

const LEVEL_END := 2200.0
const CHICKEN_POSITIONS := [360.0, 710.0, 1080.0, 1420.0, 1725.0]

var ui: CanvasLayer
var player: CharacterBody2D
var boss: CharacterBody2D
var hud_label: Label
var boss_bar: ProgressBar
var notice_label: Label
var screen := "select"
var chickens_defeated := 0
var level_objects: Array[Node] = []
var message_timer := 0.0
var end_message := ""

func _ready() -> void:
	var editor_preview := get_node_or_null("EditorPreview")
	if editor_preview:
		editor_preview.hide()
	add_to_group("game")
	randomize()
	_build_backdrop()
	_build_ui()
	show_class_select()

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and notice_label:
			notice_label.text = ""

func _draw() -> void:
	draw_rect(Rect2(-1000, -1000, 5000, 2000), Color("302a48"), true)
	for i in 12:
		var x := float(i) * 235.0 - 120.0
		var height := 115.0 + float((i * 47) % 125)
		draw_rect(Rect2(x, 285.0 - height, 170.0, height), Color("403553"), true)
		draw_rect(Rect2(x + 24.0, 300.0 - height, 12.0, 27.0), Color("55436a"), true)
	for i in 10:
		var x := float(i) * 252.0 + 40.0
		draw_rect(Rect2(x, 104.0 + float((i * 23) % 110), 3, 3), Color("e7c982"), true)

func _build_backdrop() -> void:
	for x in [80.0, 284.0, 520.0, 842.0, 1175.0, 1500.0, 1840.0, 2150.0]:
		var torch := Node2D.new()
		torch.position = Vector2(x, 330.0)
		var art := Polygon2D.new()
		art.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(4, 27), Vector2(-4, 27)])
		art.color = Color("a97851")
		torch.add_child(art)
		var flame := Polygon2D.new()
		flame.polygon = PackedVector2Array([Vector2(0, -16), Vector2(8, -5), Vector2(5, 2), Vector2(-5, 2), Vector2(-8, -5)])
		flame.color = Color("ffc66d")
		flame.position.y = -5
		torch.add_child(flame)
		add_child(torch)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	hud_label = Label.new()
	hud_label.position = Vector2(22, 14)
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color("fff0c8"))
	root.add_child(hud_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(270, 18)
	boss_bar.size = Vector2(420, 20)
	boss_bar.visible = false
	boss_bar.show_percentage = false
	root.add_child(boss_bar)
	notice_label = Label.new()
	notice_label.position = Vector2(300, 66)
	notice_label.size = Vector2(360, 36)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_font_size_override("font_size", 20)
	notice_label.add_theme_color_override("font_color", Color("ffe99c"))
	root.add_child(notice_label)
	update_hud()

func _clear_level() -> void:
	for item in level_objects:
		if is_instance_valid(item):
			item.queue_free()
	level_objects.clear()
	player = null
	boss = null

func _register_level_object(item: Node) -> Node:
	add_child(item)
	level_objects.append(item)
	return item

func _make_floor(x: float, top: float, width: float, height: float = 240.0) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + width / 2.0, top + height / 2.0)
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	body.add_child(shape)
	var art := Polygon2D.new()
	art.polygon = PackedVector2Array([Vector2(-width / 2.0, -height / 2.0), Vector2(width / 2.0, -height / 2.0), Vector2(width / 2.0, height / 2.0), Vector2(-width / 2.0, height / 2.0)])
	art.color = Color("57434e")
	body.add_child(art)
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([Vector2(-width / 2.0, -height / 2.0), Vector2(width / 2.0, -height / 2.0), Vector2(width / 2.0, -height / 2.0 + 10), Vector2(-width / 2.0, -height / 2.0 + 10)])
	lip.color = Color("92a45c")
	body.add_child(lip)
	_register_level_object(body)

func choose_class(class_choice: String) -> void:
	GameData.selected_class = class_choice
	if not GameData.weapon_override or GameData.equipped_weapon.is_empty():
		GameData.equipped_weapon = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}.get(class_choice, "Espada")
		GameData.weapon_override = false
	var starter: String = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}.get(class_choice, "Espada")
	if not GameData.owned_weapons.has(starter):
		GameData.owned_weapons.append(starter)
	GameData.save_progress()
	start_level()

func start_level() -> void:
	_clear_level()
	GameData.begin_run()
	chickens_defeated = 0
	screen = "playing"
	boss_bar.visible = false
	_make_floor(0.0, 490.0, 570.0)
	_make_floor(665.0, 490.0, 465.0)
	_make_floor(1220.0, 490.0, 980.0)
	_make_floor(565.0, 400.0, 120.0, 24.0)
	_make_floor(820.0, 365.0, 140.0, 24.0)
	_make_floor(1090.0, 395.0, 100.0, 24.0)
	_make_floor(1480.0, 390.0, 135.0, 24.0)
	_make_floor(1780.0, 355.0, 120.0, 24.0)
	for position_x in CHICKEN_POSITIONS:
		var chicken := CharacterBody2D.new()
		chicken.set_script(ChickenScript)
		chicken.position = Vector2(position_x, 486.0)
		_register_level_object(chicken)
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.position = Vector2(90.0, 465.0)
	player.configure(GameData.selected_class)
	_register_level_object(player)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_right = int(LEVEL_END)
		camera.limit_top = 0
		camera.limit_bottom = 700
		camera.make_current()
	var sign := Label.new()
	sign.position = Vector2(1940, 360)
	sign.text = "ARENA DA GALINHA REAL"
	sign.add_theme_color_override("font_color", Color("ffe49c"))
	_register_level_object(sign)
	show_hud()
	update_hud()
	show_message("WASD ou setas: mover  |  Espaço/↑: pular  |  J ou clique: atacar", 5.0)

func spawn_egg(at: Vector2) -> void:
	var egg := Area2D.new()
	egg.set_script(EggScript)
	var roll := randf()
	egg.egg_kind = 0 if roll < 0.55 else (1 if roll < 0.80 else (2 if roll < 0.93 else (3 if roll < 0.985 else 4)))
	egg.global_position = at
	add_child(egg)
	level_objects.append(egg)

func enemy_defeated() -> void:
	chickens_defeated += 1
	update_hud()
	if chickens_defeated == CHICKEN_POSITIONS.size():
		show_message("As portas da arena se abriram! A GALINHA REAL chegou!", 3.5)
		_spawn_boss()

func _spawn_boss() -> void:
	boss = CharacterBody2D.new()
	boss.set_script(BossScript)
	boss.position = Vector2(2070.0, 455.0)
	_register_level_object(boss)
	boss_bar.visible = true
	boss_bar.max_value = 24
	boss_bar.value = 24

func update_boss_health(current: int, maximum: int) -> void:
	if boss_bar:
		boss_bar.max_value = maximum
		boss_bar.value = current

func boss_defeated(at: Vector2) -> void:
	if screen != "playing":
		return
	screen = "celebrating"
	boss_bar.visible = false
	var blast := Node2D.new()
	blast.set_script(EffectScript)
	blast.kind = "burst"
	blast.position = at + Vector2(0, -48)
	add_child(blast)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.94, 0.70, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.8, 0.12)
	tween.tween_property(flash, "color:a", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)
	var armor_dropped := randf() < 0.9
	if armor_dropped:
		GameData.owns_chicken_armor = true
		GameData.save_progress()
	end_message = "A armadura de galinha caiu! Bico, crista e barbela desbloqueados!" if armor_dropped else "A galinha explodiu em luz... mas a armadura não caiu desta vez. Tente de novo!"
	show_message("PÓF! Uma explosão de penas e luz!", 2.2)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	GameData.finish_run()
	GameData.save_progress()
	show_shop(true)

func slash_effect(at: Vector2, facing: float, projectile: bool, tint: Color = Color("ffe18b")) -> void:
	var effect := Node2D.new()
	effect.set_script(EffectScript)
	effect.kind = "slash"
	effect.direction = facing
	effect.tint = tint if projectile else Color("f8e2a3")
	effect.position = at
	add_child(effect)

func player_died() -> void:
	if screen != "playing":
		return
	screen = "dead"
	GameData.fail_run()
	GameData.save_progress()
	show_end_panel("Você virou omelete! Os ovos desta tentativa foram perdidos.", "Tentar de novo", func(): start_level())

func update_hud() -> void:
	if not hud_label:
		return
	if screen == "playing" and is_instance_valid(player):
		hud_label.text = "%s  ♥ %d/%d   Valor dos ovos: %d   Galinhas: %d/5" % [GameData.selected_class, player.health, player.max_health, GameData.run_eggs, chickens_defeated]
	else:
		hud_label.text = "Ovos: %d   Moedas: %d" % [GameData.run_eggs, GameData.gold]

func show_hud() -> void:
	for child in ui.get_child(0).get_children():
		if child != hud_label and child != boss_bar and child != notice_label:
			child.visible = false
	hud_label.visible = true
	update_hud()

func show_message(text: String, duration: float = 2.0) -> void:
	if not notice_label:
		return
	notice_label.text = text
	message_timer = duration

func _panel(title: String, subtitle: String) -> VBoxContainer:
	var root := ui.get_child(0) as Control
	hud_label.visible = false
	notice_label.text = ""
	for child in root.get_children():
		if child != hud_label and child != boss_bar and child != notice_label:
			child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.07, 0.13, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-290, -265)
	panel.size = Vector2(580, 530)
	panel.add_theme_constant_override("separation", 10)
	root.add_child(panel)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("ffe59b"))
	panel.add_child(heading)
	var note := Label.new()
	note.text = subtitle
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("f1e6d7"))
	panel.add_child(note)
	return panel

func _button(parent: Container, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 40)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_class_select() -> void:
	screen = "select"
	_clear_level()
	boss_bar.visible = false
	var panel := _panel("GRILL OR BE GRILLED", "Dungeon das Galinhas — escolha seu herói\nMoedas guardadas: %d" % GameData.gold)
	for class_choice in ["Guerreiro", "Arqueiro", "Mago"]:
		var weapon: String = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}[class_choice]
		var chosen: String = class_choice
		_button(panel, "%s  ·  %s" % [class_choice, weapon], func(): choose_class(chosen))
	var controls := Label.new()
	controls.text = "Derrote as galinhas, recolha ovos e vença o boss.\nMovimento: A/D ou setas   Pulo: Espaço   Ataque: J / clique"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color("cfc6d9"))
	panel.add_child(controls)
	hud_label.visible = false
	notice_label.text = ""

func show_shop(victory: bool) -> void:
	screen = "shop"
	boss_bar.visible = false
	var result_text := "%s\nValor dos ovos vendidos: %d moedas   Saldo: %d moedas" % [end_message if not end_message.is_empty() else "A primeira fase foi vencida!", GameData.last_sale, GameData.gold]
	var panel := _panel("LOJA DO ACAMPAMENTO", result_text)
	_button(panel, "Poção de força permanente (+5) — 20 moedas", func(): _buy("strength"))
	_button(panel, "Poção de vida permanente (+5) — 20 moedas", func(): _buy("health"))
	_button(panel, "Armadura resistente (+1 defesa) — 25 moedas", func(): _buy("armor"))
	_button(panel, "Comprar/equipar Espada — 15 moedas", func(): _buy_weapon("Espada", 15))
	_button(panel, "Comprar/equipar Arco — 15 moedas", func(): _buy_weapon("Arco", 15))
	_button(panel, "Comprar/equipar Varinha — 15 moedas", func(): _buy_weapon("Varinha", 15))
	_button(panel, "Voltar ao menu de heróis", func(): show_class_select())

func _buy(kind: String) -> void:
	var price := 25 if kind == "armor" else 20
	if GameData.gold < price:
		show_message("Ainda faltam moedas! Venda ovos vencendo uma fase.")
		return
	GameData.gold -= price
	if kind == "strength":
		GameData.strength_bonus += 5
	elif kind == "health":
		GameData.health_bonus += 5
	else:
		GameData.armor_bonus += 1
	GameData.save_progress()
	show_shop(true)

func _buy_weapon(weapon: String, price: int) -> void:
	if not GameData.owned_weapons.has(weapon) and GameData.gold < price:
		show_message("Ainda faltam moedas para essa arma!")
		return
	if not GameData.owned_weapons.has(weapon):
		GameData.gold -= price
		GameData.owned_weapons.append(weapon)
	GameData.equipped_weapon = weapon
	GameData.weapon_override = true
	GameData.save_progress()
	show_shop(true)

func show_end_panel(text: String, button_text: String, callback: Callable) -> void:
	var panel := _panel("FIM DE JOGO", text)
	_button(panel, button_text, callback)
	_button(panel, "Voltar ao menu de heróis", func(): show_class_select())
