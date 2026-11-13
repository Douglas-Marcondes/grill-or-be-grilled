extends CanvasLayer

## Botoes na tela para jogar no celular: direcional a esquerda, acoes a direita.
##
## Usa TouchScreenButton, que dispara as MESMAS acoes do input map (pular,
## atacar...) que teclado e controle -- player.gd nao sabe se o comando veio de
## um dedo. Em aparelho sem tela de toque os botoes nem aparecem
## (VISIBILITY_TOUCHSCREEN_ONLY), entao no PC nada muda.
##
## Os botoes se reposicionam quando o tamanho da tela muda: com aspect "expand"
## o celular largo ganha mais mundo dos lados, e as acoes acompanham a borda
## direita em vez de ficarem no meio da tela.
##
## Exemplo:
##     var toque := ControlesDeToque.new()
##     add_child(toque)
##     toque.visible = screen == "playing"

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
## Area de toque um pouco maior que o desenho: dedo erra mais que mouse.
const RAIO_DO_TOQUE := 18.0
const DIRECIONAIS := ["esquerda", "direita"]

var _botoes := {}


func _ready() -> void:
	# Acima da interface (HUD e avisos ficam na camada 1, padrao).
	layer = 2
	var indice := 0
	for nome in BOTOES:
		_botoes[nome] = _novo_botao(nome, indice)
		indice += 1
	get_viewport().size_changed.connect(posicionar)
	posicionar()


func posicionar() -> void:
	"""Encosta cada botao na sua borda da area visivel atual."""
	var tela := get_viewport().get_visible_rect().size
	for nome in _botoes:
		var canto: Vector2 = POSICOES[nome]
		var x := canto.x if canto.x >= 0.0 else tela.x + canto.x
		_botoes[nome].position = Vector2(x, tela.y - canto.y)


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
