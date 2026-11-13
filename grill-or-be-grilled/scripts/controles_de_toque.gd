extends CanvasLayer

## Botoes na tela para jogar no celular: direcional a esquerda, acoes a direita.
##
## Usa TouchScreenButton, que dispara as MESMAS acoes do input map (pular,
## atacar...) que teclado e controle -- player.gd nao sabe se o comando veio de
## um dedo. Em aparelho sem tela de toque os botoes nem aparecem
## (VISIBILITY_TOUCHSCREEN_ONLY), entao no PC nada muda.
##
## Os botoes se reposicionam quando o tamanho da tela muda. Deitado, ficam por
## cima do jogo, encostados nos cantos de baixo (com aspect "expand" o celular
## largo ganha mais mundo dos lados, e as acoes acompanham a borda direita).
## Em pe, vao para o painel abaixo da faixa do jogo (scripts/formato_da_tela.gd)
## em tamanho dobrado: ali ha espaco e o dedo nao tapa a acao.
##
## Exemplo:
##     var toque := ControlesDeToque.new()
##     add_child(toque)
##     toque.visible = screen == "playing"

const FormatoDaTela = preload("res://scripts/formato_da_tela.gd")
const FOLHA := preload("res://Artes/gerado/toque.png")
const FOLHA_APERTADA := preload("res://Artes/gerado/toque_apertado.png")
const LADO := 30.0
## Ordem das folhas (tools/arte/toque.py, ORDEM) -> acao do input map.
const BOTOES := {
	"esquerda": "andar_esquerda",
	"direita": "andar_direita",
	"pular": "pular",
	"atacar": "atacar",
	"esquivar": "esquivar",
}
## Canto superior esquerdo de cada botao. X negativo conta da borda direita;
## Y conta da borda de baixo.
const POSICOES := {
	"esquerda": Vector2(8, 40),
	"direita": Vector2(44, 40),
	"pular": Vector2(-38, 40),
	"atacar": Vector2(-74, 40),
	"esquivar": Vector2(-56, 76),
}
## Em pe: centro de cada botao relativo ao centro do painel. X negativo conta da
## borda direita. Direcional a esquerda, pulo no canto direito com ataque ao
## lado e esquiva acima, como num controle.
const CENTROS_NO_PAINEL := {
	"esquerda": Vector2(50, 0),
	"direita": Vector2(120, 0),
	"pular": Vector2(-50, 20),
	"atacar": Vector2(-120, 20),
	"esquivar": Vector2(-85, -50),
}
const ESCALA_NO_PAINEL := 2.0
## Area de toque um pouco maior que o desenho: dedo erra mais que mouse.
const RAIO_DO_TOQUE := 18.0
const DIRECIONAIS := ["esquerda", "direita"]

var _botoes := {}


func _ready() -> void:
	# Acima da interface (camada 2) e da moldura do celular em pe (camada 1).
	layer = 3
	var indice := 0
	for nome in BOTOES:
		_botoes[nome] = _novo_botao(nome, indice)
		indice += 1
	get_viewport().size_changed.connect(posicionar)
	posicionar()


func posicionar() -> void:
	"""Arruma os botoes para a orientacao atual: no painel (em pe) ou nos
	cantos de baixo, por cima do jogo (deitado)."""
	if FormatoDaTela.tem_painel(get_viewport()):
		_arrumar_no_painel()
	else:
		_arrumar_nos_cantos()


func _arrumar_nos_cantos() -> void:
	var tela := get_viewport().get_visible_rect().size
	for nome in _botoes:
		var canto: Vector2 = POSICOES[nome]
		var x := canto.x if canto.x >= 0.0 else tela.x + canto.x
		_botoes[nome].scale = Vector2.ONE
		_botoes[nome].position = Vector2(x, tela.y - canto.y)


func _arrumar_no_painel() -> void:
	var tela := get_viewport().get_visible_rect().size
	var centro_do_painel := FormatoDaTela.ALTURA_DO_JOGO + FormatoDaTela.sobra(get_viewport()) / 2.0
	var meio_botao := LADO * ESCALA_NO_PAINEL / 2.0
	for nome in _botoes:
		var centro: Vector2 = CENTROS_NO_PAINEL[nome]
		var x := centro.x if centro.x >= 0.0 else tela.x + centro.x
		_botoes[nome].scale = Vector2.ONE * ESCALA_NO_PAINEL
		_botoes[nome].position = Vector2(x, centro_do_painel + centro.y) - Vector2.ONE * meio_botao


func botao(nome: String) -> TouchScreenButton:
	return _botoes.get(nome)


func _novo_botao(nome: String, indice: int) -> TouchScreenButton:
	var novo := TouchScreenButton.new()
	novo.name = nome.capitalize()
	novo.action = BOTOES[nome]
	novo.texture_normal = _recorte(FOLHA, indice)
	novo.texture_pressed = _recorte(FOLHA_APERTADA, indice)
	var area := CircleShape2D.new()
	area.radius = RAIO_DO_TOQUE
	novo.shape = area
	novo.shape_centered = true
	novo.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	# Deslizar o dedo de uma seta para a outra troca a direcao sem soltar.
	novo.passby_press = DIRECIONAIS.has(nome)
	add_child(novo)
	return novo


static func _recorte(folha: Texture2D, indice: int) -> AtlasTexture:
	var recorte := AtlasTexture.new()
	recorte.atlas = folha
	recorte.region = Rect2(indice * LADO, 0, LADO, LADO)
	return recorte
