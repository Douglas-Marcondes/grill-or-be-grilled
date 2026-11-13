extends Node2D

# Testes do HUD em icones: vida, chamas acesas/apagadas, contadores, modo cofre
# fora da partida e ligacao com a fase de verdade.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_do_hud.tscn

const Hud = preload("res://scripts/hud.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	_testar_partida()
	_testar_cofre()
	await _testar_na_fase()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("HUD_OK 4 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_partida() -> void:
	var hud := Hud.new()
	add_child(hud)
	hud.mostrar_partida(30, 50, 1, 3, 4, 7, 22)
	var regioes: Array[float] = []
	for chama in hud._chamas.get_children():
		regioes.append((chama.texture as AtlasTexture).region.position.x / Hud.LADO_DO_ICONE)
	_exigir("uma chama acesa e duas apagadas",
		regioes == [float(Hud.Icone.CHAMA), float(Hud.Icone.CHAMA_APAGADA), float(Hud.Icone.CHAMA_APAGADA)], str(regioes))
	_exigir("contadores da partida",
		hud._vida.text == "30/50" and hud._barra.value == 30 and hud._ovos.text == "4" and hud._galinhas.text == "7/22",
		"vida=%s ovos=%s galinhas=%s" % [hud._vida.text, hud._ovos.text, hud._galinhas.text])
	hud.free()


func _testar_cofre() -> void:
	var hud := Hud.new()
	add_child(hud)
	hud.mostrar_cofre(9, 120)
	_exigir("cofre mostra moedas e esconde a vida",
		hud._moedas.text == "120" and hud._moedas.is_visible_in_tree() and not hud._vida.is_visible_in_tree(),
		"moedas=%s vida_visivel=%s" % [hud._moedas.text, hud._vida.is_visible_in_tree()])
	hud.free()


func _testar_na_fase() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Guerreiro")
	await get_tree().process_frame
	game.player.health -= 5
	game.update_hud()
	var esperado := "%d/%d" % [game.player.health, game.player.max_health]
	_exigir("fase atualiza o HUD", game.hud.visible and game.hud._vida.text == esperado,
		"visivel=%s vida=%s esperado=%s" % [game.hud.visible, game.hud._vida.text, esperado])
	game.queue_free()


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
