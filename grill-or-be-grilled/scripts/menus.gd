extends RefCounted

## Telas de menu (escolha de heroi, prologo, loja e fim de jogo) montadas sobre
## a interface da fase. So desenha: o que cada botao faz chega como Callable de
## fase1.gd, dona do fluxo do jogo.
##
## Exemplo:
##     var menus := Menus.new(raiz, [hud, aviso])
##     var painel := menus.painel("LOJA", "Saldo: 10")
##     menus.botao(painel, "Voltar", func(): mostrar_menu())

const LARGURA_PAINEL := 300.0
const ALTURA_PAINEL := 220.0
const COR_DO_TITULO := Color("fbf236")
const COR_DO_TEXTO := Color("eec39a")
const COR_DE_DICA := Color("9badb7")

var _raiz: Control
## Nos permanentes da interface (HUD, aviso, barra do chefe): o painel nao os apaga.
var _fixos: Array[Node]


func _init(raiz: Control, fixos: Array[Node]) -> void:
	_raiz = raiz
	_fixos = fixos


func painel(titulo: String, subtitulo: String) -> VBoxContainer:
	"""Limpa a tela (menos os fixos), escurece o fundo e devolve a coluna central."""
	for filho in _raiz.get_children():
		if not _fixos.has(filho):
			filho.queue_free()
	var sombra := ColorRect.new()
	sombra.color = Color(0.054901, 0.047058, 0.098039, 0.88)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(sombra)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(-LARGURA_PAINEL / 2.0, -ALTURA_PAINEL / 2.0)
	coluna.size = Vector2(LARGURA_PAINEL, ALTURA_PAINEL)
	coluna.add_theme_constant_override("separation", 3)
	_raiz.add_child(coluna)
	# Titulo em 2x: ampliar fonte bitmap por inteiro mantem o pixel quadrado.
	coluna.add_child(texto(titulo, COR_DO_TITULO, 24))
	coluna.add_child(texto(subtitulo, COR_DO_TEXTO))
	return coluna


func esconder_paineis() -> void:
	for filho in _raiz.get_children():
		if not _fixos.has(filho):
			filho.visible = false


static func texto(conteudo: String, cor: Color, tamanho: int = 0) -> Label:
	var rotulo := Label.new()
	rotulo.text = conteudo
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_color_override("font_color", cor)
	if tamanho > 0:
		rotulo.add_theme_font_size_override("font_size", tamanho)
	return rotulo


static func botao(pai: Container, rotulo: String, acao: Callable) -> Button:
	var novo := Button.new()
	novo.text = rotulo
	novo.custom_minimum_size = Vector2(190, 0)
	novo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	novo.pressed.connect(acao)
	pai.add_child(novo)
	return novo


func prologo(paginas: Array, pagina: int, ao_terminar: Callable) -> void:
	"""Uma pagina por tela, com Continuar e Pular."""
	var coluna := painel("PRÓLOGO  %d/%d" % [pagina + 1, paginas.size()], paginas[pagina])
	if pagina + 1 < paginas.size():
		botao(coluna, "Continuar", func(): prologo(paginas, pagina + 1, ao_terminar))
		botao(coluna, "Pular", ao_terminar)
	else:
		botao(coluna, "Começar", ao_terminar)
