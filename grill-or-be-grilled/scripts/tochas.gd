@tool
extends RefCounted

## Troca as tochas chapadas da cena por tocha com chama animada e halo de luz.
##
## Os Polygon2D originais de cada Tocha* nao sao apagados, so escondidos em
## tempo de execucao: a cena salva continua mostrando o marcador no editor do
## Godot (onde Douglas e Jorge posicionam as tochas), enquanto o jogo desenha a
## arte de verdade por cima. Mover a Tocha no editor continua funcionando.
##
## E @tool porque scripts/previa_do_editor.gd monta as tochas dentro do editor
## tambem, e callback de script sem @tool nao roda la -- sem isto o marcador
## sumiria e nada apareceria no lugar.
##
## Exemplo:
##     Tochas.montar($EditorPreview/Cenario)

const Sprites = preload("res://scripts/sprites.gd")
const Iluminacao = preload("res://scripts/iluminacao.gd")
const Terreno = preload("res://scripts/terreno.gd")
const Superficie = preload("res://scripts/superficie.gd")

const PREFIXO := "Tocha"
const QUADROS_DE_CHAMA := 4
## Medidas de Artes/gerado/poste.png e do castical (tools/arte/props.py).
const ALTURA_DO_POSTE := 34.0
const ALTURA_DO_CASTICAL := 10.0
const LARGURA_DO_POSTE := 7.0


static func montar(cenario: Node2D) -> int:
	"""Instala a tocha animada em cada marcador. Devolve quantas foram criadas."""
	if not cenario:
		push_error("Tochas.montar recebeu cenario nulo; esperado EditorPreview/Cenario")
		return 0
	var total := 0
	for no in cenario.get_children():
		if not str(no.name).begins_with(PREFIXO) or not no is Node2D:
			continue
		for marcador in no.get_children():
			marcador.hide()
		var tocha := Tocha.new()
		no.add_child(tocha)
		if Terreno.regiao_em(no.global_position.x) == "fazenda":
			_plantar_em_poste(cenario, tocha)
		total += 1
	return total


static func _plantar_em_poste(cenario: Node2D, tocha: Tocha) -> void:
	"""Ao ar livre nao ha parede onde prender a tocha: ela descia pendurada no
	ceu. Aqui ela desce ate o chao abaixo do marcador e ganha um poste; sobre um
	vao nao ha onde fincar, entao ela some (luz incluida)."""
	var chao := Superficie.chao_abaixo(cenario, tocha.global_position)
	if not is_finite(chao):
		tocha.hide()
		if tocha.luz:
			tocha.luz.enabled = false
		return
	tocha.global_position.y = chao - ALTURA_DO_POSTE - ALTURA_DO_CASTICAL
	var poste := Sprites.anexar(tocha, "poste", 1,
			Vector2(-roundf(LARGURA_DO_POSTE / 2.0), ALTURA_DO_CASTICAL))
	if poste:
		poste.show_behind_parent = true


## Uma tocha acesa: castical, chama de 4 quadros e halo aditivo.
class Tocha extends Node2D:
	const ALFA_BASE := 0.40
	const ALFA_PULSO := 0.09

	const ENERGIA_DA_LUZ := 1.4
	const ESCALA_DA_LUZ := 2.4

	var chama: Sprite2D
	var halo: Sprite2D
	## Luz que ilumina o cenario em volta (so em jogo; no editor nao ha
	## escuridao ambiente e a luz so lavaria a fase).
	var luz: PointLight2D
	var tempo := 0.0

	func _ready() -> void:
		# Fase inicial sorteada: sem isso as 33 tochas da fase piscam no mesmo
		# compasso e o cenario inteiro pulsa junto, o que entrega o truque.
		tempo = randf() * 10.0
		var suporte := Sprites.celula("tocha_suporte", 1)
		Sprites.anexar(self, "tocha_suporte", 1, Vector2(-suporte.x / 2.0, 0))
		var tamanho_da_chama := Sprites.celula("tocha_chama", QUADROS_DE_CHAMA)
		chama = Sprites.anexar(self, "tocha_chama", QUADROS_DE_CHAMA,
				Vector2(-tamanho_da_chama.x / 2.0, -tamanho_da_chama.y))
		halo = _montar_halo()
		if not Engine.is_editor_hint():
			luz = Iluminacao.luz(Iluminacao.COR_DO_FOGO, ENERGIA_DA_LUZ, ESCALA_DA_LUZ)
			luz.position.y = -6.0
			add_child(luz)

	func _montar_halo() -> Sprite2D:
		var tamanho := Sprites.celula("brilho", 1)
		var sprite := Sprites.anexar(self, "brilho", 1,
				Vector2(-tamanho.x / 2.0, -tamanho.y / 2.0 - 6.0))
		if not sprite:
			return null
		var aditivo := CanvasItemMaterial.new()
		aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = aditivo
		sprite.z_index = -1
		sprite.modulate.a = ALFA_BASE
		return sprite

	func _process(delta: float) -> void:
		# No editor a chama fica num quadro fixo: 33 tochas animando manteriam o
		# viewport redesenhando sem parar enquanto a fase e editada.
		if Engine.is_editor_hint():
			set_process(false)
			return
		tempo += delta
		if chama:
			chama.frame = int(tempo * 11.0) % QUADROS_DE_CHAMA
		if halo:
			halo.modulate.a = ALFA_BASE + ALFA_PULSO * sin(tempo * 7.0)
		if luz:
			luz.energy = ENERGIA_DA_LUZ + 0.12 * sin(tempo * 7.0)
