extends CanvasLayer

## Fundo do painel de controles quando o celular esta em pe.
##
## Cobre tudo abaixo da faixa do jogo (scripts/formato_da_tela.gd): sem ele, a
## sobra de baixo mostrava o mundo continuando para baixo da faixa, e o fundo de
## ceu (fixo em 270px) acabava num degrau preto no meio da tela.
## Fica numa camada propria abaixo da interface, para os menus e os botoes de
## toque aparecerem por cima.
##
## Exemplo:
##     add_child(MolduraDeRetrato.new())

const FormatoDaTela = preload("res://scripts/formato_da_tela.gd")
const COR_DO_PAINEL := Color(0.054901, 0.047058, 0.098039, 1)
const COR_DA_BORDA := Color(0.270588, 0.156863, 0.235294, 1)

var _painel: ColorRect


func _ready() -> void:
	layer = 1
	_painel = ColorRect.new()
	_painel.color = COR_DO_PAINEL
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var borda := ColorRect.new()
	borda.color = COR_DA_BORDA
	borda.size = Vector2(0, 1)
	borda.set_anchors_preset(Control.PRESET_TOP_WIDE)
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(borda)
	add_child(_painel)
	get_viewport().size_changed.connect(ajustar)
	ajustar()


func ajustar() -> void:
	"""Estica o painel sobre a sobra de baixo; some quando nao ha sobra."""
	var tela := get_viewport().get_visible_rect().size
	var sobra := FormatoDaTela.sobra(get_viewport())
	visible = sobra > 0.0
	_painel.position = Vector2(0, FormatoDaTela.ALTURA_DO_JOGO)
	_painel.size = Vector2(tela.x, sobra)
