extends RefCounted

## Converte o layout editavel da fase em terreno jogavel e texturizado.
##
## O desenho da fase continua sendo Polygon2D arrastavel no editor do Godot (ver
## jogo.tscn / EditorPreview/Cenario). Este modulo e quem le esse desenho e
## deriva dele duas coisas: a colisao e a textura de pixel art. Assim mover uma
## plataforma no editor nao exige tocar em codigo nem redesenhar nada.
##
## Exemplo:
##     Terreno.montar($EditorPreview/Cenario)

const AcabamentoDoTerreno = preload("res://scripts/acabamento_do_terreno.gd")

const PASTA_TILES := "res://Artes/gerado/tile_%s.png"

## Fronteiras em X das tres regioes da fase, alinhadas com os Marco* do mapa:
## fazenda (Ruinas do Galinheiro / Penhasco dos Ovos), entrada de madeira
## (Caverna das Penas) e porao de pedra (Trilha das Alturas / Ninho da Rainha).
const FIM_DA_FAZENDA := 3500.0
const FIM_DA_ENTRADA := 6500.0

## Material por regiao: corpo da plataforma e faixa de superficie.
const MATERIAIS := {
	"fazenda": {"corpo": "terra", "faixa": "palha", "parede": "parede_celeiro"},
	"entrada": {"corpo": "madeira", "faixa": "tabua", "parede": "parede_celeiro"},
	"porao": {"corpo": "pedra", "faixa": "laje", "parede": "parede_porao"},
}

const PREFIXOS_DE_CORPO := ["Trecho", "RotaAlta"]
## Plataforma mais baixa que isso e uma saliencia, nao um bloco de terreno: ela
## recebe a textura de superficie inteira, senao fica so com o miolo de terra e
## sem a borda que mostra onde da para pisar.
const ALTURA_DE_SALIENCIA := 40.0
const PREFIXO_DE_FAIXA := "Grama"
## Paredes de fundo existem so na entrada e no porao: na fazenda o jogador ve o
## ceu e as silhuetas do parallax, que e o que marca a progressao de cenario.
const PREFIXO_DE_PAREDE := "Parede"


static func montar(cenario: Node2D) -> int:
	"""Texturiza todo o cenario e cria colisao nos corpos. Devolve quantos
	corpos ganharam colisao."""
	if not cenario:
		push_error("Terreno.montar recebeu cenario nulo; esperado o Node2D EditorPreview/Cenario")
		return 0
	var corpos := 0
	for arte in cenario.get_children():
		if not arte is Polygon2D:
			continue
		_assar_escala(arte)
		var caixa := _caixa_global(arte)
		var regiao := _regiao_de(caixa)
		if _tem_prefixo(arte.name, PREFIXOS_DE_CORPO):
			var papel := "faixa" if caixa.size.y <= ALTURA_DE_SALIENCIA else "corpo"
			_vestir(arte, MATERIAIS[regiao][papel])
			AcabamentoDoTerreno.aplicar(arte)
			if _criar_colisao(arte):
				corpos += 1
		elif str(arte.name).begins_with(PREFIXO_DE_FAIXA):
			_vestir(arte, MATERIAIS[regiao]["faixa"])
		elif str(arte.name).begins_with(PREFIXO_DE_PAREDE):
			_vestir(arte, MATERIAIS[regiao]["parede"])
	return corpos


static func _assar_escala(arte: Polygon2D) -> void:
	"""Transfere o scale do no para os vertices e zera o scale.

	Quatro plataformas da fase foram ajustadas no editor com scale (RotaAlta10
	esta em 0.29). Isso quebrava duas coisas: o Polygon2D usa os proprios
	vertices como UV, entao o tile de 16px era espremido junto com o no (4.6px
	na RotaAlta10, destruindo a grade de pixel); e o CollisionPolygon2D filho
	herdava escala nao uniforme, que o Godot desaconselha em forma de colisao.

	A geometria na tela nao muda -- so sai do scale e entra nos vertices --, e a
	cena salva continua com o scale original, entao o ajuste feito no editor
	segue intacto.
	"""
	if arte.scale.is_equal_approx(Vector2.ONE):
		return
	var assado := PackedVector2Array()
	for ponto in arte.polygon:
		assado.append(ponto * arte.scale)
	arte.polygon = assado
	arte.offset *= arte.scale
	arte.scale = Vector2.ONE


static func e_corpo(no: Node) -> bool:
	"""Bloco de terreno onde se pisa (tem colisao), e nao faixa nem parede."""
	return no is Polygon2D and _tem_prefixo(no.name, PREFIXOS_DE_CORPO)


static func _tem_prefixo(nome: StringName, prefixos: Array) -> bool:
	for prefixo in prefixos:
		if str(nome).begins_with(prefixo):
			return true
	return false


static func _caixa_global(arte: Polygon2D) -> Rect2:
	"""Caixa do poligono em coordenadas de mundo.

	Usa to_global em vez de somar position na mao: varias plataformas da fase
	tambem tem scale (RotaAlta8, por exemplo, e position (2404, 80) com scale
	0.47), e ignorar a escala deslocava o centro em milhares de pixels -- uma
	saliencia no meio da fazenda chegou a ser classificada como porao e saiu
	coberta com a faixa do porao.
	"""
	if arte.polygon.is_empty():
		return Rect2()
	var caixa := Rect2(arte.to_global(arte.polygon[0]), Vector2.ZERO)
	for ponto in arte.polygon:
		caixa = caixa.expand(arte.to_global(ponto))
	return caixa


static func _regiao_de(caixa: Rect2) -> String:
	return regiao_em(caixa.get_center().x)


static func regiao_em(x: float) -> String:
	"""Regiao da fase num X do mundo: fazenda, entrada ou porao."""
	if x < FIM_DA_FAZENDA:
		return "fazenda"
	if x < FIM_DA_ENTRADA:
		return "entrada"
	return "porao"


static func _vestir(arte: Polygon2D, material: String) -> void:
	"""Aplica o tile como textura repetida.

	Sem UV explicito o Godot usa os proprios vertices como coordenada de
	textura, entao o tile de 16px casa com o grid do mundo de graca. A cor volta
	para branco porque Polygon2D multiplica a textura por ela, e a cor chapada
	antiga escureceria o tile inteiro.
	"""
	var textura := load(PASTA_TILES % material) as Texture2D
	if not textura:
		push_error("tile ausente para o material \"%s\" em %s" % [material, PASTA_TILES % material])
		return
	arte.texture = textura
	arte.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	arte.color = Color.WHITE


static func _criar_colisao(arte: Polygon2D) -> bool:
	if arte.polygon.size() < 3:
		return false
	var corpo := StaticBody2D.new()
	corpo.name = "ColisaoDaPlataforma"
	corpo.collision_layer = 1
	corpo.collision_mask = 1
	var colisor := CollisionPolygon2D.new()
	colisor.polygon = arte.polygon
	corpo.add_child(colisor)
	arte.add_child(corpo)
	return true
