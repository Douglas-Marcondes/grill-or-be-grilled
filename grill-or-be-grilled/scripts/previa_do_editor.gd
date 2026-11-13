@tool
extends Node2D

## Faz o editor do Godot mostrar a fase como ela e jogada.
##
## O layout da fase e desenhado com Polygon2D chapados e marcadores crus, e toda
## a vestimenta (textura de terreno, tochas acesas, sprites dos personagens)
## acontecia so em tempo de execucao -- entao o que aparecia no editor nao era o
## que se jogava, e posicionar inimigo ou plataforma era adivinhacao. Este no
## roda a MESMA vestimenta do jogo (Terreno, Tochas, Sprites) dentro do editor.
##
## O que o editor passa a mostrar: terreno texturizado por regiao, tochas com
## castical e chama, e heroi, galinhas, ovos e Galinha Real nos tamanhos reais
## dos sprites -- os marcadores desenhados a mao sao maiores que os sprites (o
## do jogador tem 40px contra os 26px do heroi), o que fazia o editor mentir
## sobre quem alcanca o que.
##
## A cena salva NUNCA guarda a vestimenta: antes de cada salvamento a prévia se
## desfaz e devolve cada propriedade ao valor original, e se refaz depois. Sem
## isso, salvar a cena gravaria o terreno texturizado e, pior, a escala assada
## nos vertices por Terreno._assar_escala -- o layout cru que da para editar
## deixaria de existir.

const Terreno = preload("res://scripts/terreno.gd")
const Tochas = preload("res://scripts/tochas.gd")
const Adornos = preload("res://scripts/adornos.gd")
const Sprites = preload("res://scripts/sprites.gd")
const Jogador = preload("res://player.gd")
const Bestiario = preload("res://scripts/bestiario.gd")

## Tudo que Terreno e Tochas alteram nos nos de layout. E desta lista que sai o
## retrato guardado antes de vestir.
const PROPRIEDADES_DA_VESTIMENTA := ["polygon", "offset", "scale", "texture",
		"texture_repeat", "color", "vertex_colors", "uv", "default_color", "texture_mode", "visible"]

## Classe e arma mostradas no editor. Fixas porque o autoload GameData nao roda
## no editor, logo nao ha "arma equipada" para consultar aqui.
const CLASSE_DA_PREVIA := "heroi_guerreiro"
const ARMA_DA_PREVIA := "arma_espada"
const QUADROS_DO_HEROI := 4
const QUADROS_DA_GALINHA := 4
const QUADROS_DA_GALINHA_REAL := 2
const QUADROS_DE_OVO := 5

## Marque no inspetor para revestir depois de criar uma plataforma nova ou de
## arrastar alguma coisa entre regioes da fase (fazenda/entrada/porao).
@export var revestir := false:
	set(valor):
		revestir = false
		if valor and Engine.is_editor_hint():
			despir()
			vestir()

var _vestida := false
var _retrato := {}


func _ready() -> void:
	# Em jogo quem veste e fase1.gd, com o mesmo codigo; aqui so o editor.
	if Engine.is_editor_hint():
		vestir()


func _notification(o_que: int) -> void:
	if not Engine.is_editor_hint():
		return
	if o_que == NOTIFICATION_EDITOR_PRE_SAVE:
		despir()
	elif o_que == NOTIFICATION_EDITOR_POST_SAVE:
		vestir()


func vestir() -> void:
	"""Veste a cena. Publica para o teste poder exercitar o par vestir/despir
	sem abrir o editor."""
	if _vestida:
		return
	_guardar_retrato()
	_vestida = true
	var cenario := get_node_or_null("Cenario") as Node2D
	if cenario:
		Terreno.montar(cenario)
		Tochas.montar(cenario)
		Adornos.montar(cenario)
	_vestir_personagens()


func despir() -> void:
	"""Desfaz a vestimenta e devolve o layout cru, como ele esta no .tscn."""
	if not _vestida:
		return
	_remover_gerados(self)
	_devolver_retrato()
	_vestida = false


func _guardar_retrato() -> void:
	_retrato.clear()
	for no in _descendentes():
		var valores := {}
		for propriedade in PROPRIEDADES_DA_VESTIMENTA:
			var valor: Variant = no.get(propriedade)
			if valor != null:
				valores[propriedade] = valor
		if not valores.is_empty():
			_retrato[no] = valores


func _devolver_retrato() -> void:
	for no in _retrato:
		if not is_instance_valid(no):
			continue
		for propriedade in _retrato[no]:
			no.set(propriedade, _retrato[no][propriedade])
	_retrato.clear()


func _descendentes() -> Array[Node]:
	var achados: Array[Node] = []
	var pilha: Array[Node] = get_children()
	while not pilha.is_empty():
		var no: Node = pilha.pop_back()
		achados.append(no)
		pilha.append_array(no.get_children())
	return achados


func _remover_gerados(no: Node) -> void:
	"""Apaga o que a vestimenta criou. Reconhece pelo `owner` nulo: no salvo em
	cena sempre tem dono, no criado em codigo nunca -- e e justamente por isso
	que a vestimenta nao vaza para o .tscn."""
	for filho in no.get_children():
		if filho.owner == null:
			no.remove_child(filho)
			filho.queue_free()
		else:
			_remover_gerados(filho)


func _vestir_personagens() -> void:
	var personagens := get_node_or_null("Personagens")
	if not personagens:
		return
	_vestir_heroi(personagens.get_node_or_null("Jogador"))
	for marcador in _marcadores(personagens, "Bots"):
		_trocar_por_sprite(marcador, Bestiario.folha_de(Bestiario.tipo_do_marcador(marcador)), QUADROS_DA_GALINHA)
	for marcador in _marcadores(personagens, "Ovos"):
		_trocar_por_ovo(marcador)
	_trocar_por_sprite(personagens.get_node_or_null("GalinhaReal"),
			Sprites.GALINHA_REAL, QUADROS_DA_GALINHA_REAL)


func _marcadores(personagens: Node, grupo: String) -> Array[Node]:
	var no := personagens.get_node_or_null(grupo)
	if not no:
		return []
	return no.get_children()


func _vestir_heroi(marcador: Node2D) -> void:
	if not marcador:
		return
	_apagar_marcador(marcador)
	Sprites.montar(marcador, CLASSE_DA_PREVIA, QUADROS_DO_HEROI)
	var arma := Sprites.montar_centrado(marcador, ARMA_DA_PREVIA, 1)
	if arma:
		# Mesma pose de repouso de player.gd: arma ancorada pelo cabo na mao.
		arma.offset.x = 0.0
		arma.position = Vector2(Jogador.ALCANCE_DA_MAO, Jogador.ALTURA_DA_MAO)


func _trocar_por_ovo(marcador: Node2D) -> void:
	if not marcador:
		return
	_apagar_marcador(marcador)
	# Ovo flutua: ancorado pelo centro, como em egg_pickup.gd.
	var sprite := Sprites.montar_centrado(marcador, Sprites.OVOS, QUADROS_DE_OVO)
	if sprite:
		sprite.frame = clampi(int(marcador.get_meta("egg_kind", 1)), 0, QUADROS_DE_OVO - 1)


func _trocar_por_sprite(marcador: Node2D, folha: String, quadros: int) -> void:
	if not marcador:
		return
	_apagar_marcador(marcador)
	Sprites.montar(marcador, folha, quadros)


func _apagar_marcador(marcador: Node2D) -> void:
	"""Zera o alfa do poligono em vez de esconder o no: esconder levaria o
	sprite filho junto, porque visibilidade e herdada."""
	if marcador is Polygon2D:
		marcador.color = Color.TRANSPARENT
		return
	for filho in marcador.get_children():
		if filho is Polygon2D:
			filho.color = Color.TRANSPARENT
