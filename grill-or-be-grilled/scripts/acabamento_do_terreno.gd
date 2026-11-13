@tool
extends RefCounted

## Da volume aos blocos de terreno: sombra de profundidade e contorno.
##
## Sem isto cada plataforma era um retangulo com o mesmo tile do topo ao fundo,
## sem borda -- o "recortado em papel" que deixava a fase com cara de prototipo.
## Plataformistas em pixel art resolvem com duas coisas baratas: o miolo escurece
## conforme se afasta da superficie (o olho le "isto e fundo, nao se pisa") e um
## contorno escuro separa o bloco do fundo.
##
## E @tool porque scripts/previa_do_editor.gd veste a fase no editor com o mesmo
## codigo; o Line2D e a franja criados aqui nao tem owner e saem antes de
## salvar, e `vertex_colors` e `uv` estao no retrato da prévia.
##
## Exemplo:
##     AcabamentoDoTerreno.aplicar($EditorPreview/Cenario/Trecho1)

const Superficie = preload("res://scripts/superficie.gd")

const PASTA_FRANJAS := "res://Artes/gerado/franja_%s.png"
## Altura de franja_*.png (tools/arte/cenario.py, ALTURA_DA_FRANJA).
const ALTURA_DA_FRANJA := 6.0
## Espaco entre amostras da borda de baixo: curto o bastante para a franja
## acompanhar o piso curvo do ninho.
const PASSO_DA_FRANJA := 4.0
## Distancia (px) abaixo do topo em que o miolo chega a cor mais escura.
const PROFUNDIDADE_DA_SOMBRA := 150.0
const COR_DO_FUNDO := Color(0.32, 0.26, 0.40)
const COR_DO_CONTORNO := Color(0.0, 0.0, 0.0, 0.85)


static func aplicar(arte: Polygon2D) -> void:
	"""Escurece o bloco com a profundidade e desenha o contorno."""
	if arte.polygon.size() < 3:
		push_error("AcabamentoDoTerreno.aplicar: %s tem %d vertices; esperado >= 3" % [arte.name, arte.polygon.size()])
		return
	arte.vertex_colors = _cores_por_profundidade(arte.polygon)
	arte.add_child(_contorno(arte.polygon))


static func aplicar_faixa(arte: Polygon2D, material: String) -> void:
	"""Faixa de superficie: textura que segue o topo e franja pendurada embaixo.

	A textura do Polygon2D usava os vertices como UV, ou seja, alinhada ao
	mundo: no piso curvo do ninho a laje virava uma banda reta atravessando a
	curva, e em faixa reta a linha clara do tile caia em qualquer altura. Com UV
	medido a partir do topo, a primeira linha do tile sempre e a beirada.
	"""
	arte.uv = _uv_a_partir_do_topo(arte)
	var franja := load(PASTA_FRANJAS % material) as Texture2D
	if franja:
		arte.add_child(_franja(arte, franja))


static func _uv_a_partir_do_topo(arte: Polygon2D) -> PackedVector2Array:
	var uv := PackedVector2Array()
	for ponto in arte.polygon:
		var mundo := arte.to_global(ponto)
		var topo := Superficie.topo_em(arte, mundo.x)
		uv.append(Vector2(ponto.x, mundo.y - topo if is_finite(topo) else 0.0))
	return uv


static func _franja(arte: Polygon2D, textura: Texture2D) -> Polygon2D:
	"""Fita de ALTURA_DA_FRANJA px colada na borda de baixo da faixa."""
	var de_cima := PackedVector2Array()
	var de_baixo := PackedVector2Array()
	var uv_cima := PackedVector2Array()
	var uv_baixo := PackedVector2Array()
	for x in _amostras_em_x(arte):
		var borda := arte.to_local(Vector2(x, Superficie.fundo_em(arte, x)))
		de_cima.append(borda)
		de_baixo.append(borda + Vector2(0, ALTURA_DA_FRANJA))
		uv_cima.append(Vector2(borda.x, 0))
		uv_baixo.append(Vector2(borda.x, ALTURA_DA_FRANJA))
	de_baixo.reverse()
	uv_baixo.reverse()
	var fita := Polygon2D.new()
	fita.name = "Franja"
	fita.polygon = de_cima + de_baixo
	fita.uv = uv_cima + uv_baixo
	fita.texture = textura
	fita.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return fita


static func _amostras_em_x(arte: Polygon2D) -> PackedFloat32Array:
	var menor := INF
	var maior := -INF
	for ponto in arte.polygon:
		var x := arte.to_global(ponto).x
		menor = minf(menor, x)
		maior = maxf(maior, x)
	var amostras := PackedFloat32Array()
	var x := menor
	while x < maior:
		amostras.append(x)
		x += PASSO_DA_FRANJA
	amostras.append(maior)
	# Os X dos vertices entram tambem: so com o passo fixo a franja cortava a
	# quina de cada dobra da faixa em vez de contorna-la.
	for ponto in arte.polygon:
		var vertice := arte.to_global(ponto).x
		if not amostras.has(vertice):
			amostras.append(vertice)
	amostras.sort()
	return amostras


static func _cores_por_profundidade(pontos: PackedVector2Array) -> PackedColorArray:
	var topo := pontos[0].y
	for ponto in pontos:
		topo = minf(topo, ponto.y)
	var cores := PackedColorArray()
	for ponto in pontos:
		var fundura := clampf((ponto.y - topo) / PROFUNDIDADE_DA_SOMBRA, 0.0, 1.0)
		cores.append(Color.WHITE.lerp(COR_DO_FUNDO, fundura))
	return cores


static func _contorno(pontos: PackedVector2Array) -> Line2D:
	var linha := Line2D.new()
	linha.name = "Contorno"
	linha.points = pontos
	linha.closed = true
	linha.width = 1.0
	linha.default_color = COR_DO_CONTORNO
	linha.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return linha
