extends Node2D

# Testes da historia e da loja: os recados de avanco saem nos quartos certos,
# toda placa com texto existe na fase, o prologo e mostrado uma vez so, e a
# loja cobra e entrega a melhoria. A loja roda numa instancia propria de
# game_data.gd, nunca no autoload.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_da_historia.tscn

const Historia = preload("res://scripts/historia.gd")
const DadosDoJogo = preload("res://game_data.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	_testar_recados_de_avanco()
	_testar_placas_existem()
	_testar_save_isolado()
	_testar_loja()
	await _testar_prologo_uma_vez()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("HISTORIA_OK 5 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_recados_de_avanco() -> void:
	var saidos: Array[int] = []
	for derrotadas in range(1, 23):
		if not Historia.recado_de_avanco(derrotadas, 22).is_empty():
			saidos.append(derrotadas)
	_exigir("recados em 1/4, 2/4 e 3/4", saidos == [6, 11, 17], "sairam em %s" % [saidos])


func _testar_placas_existem() -> void:
	var fase := preload("res://jogo.tscn").instantiate()
	for placa in Historia.PLACAS:
		_exigir("placa %s existe" % placa, fase.has_node("EditorPreview/Cenario/%s" % placa), "nao achei o no")
	fase.free()


func _testar_save_isolado() -> void:
	_exigir("ferramentas usam save proprio", GameData.caminho_do_save == DadosDoJogo.SAVE_DAS_FERRAMENTAS, "save=%s" % GameData.caminho_do_save)


func _testar_loja() -> void:
	var dados := DadosDoJogo.new()
	dados.caminho_do_save = "user://teste_da_loja.cfg"
	dados.gold = 10
	var sem_moeda := dados.comprar_melhoria("forca")
	dados.gold = 25
	var com_moeda := dados.comprar_melhoria("forca")
	_exigir("loja cobra e entrega", not sem_moeda and com_moeda and dados.gold == 5 and dados.strength_bonus == 5,
		"sem=%s com=%s ouro=%d forca=%d" % [sem_moeda, com_moeda, dados.gold, dados.strength_bonus])
	dados.free()


func _testar_prologo_uma_vez() -> void:
	GameData.viu_prologo = false
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var primeira := _titulo_do_painel(game)
	GameData.viu_prologo = true
	game.show_class_select()
	await get_tree().process_frame
	var segunda := _titulo_do_painel(game)
	_exigir("prologo so na primeira vez", primeira.begins_with("PRÓLOGO") and segunda == "GRILL OR BE GRILLED", "%s / %s" % [primeira, segunda])
	game.queue_free()


func _titulo_do_painel(game: Node) -> String:
	"""Titulo do painel visivel mais recente (o primeiro Label da coluna)."""
	var raiz := game.ui.get_child(0) as Control
	for indice in range(raiz.get_child_count() - 1, -1, -1):
		var filho := raiz.get_child(indice)
		if filho is VBoxContainer and not filho.is_queued_for_deletion():
			return (filho.get_child(0) as Label).text
	return ""


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
