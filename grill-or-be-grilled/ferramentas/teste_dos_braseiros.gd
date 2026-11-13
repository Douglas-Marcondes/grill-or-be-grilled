extends Node2D

# Testes de checkpoint e vidas na fase de verdade: passar no braseiro acende,
# cura e marca o ponto de volta; cair devolve ao braseiro gastando uma vida;
# a ultima vida perdida encerra a tentativa.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_dos_braseiros.tscn

var _falhas: PackedStringArray = []

func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Guerreiro")
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		inimigo.queue_free()
	await get_tree().physics_frame
	var braseiro: Vector2 = game.get_node("EditorPreview/Personagens/Braseiros/Braseiro2").global_position
	await _testar_acender(game, braseiro)
	await _testar_queda_volta_ao_braseiro(game, braseiro)
	await _testar_fim_das_vidas(game)
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("BRASEIROS_OK 4 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_acender(game: Node, braseiro: Vector2) -> void:
	game.player.health = 5
	game.player.global_position = braseiro + Vector2(0, -2)
	await _esperar(5)
	_exigir("braseiro cura e marca a volta", game.player.health == game.player.max_health and game.checkpoint.distance_to(braseiro) < 4.0,
		"vida=%d checkpoint=%s" % [game.player.health, game.checkpoint])
	var acesos := 0
	var apagados := 0
	for no in game.get_children():
		if not "fogueira" in no:
			continue
		var quadro: int = no.fogueira.frame
		if no.aceso and quadro == no.QUADRO_ACESO and no.tocha.chama.visible:
			acesos += 1
		elif not no.aceso and quadro == no.QUADRO_APAGADO and not no.tocha.chama.visible:
			apagados += 1
	_exigir("fogueira muda de quadro ao acender", acesos >= 1 and apagados >= 1,
		"acesos=%d apagados=%d" % [acesos, apagados])


func _testar_queda_volta_ao_braseiro(game: Node, braseiro: Vector2) -> void:
	await _cair(game)
	_exigir("queda volta ao braseiro com uma vida a menos",
		game.screen == "playing" and game.vidas == 2 and game.player.global_position.distance_to(braseiro) < 20.0,
		"tela=%s vidas=%d em %s" % [game.screen, game.vidas, game.player.global_position])


func _testar_fim_das_vidas(game: Node) -> void:
	await _cair(game)
	await _cair(game)
	_exigir("sem vidas a tentativa acaba", game.screen == "dead", "tela=%s vidas=%d" % [game.screen, game.vidas])


func _cair(game: Node) -> void:
	game.player.invulnerability = 0.0
	game.player.global_position = Vector2(game.player.global_position.x, 900.0)
	await _esperar(5)


func _esperar(frames: int) -> void:
	for frame in frames:
		await get_tree().physics_frame


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
