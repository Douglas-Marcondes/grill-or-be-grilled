extends Node2D

# Teste dos menus: em cada tela (prologo, escolha de heroi, vitoria, loja, fim
# de jogo) todo botao precisa caber inteiro no viewport de 480x270. A loja ja
# empurrou o "Voltar" para fora da tela com o epilogo longo e o jogador ficou
# preso nela (relato de jogo, 13/11/2026).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_dos_menus.tscn

const Historia = preload("res://scripts/historia.gd")

var _falhas: PackedStringArray = []
var _game: Node

func _ready() -> void:
	_game = preload("res://jogo.tscn").instantiate()
	add_child(_game)
	await get_tree().process_frame
	_game.end_message = "%s\n%s" % [Historia.EPILOGO, Historia.ARMADURA_PERDIDA]
	await _conferir("prologo", func(): _game.show_prologue())
	GameData.viu_prologo = true
	await _conferir("escolha de heroi", func(): _game.show_class_select())
	await _conferir("vitoria", func(): _game.show_victory())
	await _conferir("loja", func(): _game.show_shop())
	await _conferir("fim de jogo", func(): _game.show_end_panel(Historia.DERROTA, "Tentar de novo", func(): pass))
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("MENUS_OK 5 telas")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _conferir(tela: String, abrir: Callable) -> void:
	abrir.call()
	await get_tree().process_frame
	await get_tree().process_frame
	var limite := get_viewport().get_visible_rect()
	var botoes := 0
	for botao in _botoes_visiveis(_game.ui.get_child(0)):
		botoes += 1
		var caixa := botao.get_global_rect()
		if not limite.encloses(caixa):
			_falhas.append("%s: botao \"%s\" fora da tela em %s (tela %s)" % [tela, botao.text, caixa, limite.size])
	if botoes == 0:
		_falhas.append("%s: nenhum botao visivel" % tela)


func _botoes_visiveis(raiz: Node) -> Array[Button]:
	var achados: Array[Button] = []
	for filho in raiz.get_children():
		if filho.is_queued_for_deletion():
			continue
		if filho is Button and filho.is_visible_in_tree():
			achados.append(filho)
		achados.append_array(_botoes_visiveis(filho))
	return achados
