@tool
extends RefCounted

## Onde fica o chao: altura da superficie pisavel do cenario num dado X.
##
## Adornos e postes de tocha precisam pousar no topo do terreno, e o terreno e
## desenhado a mao no editor (retangulos, mas tambem a curva do ninho). Em vez
## de raycast -- que nao existe no editor, onde a prévia tambem veste a fase --
## a altura sai direto dos vertices dos Polygon2D.
##
## Exemplo:
##     var y := Superficie.chao_abaixo(cenario, Vector2(980, 330))
##     if is_finite(y): poste.global_position = Vector2(980, y)

const Terreno = preload("res://scripts/terreno.gd")


static func topo_em(arte: Polygon2D, x: float) -> float:
	"""Y global mais alto do poligono na vertical X; INF se X fica fora dele."""
	var cortes := _cortes(arte, x)
	return cortes.x if cortes.x <= cortes.y else INF


static func fundo_em(arte: Polygon2D, x: float) -> float:
	"""Y global mais baixo do poligono na vertical X; INF se X fica fora dele."""
	var cortes := _cortes(arte, x)
	return cortes.y if cortes.x <= cortes.y else INF


static func _cortes(arte: Polygon2D, x: float) -> Vector2:
	"""Menor e maior Y onde as arestas cruzam a vertical X (x > y se nenhuma)."""
	var pontos := arte.polygon
	var cortes := Vector2(INF, -INF)
	for indice in pontos.size():
		var a := arte.to_global(pontos[indice])
		var b := arte.to_global(pontos[(indice + 1) % pontos.size()])
		if is_equal_approx(a.x, b.x) or x < minf(a.x, b.x) or x > maxf(a.x, b.x):
			continue
		var y := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
		cortes = Vector2(minf(cortes.x, y), maxf(cortes.y, y))
	return cortes


static func chao_abaixo(cenario: Node, ponto: Vector2) -> float:
	"""Primeira superficie pisavel abaixo do ponto (Y global); INF se for vao."""
	var chao := INF
	for no in cenario.get_children():
		if not Terreno.e_corpo(no):
			continue
		var topo := topo_em(no, ponto.x)
		if topo >= ponto.y:
			chao = minf(chao, topo)
	return chao
