extends PanelContainer

## HUD em icones: vida em barra, vidas como chamas, ovos e galinhas abatidas.
##
## Substitui uma linha de texto que o jogador tinha de ler no meio da acao. A
## vida e a Chama do Ninho da historia: chamas acesas sao as vidas que restam,
## apagadas as perdidas -- assim se ve quantas havia, nao so quantas sobram.
## Fora da partida (loja, vitoria) o mesmo painel mostra ovos e moedas.
##
## Exemplo:
##     var hud := Hud.new()
##     raiz.add_child(hud)
##     hud.mostrar_partida(40, 50, 2, 3, 5, 7, 22)

const FOLHA := preload("res://Artes/gerado/icones_hud.png")
enum Icone { CORACAO, CHAMA, CHAMA_APAGADA, OVO, GALINHA, MOEDA }
const LADO_DO_ICONE := 9
const LARGURA_DA_BARRA := 56.0

var _barra: ProgressBar
var _vida: Label
var _chamas: HBoxContainer
var _ovos: Label
var _galinhas: Label
var _moedas: Label
## Itens que so aparecem durante a partida, e os que so aparecem fora dela.
var _so_na_partida: Array[Control] = []
var _so_no_cofre: Array[Control] = []


func _init() -> void:
	name = "Hud"
	position = Vector2(4, 3)
	add_theme_stylebox_override("panel", _fundo())
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 3)
	add_child(linha)
	_barra = _nova_barra()
	_vida = _rotulo()
	_chamas = HBoxContainer.new()
	_chamas.add_theme_constant_override("separation", 0)
	_so_na_partida.append_array([_par(linha, Icone.CORACAO, _barra), _vida, _chamas])
	linha.add_child(_vida)
	linha.add_child(_chamas)
	_ovos = _rotulo()
	_par(linha, Icone.OVO, _ovos)
	_galinhas = _rotulo()
	_so_na_partida.append(_par(linha, Icone.GALINHA, _galinhas))
	_moedas = _rotulo()
	_so_no_cofre.append(_par(linha, Icone.MOEDA, _moedas))


func mostrar_partida(vida: int, vida_maxima: int, vidas: int, vidas_maximas: int,
		ovos: int, galinhas: int, total_de_galinhas: int) -> void:
	"""Painel da partida em andamento."""
	_mudar_modo(true)
	_barra.max_value = vida_maxima
	_barra.value = vida
	_vida.text = "%d/%d" % [vida, vida_maxima]
	_acender_chamas(vidas, vidas_maximas)
	_ovos.text = str(ovos)
	_galinhas.text = "%d/%d" % [galinhas, total_de_galinhas]


func mostrar_cofre(ovos: int, moedas: int) -> void:
	"""Painel fora da partida: o que se leva para a loja."""
	_mudar_modo(false)
	_ovos.text = str(ovos)
	_moedas.text = str(moedas)


func _mudar_modo(na_partida: bool) -> void:
	for item in _so_na_partida:
		item.visible = na_partida
	for item in _so_no_cofre:
		item.visible = not na_partida


func _acender_chamas(acesas: int, total: int) -> void:
	while _chamas.get_child_count() < total:
		_chamas.add_child(icone(Icone.CHAMA))
	for indice in _chamas.get_child_count():
		var chama := _chamas.get_child(indice) as TextureRect
		chama.visible = indice < total
		chama.texture = _recorte(Icone.CHAMA if indice < acesas else Icone.CHAMA_APAGADA)


func _par(linha: HBoxContainer, qual: Icone, valor: Control) -> Control:
	"""Icone colado ao seu valor, num grupo que some e aparece junto."""
	var grupo := HBoxContainer.new()
	grupo.add_theme_constant_override("separation", 2)
	grupo.add_child(icone(qual))
	grupo.add_child(valor)
	linha.add_child(grupo)
	return grupo


static func icone(qual: Icone) -> TextureRect:
	"""TextureRect de um icone da folha, centrado na altura da linha."""
	var imagem := TextureRect.new()
	imagem.texture = _recorte(qual)
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return imagem


static func _recorte(qual: Icone) -> AtlasTexture:
	var recorte := AtlasTexture.new()
	recorte.atlas = FOLHA
	recorte.region = Rect2(qual * LADO_DO_ICONE, 0, LADO_DO_ICONE, LADO_DO_ICONE)
	return recorte


func _nova_barra() -> ProgressBar:
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(LARGURA_DA_BARRA, 5)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.show_percentage = false
	return barra


func _rotulo() -> Label:
	var rotulo := Label.new()
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rotulo


func _fundo() -> StyleBoxFlat:
	# Mesmo fundo translucido do aviso de historia (fase1.gd): o HUD tem de ler
	# sobre o ceu claro sem tapar a fase.
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.054901, 0.047058, 0.098039, 0.72)
	fundo.border_color = Color(0.270588, 0.156863, 0.235294, 1)
	fundo.set_border_width_all(1)
	fundo.set_content_margin_all(2)
	fundo.content_margin_left = 3
	fundo.content_margin_right = 4
	fundo.anti_aliasing = false
	return fundo
