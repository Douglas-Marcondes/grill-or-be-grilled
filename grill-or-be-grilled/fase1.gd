extends Node2D

const PlayerScript = preload("res://player.gd")
const ChickenScript = preload("res://chicken_enemy.gd")
const BossScript = preload("res://chicken_boss.gd")
const EggScript = preload("res://egg_pickup.gd")
const EffectScript = preload("res://pixel_effect.gd")
const TEMA = preload("res://tema_pixel.tres")
const Terreno = preload("res://scripts/terreno.gd")
const Tochas = preload("res://scripts/tochas.gd")
const Limites = preload("res://scripts/limites.gd")

const LEVEL_END := 10000.0
const LARGURA_PAINEL := 300.0
const ALTURA_PAINEL := 220.0
var ui: CanvasLayer
var player: CharacterBody2D
var boss: CharacterBody2D
var hud_label: Label
var boss_bar: ProgressBar
var notice_label: Label
var screen := "select"
var chickens_defeated := 0
var total_chickens := 0
var level_objects: Array[Node] = []
var message_timer := 0.0
var end_message := ""
var proximo_marco := 4
var boss_intro_shown := false

func _ready() -> void:
	var preview_characters := get_node_or_null("EditorPreview/Personagens")
	if preview_characters:
		preview_characters.hide()
	_build_playable_geometry()
	add_to_group("game")
	randomize()
	_build_ui()
	show_class_select()

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and notice_label:
			notice_label.text = ""
	if boss_bar:
		boss_bar.visible = screen == "playing" and is_instance_valid(player) and is_instance_valid(boss) and absf(player.global_position.x - boss.global_position.x) < 700.0
	if screen == "playing" and not boss_intro_shown and is_instance_valid(player) and is_instance_valid(boss) and absf(player.global_position.x - boss.global_position.x) < 430.0:
		boss_intro_shown = true
		show_message("A Galinha Real bloqueia o ninho. Leia o aviso, desvie e contra-ataque!", 4.0)

func _build_playable_geometry() -> void:
	var level_art := get_node_or_null("EditorPreview/Cenario")
	if not level_art:
		push_error("Falta EditorPreview/Cenario na cena; nao foi possivel carregar o terreno.")
		return
	Terreno.montar(level_art)
	Tochas.montar(level_art)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = TEMA
	ui.add_child(root)
	hud_label = Label.new()
	hud_label.position = Vector2(5, 3)
	root.add_child(hud_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(150, 16)
	boss_bar.size = Vector2(180, 7)
	boss_bar.visible = false
	boss_bar.show_percentage = false
	root.add_child(boss_bar)
	notice_label = Label.new()
	notice_label.position = Vector2(20, 28)
	notice_label.size = Vector2(440, 14)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_color_override("font_color", Color("fbf236"))
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
	proximo_marco = 4
	boss_intro_shown = false
	screen = "playing"
	boss_bar.visible = false
	var bot_markers := get_node("EditorPreview/Personagens/Bots").get_children()
	total_chickens = bot_markers.size()
	for index in bot_markers.size():
		var marker := bot_markers[index] as Node2D
		var chicken := CharacterBody2D.new()
		chicken.set_script(ChickenScript)
		chicken.configure_progression(index, bot_markers.size())
		chicken.position = marker.global_position
		_register_level_object(chicken)
	var egg_markers := get_node("EditorPreview/Personagens/Ovos").get_children()
	for marker in egg_markers:
		var egg_kind := int(marker.get_meta("egg_kind", 1))
		_place_egg(marker.global_position, egg_kind)
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.position = get_node("EditorPreview/Personagens/Jogador").global_position
	player.configure(GameData.selected_class)
	_register_level_object(player)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_right = int(LEVEL_END)
		camera.limit_top = 0
		camera.limit_bottom = int(Limites.FUNDO_DA_CAMERA)
		camera.make_current()
	_spawn_boss()
	show_hud()
	update_hud()
	show_message("A fazenda caiu. Atravesse as ruínas, reúna os ovos e descubra por que a Galinha Real guarda o ninho.", 5.0)

func _place_egg(at: Vector2, kind: int) -> void:
	var egg := Area2D.new()
	egg.set_script(EggScript)
	egg.egg_kind = clampi(kind, 0, 4)
	egg.global_position = at
	_register_level_object(egg)

func spawn_egg(at: Vector2) -> void:
	# Adiado: a morte da galinha costuma vir de dentro de body_entered do
	# projetil, e criar Area2D durante o flush de fisica gera "Can't change this
	# state while flushing queries" (PENDENCIAS.md, 19/10/2026).
	_place_egg.call_deferred(at, _sortear_raridade())

func _sortear_raridade() -> int:
	var roll := randf()
	if roll < 0.55:
		return 0
	if roll < 0.80:
		return 1
	if roll < 0.93:
		return 2
	return 3 if roll < 0.985 else 4

func enemy_defeated() -> void:
	chickens_defeated += 1
	update_hud()
	if chickens_defeated >= proximo_marco and chickens_defeated < total_chickens:
		_show_story_beat()
		proximo_marco += 4
	if chickens_defeated == total_chickens:
		show_message("O ninho está à frente. A guardiã despertou!", 3.5)

func _show_story_beat() -> void:
	var fraction := float(chickens_defeated) / maxf(1.0, float(total_chickens))
	var story := "As penas brilham no escuro. Alguém protege este lugar há muito tempo."
	if fraction >= 0.75:
		story = "O calor aumenta. A Galinha Real sente seus passos e chama suas últimas guardiãs."
	elif fraction >= 0.5:
		story = "Marcas antigas cobrem as paredes: o ninho mantém viva a chama da fazenda."
	show_message(story, 4.0)

func _spawn_boss() -> void:
	if is_instance_valid(boss):
		return
	boss = CharacterBody2D.new()
	boss.set_script(BossScript)
	boss.position = get_node("EditorPreview/Personagens/GalinhaReal").global_position
	_register_level_object(boss)
	boss_bar.visible = false
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
	var epilogo := "A chama do ninho reacende. A fazenda ainda pode ser salva."
	end_message = "%s\nA armadura de galinha caiu! Bico, crista e barbela desbloqueados!" % epilogo if armor_dropped else "%s\nA armadura sumiu na explosão. A guardiã pode voltar a deixar uma." % epilogo
	show_message("PÓF! A chama do ninho voltou a brilhar!", 2.2)
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
		hud_label.text = "%s  ♥ %d/%d   Valor dos ovos: %d   Galinhas: %d/%d" % [GameData.selected_class, player.health, player.max_health, GameData.run_eggs, chickens_defeated, total_chickens]
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
	shade.color = Color(0.054901, 0.047058, 0.098039, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-LARGURA_PAINEL / 2.0, -ALTURA_PAINEL / 2.0)
	panel.size = Vector2(LARGURA_PAINEL, ALTURA_PAINEL)
	panel.add_theme_constant_override("separation", 3)
	root.add_child(panel)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Titulo em 2x: ampliar fonte bitmap por inteiro mantem o pixel quadrado.
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("fbf236"))
	panel.add_child(heading)
	var note := Label.new()
	note.text = subtitle
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("eec39a"))
	panel.add_child(note)
	return panel

func _button(parent: Container, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_class_select() -> void:
	screen = "select"
	_clear_level()
	boss_bar.visible = false
	var panel := _panel("GRILL OR BE GRILLED", "A fazenda foi tomada pela noite. A chama do ninho está enfraquecendo.\nEncontre a Galinha Real antes que ela se apague.\nMoedas guardadas: %d" % GameData.gold)
	for class_choice in ["Guerreiro", "Arqueiro", "Mago"]:
		var weapon: String = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}[class_choice]
		var chosen: String = class_choice
		_button(panel, "%s  ·  %s" % [class_choice, weapon], func(): choose_class(chosen))
	var controls := Label.new()
	controls.text = "Derrote as galinhas, recolha ovos e vença o boss.\nMovimento: A/D ou setas   Pulo: Espaço/W   Ataque: J / clique\nControle: analógico/direcional, A para pular, X para atacar"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_color", Color("9badb7"))
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
