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
## codigo; o Line2D criado aqui nao tem owner e sai antes de salvar, e
## `vertex_colors` esta no retrato da prévia.
##
## Exemplo:
##     AcabamentoDoTerreno.aplicar($EditorPreview/Cenario/Trecho1)

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
