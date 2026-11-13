extends Node2D

# Testes da camada de cenario: altura do chao lida dos poligonos, adornos
# deterministicos no topo das plataformas e tochas da fazenda fincadas em poste.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_dos_adornos.tscn

const Superficie = preload("res://scripts/superficie.gd")
const Adornos = preload("res://scripts/adornos.gd")
const Tochas = preload("res://scripts/tochas.gd")
const AcabamentoDoTerreno = preload("res://scripts/acabamento_do_terreno.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	_testar_superficie()
	_testar_adornos_deterministicos()
	_testar_tochas_da_fazenda()
	_testar_faixa_curva()
	_testar_ninho()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("ADORNOS_OK 8 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


## Cenario minimo: um bloco plano e uma rampa, separados por um vao.
func _cenario_de_teste() -> Node2D:
	var cenario := Node2D.new()
	add_child(cenario)
	cenario.add_child(_bloco("Trecho1", [Vector2(0, 400), Vector2(300, 400), Vector2(300, 600), Vector2(0, 600)]))
	cenario.add_child(_bloco("Trecho2", [Vector2(500, 400), Vector2(800, 300), Vector2(800, 600), Vector2(500, 600)]))
	return cenario


func _bloco(nome: String, pontos: Array[Vector2]) -> Polygon2D:
	var bloco := Polygon2D.new()
	bloco.name = nome
	bloco.polygon = PackedVector2Array(pontos)
	return bloco


func _testar_superficie() -> void:
	var cenario := _cenario_de_teste()
	var plano := Superficie.chao_abaixo(cenario, Vector2(100, 0))
	var rampa := Superficie.chao_abaixo(cenario, Vector2(650, 0))
	var vao := Superficie.chao_abaixo(cenario, Vector2(400, 0))
	_exigir("chao no plano e na rampa", is_equal_approx(plano, 400.0) and is_equal_approx(rampa, 350.0),
		"plano=%s rampa=%s" % [plano, rampa])
	_exigir("vao nao tem chao", is_inf(vao), "vao=%s" % vao)
	cenario.free()


func _testar_adornos_deterministicos() -> void:
	var primeira := _posicoes_dos_adornos()
	var segunda := _posicoes_dos_adornos()
	_exigir("adornos sempre nos mesmos lugares", not primeira.is_empty() and primeira == segunda,
		"%s vs %s" % [primeira, segunda])
	var no_chao := true
	for ponto in primeira:
		no_chao = no_chao and is_equal_approx(ponto.y, 400.0)
	_exigir("adornos pousam no topo do bloco", no_chao, str(primeira))


func _posicoes_dos_adornos() -> Array[Vector2]:
	var cenario := _cenario_de_teste()
	Adornos.montar(cenario)
	var posicoes: Array[Vector2] = []
	for sprite in cenario.get_node("Trecho1/Adornos").get_children():
		posicoes.append(sprite.global_position)
	cenario.free()
	return posicoes


func _testar_tochas_da_fazenda() -> void:
	var cenario := _cenario_de_teste()
	for dados in [["Tocha1", 100.0], ["Tocha2", 400.0]]:
		var marcador := Node2D.new()
		marcador.name = dados[0]
		marcador.position = Vector2(dados[1], 100)
		cenario.add_child(marcador)
	Tochas.montar(cenario)
	var plantada: Node2D = cenario.get_node("Tocha1").get_child(0)
	var no_vao: Node2D = cenario.get_node("Tocha2").get_child(0)
	var altura_esperada := 400.0 - Tochas.ALTURA_DO_POSTE - Tochas.ALTURA_DO_CASTICAL
	_exigir("tocha da fazenda no poste, e escondida sobre o vao",
		is_equal_approx(plantada.global_position.y, altura_esperada) and plantada.visible and not no_vao.visible,
		"y=%s esperado=%s vao_visivel=%s" % [plantada.global_position.y, altura_esperada, no_vao.visible])
	cenario.free()


func _testar_faixa_curva() -> void:
	# Faixa em V: topo desce de 400 a 420 e volta, com 10px de espessura.
	var faixa := _bloco("Grama1", [Vector2(0, 400), Vector2(50, 420), Vector2(100, 400),
		Vector2(100, 410), Vector2(50, 430), Vector2(0, 410)])
	add_child(faixa)
	var fundo := Superficie.fundo_em(faixa, 50.0)
	AcabamentoDoTerreno.aplicar_faixa(faixa, "palha")
	var alturas_no_tile: Array[float] = []
	for ponto in faixa.uv:
		alturas_no_tile.append(ponto.y)
	_exigir("textura da faixa segue o topo da curva",
		is_equal_approx(fundo, 430.0) and alturas_no_tile == [0.0, 0.0, 0.0, 10.0, 10.0, 10.0],
		"fundo=%s uv_y=%s" % [fundo, alturas_no_tile])
	var franja := faixa.get_node_or_null("Franja") as Polygon2D
	_exigir("franja pendurada na borda de baixo",
		franja != null and franja.polygon.has(Vector2(50, 430)) and franja.polygon.has(Vector2(50, 436)),
		str(franja.polygon if franja else "sem franja"))
	faixa.free()


func _testar_ninho() -> void:
	var cenario := Node2D.new()
	add_child(cenario)
	var ninho := Node2D.new()
	ninho.name = "Ninho"
	cenario.add_child(ninho)
	var fibra := Line2D.new()
	fibra.points = PackedVector2Array([Vector2.ZERO, Vector2(40, 5)])
	ninho.add_child(fibra)
	Adornos.montar(cenario)
	_exigir("fibras do ninho com palha e contorno",
		fibra.texture != null and fibra.texture_mode == Line2D.LINE_TEXTURE_TILE and fibra.get_child_count() == 1,
		"textura=%s filhos=%d" % [fibra.texture, fibra.get_child_count()])
	cenario.free()


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
