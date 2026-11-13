extends Node2D

# Testes dos controles de toque: cada botao dispara uma acao que existe no
# input map, fica dentro da tela (inclusive em celular largo) e so aparece
# durante a partida.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_do_toque.tscn

const ControlesDeToque = preload("res://scripts/controles_de_toque.gd")
const Historia = preload("res://scripts/historia.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	_testar_acoes(game.toque)
	_testar_dentro_da_tela(game.toque)
	_exigir("escondido no menu", not game.toque.visible, "visivel=%s" % game.toque.visible)
	game.choose_class("Mago")
	await get_tree().process_frame
	_exigir("visivel jogando", game.toque.visible, "visivel=%s" % game.toque.visible)
	_exigir("dica de toque no celular",
		Historia.dica_de_controles(true) == Historia.DICA_DE_TOQUE and Historia.dica_de_controles(false) == Historia.DICA_DE_TECLADO,
		Historia.dica_de_controles(true))
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("TOQUE_OK 5 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_acoes(toque: ControlesDeToque) -> void:
	var sem_acao: Array[String] = []
	for nome in ControlesDeToque.BOTOES:
		var botao := toque.botao(nome)
		if not botao or not InputMap.has_action(botao.action):
			sem_acao.append(nome)
	_exigir("cada botao dispara uma acao do input map", sem_acao.is_empty(), str(sem_acao))


func _testar_dentro_da_tela(toque: ControlesDeToque) -> void:
	# Simula o celular largo (20:9 -> 600x270 de viewport) e reposiciona.
	get_viewport().size = Vector2i(600, 270)
	toque.posicionar()
	var limite := Rect2(Vector2.ZERO, Vector2(600, 270))
	var fora: Array[String] = []
	for nome in ControlesDeToque.BOTOES:
		var caixa := Rect2(toque.botao(nome).position, Vector2.ONE * ControlesDeToque.LADO)
		if not limite.encloses(caixa):
			fora.append("%s em %s" % [nome, caixa])
	var pular := toque.botao("pular").position.x
	_exigir("botoes dentro da tela larga e acoes na borda direita", fora.is_empty() and pular > 540.0,
		"fora=%s pular_x=%s" % [fora, pular])


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
