@tool
extends RefCounted

## Espalha adornos (capim, feno, caixote, osso...) no topo das plataformas.
##
## Bloco liso do comeco ao fim e o que mais denunciava a fase como prototipo.
## Os adornos nao tem colisao nem mudam o jogo; so quebram a monotonia e contam
## a regiao. A posicao e sorteada com semente no nome da plataforma: a mesma
## plataforma recebe sempre os mesmos adornos (no editor e no jogo), e mover ou
## esticar a plataforma no editor redistribui sozinho.
##
## E @tool porque scripts/previa_do_editor.gd veste a fase no editor; o no
## "Adornos" criado aqui nao tem owner e sai antes de salvar.
##
## Exemplo:
##     Adornos.montar($EditorPreview/Cenario)

const Terreno = preload("res://scripts/terreno.gd")
const Superficie = preload("res://scripts/superficie.gd")
const Sprites = preload("res://scripts/sprites.gd")

const FOLHA := "adornos_%s"
const QUADROS := 5
## Peso de sorteio por quadro: as folhas (tools/arte/adornos.py) vem do mais
## comum ao mais raro. Feno ou barril a cada passo viraria entulho, mas peca
## miuda demais (a primeira versao dava pedrinha em metade dos passos) some no
## quadro de 480x270 e a plataforma volta a parecer lisa.
const PESOS := [4.0, 3.0, 2.0, 2.0, 1.5]
const PASSO_MINIMO := 22
const PASSO_MAXIMO := 64
## Distancia da quina: adorno na beirada parece pendurado no vazio.
const MARGEM := 10.0
const LARGURA_MINIMA := 40.0


static func montar(cenario: Node2D) -> int:
	"""Adorna todas as plataformas. Devolve quantos adornos foram postos."""
	if not cenario:
		push_error("Adornos.montar recebeu cenario nulo; esperado EditorPreview/Cenario")
		return 0
	var total := 0
	for no in cenario.get_children():
		if Terreno.e_corpo(no):
			total += _adornar(no)
	return total


static func _adornar(arte: Polygon2D) -> int:
	var faixa := _faixa_em_x(arte)
	if faixa.y - faixa.x < LARGURA_MINIMA:
		return 0
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash(str(arte.name))
	var grupo := Node2D.new()
	grupo.name = "Adornos"
	arte.add_child(grupo)
	var folha := FOLHA % Terreno.regiao_em((faixa.x + faixa.y) / 2.0)
	var x := faixa.x + MARGEM + sorteio.randi_range(0, PASSO_MINIMO)
	var postos := 0
	while x < faixa.y - MARGEM:
		var topo := Superficie.topo_em(arte, x)
		if is_finite(topo):
			_por(grupo, folha, arte.to_local(Vector2(x, topo)), sorteio)
			postos += 1
		x += sorteio.randi_range(PASSO_MINIMO, PASSO_MAXIMO)
	return postos


static func _faixa_em_x(arte: Polygon2D) -> Vector2:
	"""Menor e maior X global do poligono."""
	var faixa := Vector2(INF, -INF)
	for ponto in arte.polygon:
		var x := arte.to_global(ponto).x
		faixa = Vector2(minf(faixa.x, x), maxf(faixa.y, x))
	return faixa


static func _por(grupo: Node2D, folha: String, pe: Vector2, sorteio: RandomNumberGenerator) -> void:
	var sprite := Sprites.montar(grupo, folha, QUADROS)
	if not sprite:
		return
	sprite.position = pe.round()
	sprite.frame = sorteio.rand_weighted(PackedFloat32Array(PESOS))
	sprite.flip_h = sorteio.randf() < 0.5
