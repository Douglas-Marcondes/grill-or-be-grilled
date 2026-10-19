extends Node2D

# Testes do modulo de salto (scripts/salto.gd): o arco e as folgas que a camada
# de controle promete. Rodam num piso isolado, sem a fase, porque medir coyote
# time e buffer no meio das galinhas seria lento e nao repetivel.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_do_salto.tscn

const Salto = preload("res://scripts/salto.gd")

const PISO_Y := 400.0
const MEIA_LARGURA_DO_PISO := 300.0
const ALTURA_ESPERADA := 105.0
## Teto do toque de 3 frames. Nao e o teto teorico do corte (17px): os 3 frames
## de subida antes de soltar o botao ja valem ~15px que nao voltam.
const ALTURA_DO_TOQUE_CURTO := 45.0
const FRAMES_DE_UM_ARCO := 70

var _falhas: PackedStringArray = []

func _ready() -> void:
	_criar_piso()
	await _testar_arco_cheio()
	await _testar_toque_curto()
	await _testar_folga_de_borda()
	await _testar_folga_de_antecipacao()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("SALTO_OK 5 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_arco_cheio() -> void:
	"""Altura e proporcao subida/queda: o envelope que mantem a fase 1 passavel."""
	var corpo := await _corpo_no_piso()
	corpo.segura = true
	corpo.pediu = true
	await _esperar(FRAMES_DE_UM_ARCO)
	_conferir("altura do pulo cheio", corpo.altura_maxima, ALTURA_ESPERADA, 10.0)
	_exigir("queda mais rapida que a subida", corpo.frames_caindo < corpo.frames_subindo,
		"subiu em %d frames e caiu em %d" % [corpo.frames_subindo, corpo.frames_caindo])
	corpo.queue_free()


func _testar_toque_curto() -> void:
	"""Altura variavel: soltar o botao no inicio da subida encurta o pulo."""
	var corpo := await _corpo_no_piso()
	corpo.segura = true
	corpo.pediu = true
	await _esperar(2)
	corpo.segura = false
	await _esperar(FRAMES_DE_UM_ARCO)
	_exigir("toque curto sobe menos que o pulo cheio", corpo.altura_maxima < ALTURA_DO_TOQUE_CURTO,
		"subiu %.0fpx, esperado menos de %.0fpx" % [corpo.altura_maxima, ALTURA_DO_TOQUE_CURTO])
	corpo.queue_free()


func _testar_folga_de_borda() -> void:
	"""Coyote time: pular pouco depois de ja ter saido da plataforma."""
	var corpo := await _corpo_no_piso()
	corpo.deslocamento = 220.0
	while corpo.is_on_floor():
		await get_tree().physics_frame
	corpo.segura = true
	corpo.pediu = true
	await get_tree().physics_frame
	_conferir("folga de borda (coyote)", corpo.velocity.y, Salto.VELOCIDADE, 40.0)
	corpo.queue_free()


func _testar_folga_de_antecipacao() -> void:
	"""Buffer: um unico toque pouco antes de encostar no chao ainda vira pulo."""
	var corpo := await _corpo_no_piso()
	corpo.segura = true
	corpo.pediu = true
	await _esperar(2)
	while corpo.velocity.y <= 0.0 or PISO_Y - corpo.global_position.y > 15.0:
		await get_tree().physics_frame
	corpo.pediu = true
	var saltou := false
	for _i in 20:
		await get_tree().physics_frame
		saltou = saltou or corpo.velocity.y < -100.0
	_exigir("folga de antecipacao (buffer)", saltou, "o toque antes da aterrissagem nao virou pulo")
	corpo.queue_free()


func _criar_piso() -> void:
	var piso := StaticBody2D.new()
	piso.collision_layer = 1
	piso.position = Vector2(0, PISO_Y)
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(MEIA_LARGURA_DO_PISO * 2.0, 40.0)
	forma.shape = retangulo
	forma.position.y = 20.0
	piso.add_child(forma)
	add_child(piso)


func _corpo_no_piso() -> CorpoDeTeste:
	var corpo := CorpoDeTeste.new()
	corpo.position = Vector2(-MEIA_LARGURA_DO_PISO + 60.0, PISO_Y - 60.0)
	add_child(corpo)
	while not corpo.is_on_floor():
		await get_tree().physics_frame
	corpo.zerar_medidas()
	return corpo


func _esperar(frames: int) -> void:
	for _i in frames:
		await get_tree().physics_frame


func _conferir(nome: String, obtido: float, esperado: float, tolerancia: float) -> void:
	_exigir(nome, absf(obtido - esperado) <= tolerancia,
		"obtido %.1f, esperado %.1f +- %.1f" % [obtido, esperado, tolerancia])


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])


## Corpo minimo que roda o Salto como o jogador roda, para o teste so precisar
## ligar e desligar os dois sinais de entrada.
class CorpoDeTeste extends CharacterBody2D:
	var salto := Salto.new()
	var pediu := false
	var segura := false
	var deslocamento := 0.0
	var altura_maxima := 0.0
	var frames_subindo := 0
	var frames_caindo := 0
	var _altura_do_chao := 0.0

	func _init() -> void:
		collision_layer = 1
		collision_mask = 1
		var forma := CollisionShape2D.new()
		var capsula := CapsuleShape2D.new()
		capsula.radius = 7
		capsula.height = 26
		forma.shape = capsula
		forma.position.y = -13
		add_child(forma)

	func zerar_medidas() -> void:
		altura_maxima = 0.0
		frames_subindo = 0
		frames_caindo = 0
		_altura_do_chao = global_position.y

	func _physics_process(delta: float) -> void:
		if is_on_floor():
			_altura_do_chao = global_position.y
		velocity.x = deslocamento
		salto.atualizar(self, delta, pediu, segura)
		# Um toque por chamada: o teste liga `pediu` e o corpo o consome, que e o
		# que is_action_just_pressed faz no jogador.
		pediu = false
		move_and_slide()
		altura_maxima = maxf(altura_maxima, _altura_do_chao - global_position.y)
		if not is_on_floor():
			if velocity.y < 0.0:
				frames_subindo += 1
			else:
				frames_caindo += 1
