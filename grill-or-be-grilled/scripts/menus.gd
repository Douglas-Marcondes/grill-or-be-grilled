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
const COR_DA_SOMBRA_DO_TITULO := Color("ac3232")
## Fundo do painel: deixa a fazenda noturna aparecer atras do menu. Com 0.88 a
## tela de titulo era um retangulo escuro com texto.
const OPACIDADE_DO_FUNDO := 0.62
## Celula do heroi na folha (tools/arte/personagens.py) e escala inteira.
const CELULA_DO_HEROI := Vector2(18, 26)
const ESCALA_DO_RETRATO := 2.0
const TAMANHO_DA_CARTA := Vector2(92, 86)

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
	sombra.color = Color(0.054901, 0.047058, 0.098039, OPACIDADE_DO_FUNDO)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(sombra)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(-LARGURA_PAINEL / 2.0, -ALTURA_PAINEL / 2.0)
	coluna.size = Vector2(LARGURA_PAINEL, ALTURA_PAINEL)
	coluna.add_theme_constant_override("separation", 3)
	_raiz.add_child(coluna)
	# Titulo em 2x: ampliar fonte bitmap por inteiro mantem o pixel quadrado.
	var cabecalho := texto(titulo, COR_DO_TITULO, 24)
	# Sombra dura de 2px em vermelho brasa: o titulo deixa de ser texto solto.
	cabecalho.add_theme_color_override("font_shadow_color", COR_DA_SOMBRA_DO_TITULO)
	cabecalho.add_theme_constant_override("shadow_offset_x", 2)
	cabecalho.add_theme_constant_override("shadow_offset_y", 2)
	coluna.add_child(cabecalho)
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


static func cartas_de_heroi(pai: Container, descricoes: Dictionary, ao_escolher: Callable) -> HBoxContainer:
	"""Uma carta por classe (retrato, nome, arma), lado a lado. Cada carta e um
	Button inteiro: grande o bastante para o dedo no celular, e com foco de
	teclado/controle como qualquer botao."""
	var fileira := HBoxContainer.new()
	fileira.alignment = BoxContainer.ALIGNMENT_CENTER
	fileira.add_theme_constant_override("separation", 6)
	for classe in descricoes:
		var escolhida: String = classe
		fileira.add_child(_carta(classe, descricoes[classe], func(): ao_escolher.call(escolhida)))
	pai.add_child(fileira)
	return fileira


static func _carta(classe: String, descricao: String, acao: Callable) -> Button:
	var carta := Button.new()
	carta.name = "Carta%s" % classe
	carta.custom_minimum_size = TAMANHO_DA_CARTA
	carta.pressed.connect(acao)
	var conteudo := VBoxContainer.new()
	conteudo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	conteudo.alignment = BoxContainer.ALIGNMENT_CENTER
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.add_child(_retrato(classe))
	conteudo.add_child(texto(classe, COR_DO_TITULO))
	var linha := texto(descricao, COR_DE_DICA)
	linha.custom_minimum_size.x = TAMANHO_DA_CARTA.x - 6
	conteudo.add_child(linha)
	for parte in conteudo.get_children():
		parte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carta.add_child(conteudo)
	return carta


static func _retrato(classe: String) -> TextureRect:
	var recorte := AtlasTexture.new()
	recorte.atlas = load("res://Artes/gerado/heroi_%s.png" % classe.to_lower())
	recorte.region = Rect2(Vector2.ZERO, CELULA_DO_HEROI)
	var retrato := TextureRect.new()
	retrato.texture = recorte
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.custom_minimum_size = CELULA_DO_HEROI * ESCALA_DO_RETRATO
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return retrato


func prologo(paginas: Array, pagina: int, ao_terminar: Callable) -> void:
	"""Uma pagina por tela, com Continuar e Pular."""
	var coluna := painel("PRÓLOGO  %d/%d" % [pagina + 1, paginas.size()], paginas[pagina])
	if pagina + 1 < paginas.size():
		botao(coluna, "Continuar", func(): prologo(paginas, pagina + 1, ao_terminar))
		botao(coluna, "Pular", ao_terminar)
	else:
		botao(coluna, "Começar", ao_terminar)
