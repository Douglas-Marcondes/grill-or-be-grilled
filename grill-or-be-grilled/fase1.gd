extends Node2D

const PlayerScript = preload("res://player.gd")
const Bestiario = preload("res://scripts/bestiario.gd")
const BossScript = preload("res://chicken_boss.gd")
const EggScript = preload("res://egg_pickup.gd")
const EffectScript = preload("res://pixel_effect.gd")
const BraseiroScript = preload("res://braseiro.gd")
const TEMA = preload("res://tema_pixel.tres")
const Terreno = preload("res://scripts/terreno.gd")
const Tochas = preload("res://scripts/tochas.gd")
const Adornos = preload("res://scripts/adornos.gd")
const Limites = preload("res://scripts/limites.gd")
const Historia = preload("res://scripts/historia.gd")
const Menus = preload("res://scripts/menus.gd")
const Iluminacao = preload("res://scripts/iluminacao.gd")

const LEVEL_END := 10000.0
var ui: CanvasLayer
var menus: Menus
## Placas (Marco*) ainda nao lidas nesta tentativa: nome -> X da placa.
var unread_signs := {}
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
var boss_intro_shown := false
## Vidas por tentativa: acabar com elas e o "fim de jogo" que perde os ovos.
const VIDAS_POR_TENTATIVA := 3
var vidas := VIDAS_POR_TENTATIVA
var checkpoint := Vector2.ZERO

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
			show_message("", 0.0)
	if boss_bar:
		boss_bar.visible = screen == "playing" and is_instance_valid(player) and is_instance_valid(boss) and absf(player.global_position.x - boss.global_position.x) < 700.0
	if screen == "playing" and not boss_intro_shown and is_instance_valid(player) and is_instance_valid(boss) and absf(player.global_position.x - boss.global_position.x) < 430.0:
		boss_intro_shown = true
		show_message(Historia.FALA_DO_CHEFE_AO_VER_O_HEROI, 4.0)
	_read_passed_signs()

func _read_passed_signs() -> void:
	"""Mostra o texto de cada placa uma vez, quando o heroi passa por ela."""
	if screen != "playing" or not is_instance_valid(player):
		return
	for sign_name in unread_signs.keys():
		if player.global_position.x >= unread_signs[sign_name]:
			unread_signs.erase(sign_name)
			show_message(Historia.PLACAS[sign_name], 4.5)
			return

func _build_playable_geometry() -> void:
	var level_art := get_node_or_null("EditorPreview/Cenario")
	if not level_art:
		push_error("Falta EditorPreview/Cenario na cena; nao foi possivel carregar o terreno.")
		return
	Terreno.montar(level_art)
	Tochas.montar(level_art)
	Adornos.montar(level_art)
	add_child(Iluminacao.new())
	_build_world_walls()


func _build_world_walls() -> void:
	"""Paredes invisiveis em x=0 e x=LEVEL_END. Sem elas o salto da Galinha
	Real a levava para fora do fim da arena e ela caia para sempre: a luta
	ficava impossivel de vencer (achado pelo teste de fumaca na arena)."""
	for x in [0.0, LEVEL_END]:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 2000)
		shape.shape = rect
		shape.position = Vector2(x + (20.0 if x > 0.0 else -20.0), 0)
		wall.add_child(shape)
		add_child(wall)


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
	# Aviso com quebra de linha e fundo escuro: as falas da historia passam de
	# uma linha e, sem fundo, sumiam contra o ceu claro e as tochas.
	notice_label = Menus.texto("", Color("fbf236"))
	notice_label.position = Vector2(40, 26)
	notice_label.size = Vector2(400, 0)
	var notice_box := StyleBoxFlat.new()
	notice_box.bg_color = Color(0.054901, 0.047058, 0.098039, 0.78)
	notice_box.set_content_margin_all(3)
	notice_label.add_theme_stylebox_override("normal", notice_box)
	notice_label.visible = false
	root.add_child(notice_label)
	_arm_menus()
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
	vidas = VIDAS_POR_TENTATIVA
	boss_intro_shown = false
	screen = "playing"
	boss_bar.visible = false
	var bot_markers := get_node("EditorPreview/Personagens/Bots").get_children()
	total_chickens = bot_markers.size()
	for marker in bot_markers:
		_spawn_enemy(marker)
	var egg_markers := get_node("EditorPreview/Personagens/Ovos").get_children()
	for marker in egg_markers:
		var egg_kind := int(marker.get_meta("egg_kind", 1))
		_place_egg(marker.global_position, egg_kind)
	for marker in get_node("EditorPreview/Personagens/Braseiros").get_children():
		var braseiro := Area2D.new()
		braseiro.set_script(BraseiroScript)
		braseiro.position = marker.global_position
		_register_level_object(braseiro)
	checkpoint = get_node("EditorPreview/Personagens/Jogador").global_position
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.position = checkpoint
	player.configure(GameData.selected_class)
	_register_level_object(player)
	# Luz fraca no heroi: no porao escuro ele nunca some entre duas tochas.
	var luz_do_heroi := Iluminacao.luz(Iluminacao.COR_DO_HEROI, 0.6, 1.3)
	luz_do_heroi.position.y = -14.0
	player.add_child(luz_do_heroi)
	var camera: Camera2D = player.camera
	if camera:
		camera.limit_left = 0
		camera.limit_right = int(LEVEL_END)
		camera.limit_top = 0
		camera.limit_bottom = int(Limites.FUNDO_DA_CAMERA)
		camera.make_current()
	_spawn_boss()
	show_hud()
	update_hud()
	unread_signs.clear()
	for sign_name in Historia.PLACAS:
		var sign_label := get_node("EditorPreview/Cenario/%s" % sign_name) as Control
		unread_signs[sign_name] = sign_label.global_position.x
	show_message(Historia.INICIO_DA_FASE, 5.0)
	Som.tocar_musica("musica_fase1")

func _spawn_enemy(marker: Node2D) -> void:
	var tipo := Bestiario.tipo_do_marcador(marker)
	var enemy := CharacterBody2D.new()
	enemy.set_script(Bestiario.script_de(tipo))
	enemy.folha_do_sprite = Bestiario.folha_de(tipo)
	enemy.configure_progression(clampf(marker.global_position.x / LEVEL_END, 0.0, 1.0))
	enemy.position = marker.global_position
	_register_level_object(enemy)

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
	var recado := Historia.recado_de_avanco(chickens_defeated, total_chickens)
	if chickens_defeated == total_chickens:
		recado = Historia.TODAS_DERROTADAS
	if not recado.is_empty():
		show_message(recado, 4.0)

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
	Som.parar_musica()
	Som.tocar("vitoria")
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
	end_message = "%s\n%s" % [Historia.EPILOGO, Historia.ARMADURA_GANHA if armor_dropped else Historia.ARMADURA_PERDIDA]
	show_message(Historia.QUEDA_DO_CHEFE, 2.2)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	GameData.finish_run()
	GameData.save_progress()
	show_victory()

func slash_effect(at: Vector2, facing: float, projectile: bool, tint: Color = Color("ffe18b")) -> void:
	var effect := Node2D.new()
	effect.set_script(EffectScript)
	effect.kind = "slash"
	effect.direction = facing
	effect.tint = tint if projectile else Color("f8e2a3")
	effect.position = at
	add_child(effect)

func shockwave_effect(at: Vector2, alcance: float) -> void:
	var onda := Node2D.new()
	onda.set_script(EffectScript)
	onda.kind = "onda"
	onda.reach_onda = alcance
	onda.position = at
	add_child(onda)

func boss_enraged() -> void:
	show_message(Historia.FALA_DO_CHEFE_ENFURECIDA, 3.0)

func checkpoint_reached(at: Vector2) -> void:
	checkpoint = at + Vector2(0, -2)
	if is_instance_valid(player):
		player.health = player.max_health
	update_hud()
	show_message("Braseiro aceso! Vida cheia. Se cair, você volta aqui.", 3.0)

func player_died() -> void:
	if screen != "playing":
		return
	vidas -= 1
	if vidas > 0:
		_respawn_player.call_deferred()
		return
	screen = "dead"
	Som.parar_musica()
	Som.tocar("derrota")
	GameData.fail_run()
	GameData.save_progress()
	show_end_panel(Historia.DERROTA, "Tentar de novo", func(): start_level())

func _respawn_player() -> void:
	"""Volta ao ultimo braseiro com vida cheia. A Galinha Real tambem se
	recompoe: morrer na luta recomeca a luta, nao so a vida do heroi."""
	if not is_instance_valid(player):
		return
	player.renascer(checkpoint)
	if is_instance_valid(boss) and boss.despertou:
		boss.queue_free()
		boss = null
		boss_intro_shown = false
		_spawn_boss()
	update_hud()
	show_message("Você caiu! Restam %d vidas. De volta ao braseiro." % vidas if vidas > 1 else "Última vida! Cuidado.", 3.0)

func update_hud() -> void:
	if not hud_label:
		return
	if screen == "playing" and is_instance_valid(player):
		hud_label.text = "%s  ♥ %d/%d  Vidas: %d  Ovos: %d  Galinhas: %d/%d" % [GameData.selected_class, player.health, player.max_health, vidas, GameData.run_eggs, chickens_defeated, total_chickens]
	else:
		hud_label.text = "Ovos: %d   Moedas: %d" % [GameData.run_eggs, GameData.gold]

func show_hud() -> void:
	menus.esconder_paineis()
	hud_label.visible = true
	update_hud()

func show_message(text: String, duration: float = 2.0) -> void:
	if not notice_label:
		return
	notice_label.text = text
	notice_label.visible = not text.is_empty()
	message_timer = duration

func _arm_menus() -> void:
	menus = Menus.new(ui.get_child(0) as Control, [hud_label, boss_bar, notice_label])

func _panel(title: String, subtitle: String) -> VBoxContainer:
	hud_label.visible = false
	show_message("", 0.0)
	return menus.painel(title, subtitle)

func show_class_select() -> void:
	screen = "select"
	_clear_level()
	boss_bar.visible = false
	if not GameData.viu_prologo:
		show_prologue()
		return
	var panel := _panel("GRILL OR BE GRILLED", "%s\nMoedas guardadas: %d" % [Historia.CHAMADA_DO_MENU, GameData.gold])
	for class_choice in ["Guerreiro", "Arqueiro", "Mago"]:
		var weapon: String = {"Guerreiro": "Espada", "Arqueiro": "Arco", "Mago": "Varinha"}[class_choice]
		var chosen: String = class_choice
		Menus.botao(panel, "%s  ·  %s" % [class_choice, weapon], func(): choose_class(chosen))
	Menus.botao(panel, "Rever a história", func(): show_prologue())
	panel.add_child(Menus.texto("Mover: A/D ou setas   Pular: Espaço/W   Atacar: J/clique   Esquivar: Shift/L\nControle: analógico, A pula, X ataca, B esquiva", Menus.COR_DE_DICA))

func show_prologue() -> void:
	menus.prologo(Historia.PROLOGO, 0, func():
		GameData.viu_prologo = true
		GameData.save_progress()
		show_class_select())

func show_victory() -> void:
	"""Epilogo em tela propria antes da loja: junto dela, o texto longo empurrava
	os botoes para fora da tela de 270px e o "Voltar" sumia -- o jogador ficava
	preso na loja."""
	screen = "victory"
	boss_bar.visible = false
	var panel := _panel("VITÓRIA!", end_message)
	Menus.botao(panel, "Ir para a loja", func(): show_shop())

func show_shop() -> void:
	screen = "shop"
	boss_bar.visible = false
	var result_text := "Ovos vendidos: %d moedas   Saldo: %d moedas" % [GameData.last_sale, GameData.gold]
	var panel := _panel("LOJA DO ACAMPAMENTO", result_text)
	Menus.botao(panel, "Poção de força permanente (+5) — 20 moedas", func(): _buy("forca"))
	Menus.botao(panel, "Poção de vida permanente (+5) — 20 moedas", func(): _buy("vida"))
	Menus.botao(panel, "Armadura resistente (+1 defesa) — 25 moedas", func(): _buy("armadura"))
	for weapon in ["Espada", "Arco", "Varinha"]:
		var chosen: String = weapon
		Menus.botao(panel, "Comprar/equipar %s — %d moedas" % [weapon, GameData.PRECO_DE_ARMA], func(): _buy_weapon(chosen))
	Menus.botao(panel, "Voltar ao menu de heróis", func(): show_class_select())

func _buy(kind: String) -> void:
	if not GameData.comprar_melhoria(kind):
		show_message("Ainda faltam moedas! Venda ovos vencendo uma fase.")
		return
	show_shop()

func _buy_weapon(weapon: String) -> void:
	if not GameData.comprar_arma(weapon):
		show_message("Ainda faltam moedas para essa arma!")
		return
	show_shop()

func show_end_panel(text: String, button_text: String, callback: Callable) -> void:
	var panel := _panel("FIM DE JOGO", text)
	Menus.botao(panel, button_text, callback)
	Menus.botao(panel, "Voltar ao menu de heróis", func(): show_class_select())
