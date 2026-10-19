extends Node2D

# Testes de scripts/previa_do_editor.gd. O que esta em jogo e o layout da fase:
# a previa altera os nos de layout no editor (textura, cor, e a escala assada
# nos vertices por Terreno._assar_escala), e se `despir` nao devolver cada
# propriedade EXATAMENTE como estava, salvar a cena no Godot gravaria a
# vestimenta no lugar do layout cru -- e o desenho editavel da fase se perde.
#
# Roda sobre uma cena falsa montada aqui, nao sobre jogo.tscn, porque jogo.tscn
# ja chega vestido por fase1.gd em tempo de execucao. A cena falsa reproduz o
# que importa: os `owner` preenchidos (e assim que a previa distingue no salvo
# de no gerado) e uma plataforma com escala, que e a mutacao perigosa.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_da_previa.tscn

const Previa = preload("res://scripts/previa_do_editor.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	var previa := _montar_cena_falsa()
	var antes := _retratar(previa)
	previa.vestir()
	_conferir_vestida(previa)
	previa.despir()
	_conferir_retrato_devolvido(antes, _retratar(previa))
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("PREVIA_OK %d nos conferidos" % antes.size())
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _conferir_vestida(previa: Node2D) -> void:
	"""A previa tem de produzir o mesmo que o jogo: terreno texturizado com
	colisao, tocha montada e um sprite em cada marcador."""
	var plataforma := previa.get_node("Cenario/Trecho1") as Polygon2D
	_exigir("plataforma texturizada", plataforma.texture != null, "texture continua nula")
	_exigir("escala assada nos vertices", plataforma.scale.is_equal_approx(Vector2.ONE),
			"scale ficou em %s" % plataforma.scale)
	_exigir("colisao criada", plataforma.get_node_or_null("ColisaoDaPlataforma") != null,
			"nao achei ColisaoDaPlataforma")
	_exigir("tocha montada", _tem_sprite(previa.get_node("Cenario/Tocha1")),
			"a tocha nao ganhou sprite")
	for caminho in ["Personagens/Jogador", "Personagens/Bots/Bot1",
			"Personagens/Ovos/Ovo1", "Personagens/GalinhaReal"]:
		_exigir("sprite em %s" % caminho, _tem_sprite(previa.get_node(caminho)),
				"o marcador continua sem sprite")


func _conferir_retrato_devolvido(antes: Dictionary, depois: Dictionary) -> void:
	_exigir("nenhum no gerado sobrou", antes.size() == depois.size(),
			"a cena tinha %d nos e ficou com %d" % [antes.size(), depois.size()])
	for caminho in antes:
		if not depois.has(caminho):
			_falhas.append("%s desapareceu depois de despir" % caminho)
			continue
		for propriedade in antes[caminho]:
			var original: Variant = antes[caminho][propriedade]
			var atual: Variant = depois[caminho][propriedade]
			if original != atual:
				_falhas.append("%s.%s voltou como %s, era %s"
						% [caminho, propriedade, atual, original])


func _retratar(previa: Node2D) -> Dictionary:
	"""Caminho -> propriedades da vestimenta, de todo descendente com dono."""
	var retrato := {}
	var pilha: Array[Node] = previa.get_children()
	while not pilha.is_empty():
		var no: Node = pilha.pop_back()
		if no.owner == null:
			continue
		var valores := {}
		for propriedade in Previa.PROPRIEDADES_DA_VESTIMENTA:
			var valor: Variant = no.get(propriedade)
			if valor != null:
				valores[propriedade] = valor
		retrato[str(previa.get_path_to(no))] = valores
		pilha.append_array(no.get_children())
	return retrato


func _tem_sprite(no: Node) -> bool:
	"""Busca em profundidade: o marcador de personagem recebe o Sprite2D direto,
	mas a tocha recebe um no Tocha que carrega castical, chama e halo dentro."""
	for filho in no.get_children():
		if filho is Sprite2D or _tem_sprite(filho):
			return true
	return false


func _montar_cena_falsa() -> Node2D:
	var previa := Node2D.new()
	previa.set_script(Previa)
	add_child(previa)
	var cenario := _filho(previa, Node2D.new(), "Cenario")
	# Escala diferente de 1 de proposito: e o caso que Terreno._assar_escala
	# transforma em vertices, a mutacao que despir tem de desfazer.
	_plataforma(cenario, "Trecho1", Vector2(100, 400), Vector2(2.0, 1.5))
	_filho(_filho(cenario, Node2D.new(), "Tocha1"), _poligono(Color("ac3232")), "SuporteTocha1")
	var personagens := _filho(previa, Node2D.new(), "Personagens")
	_filho(_filho(personagens, Node2D.new(), "Jogador"), _poligono(Color("486baa")), "Corpo")
	_filho(_filho(personagens, Node2D.new(), "Bots"), _poligono(Color("fff0cf")), "Bot1")
	var ovo := _filho(_filho(personagens, Node2D.new(), "Ovos"), _poligono(Color("afe17a")), "Ovo1")
	ovo.set_meta("egg_kind", 3)
	_filho(personagens, _poligono(Color("f7e7ce")), "GalinhaReal")
	_adotar(previa, previa)
	return previa


func _plataforma(pai: Node2D, nome: String, posicao: Vector2, escala: Vector2) -> void:
	var arte := _poligono(Color("3f2832"))
	arte.position = posicao
	arte.scale = escala
	_filho(pai, arte, nome)


func _poligono(cor: Color) -> Polygon2D:
	var arte := Polygon2D.new()
	arte.color = cor
	arte.polygon = PackedVector2Array([Vector2(0, 0), Vector2(200, 0),
			Vector2(200, 120), Vector2(0, 120)])
	return arte


func _filho(pai: Node, no: Node, nome: String) -> Node:
	no.name = nome
	pai.add_child(no)
	return no


func _adotar(no: Node, dono: Node) -> void:
	"""Preenche `owner` como o editor faz numa cena aberta: todo no salvo tem
	dono, e a raiz da cena nao."""
	for filho in no.get_children():
		filho.owner = dono
		_adotar(filho, dono)


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
