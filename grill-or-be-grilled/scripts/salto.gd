extends RefCounted

## Pulo de plataforma com as folgas que o jogador espera sentir: coyote time,
## buffer de entrada, altura variavel e gravidade assimetrica.
##
## Guarda estado entre frames (os dois temporizadores), por isso e instancia e
## nao primitiva estatica como as de character_movement.gd.
##
## Exemplo:
##     var salto := Salto.new()
##     func _physics_process(delta: float) -> void:
##         salto.atualizar(self, delta, Input.is_action_just_pressed("pular"),
##             Input.is_action_pressed("pular"))
##         move_and_slide()

## O envelope do arco e INTOCAVEL sem mexer na fase: alcance = tempo de ar x
## velocidade, e os gaps largos da fase 1 estao calibrados no limite do arco
## original (Trecho11 -> Trecho12 passava com -3px de margem, ou seja so pela
## pedra RotaAlta11). Entao 500/1150 mantem 105px de altura e 0.78s de ar, os
## mesmos de antes, e o peso vem todo da assimetria: a queda e 1.6x mais pesada
## que a subida, que e onde a flutuacao era sentida. Encurtar o ar de verdade
## exige reposicionar RotaAlta7/8/11/13/15 ou subir a velocidade de corrida.
const VELOCIDADE := -500.0
const GRAVIDADE_DE_SUBIDA := 1150.0
const GRAVIDADE_DE_QUEDA := 1800.0

## Teto da velocidade vertical ao soltar o botao ainda subindo: um toque curto
## sobe ~17px, o bastante para um degrau, e o pulo cheio continua inteiro.
const VELOCIDADE_DE_TOQUE := -200.0

## Janela para pular depois de ja ter saido da plataforma (coyote time) e para
## registrar um pulo apertado pouco antes de encostar no chao (buffer). 0.1s le
## como "obedeceu" sem o personagem parecer que pula do ar.
const FOLGA_DE_BORDA := 0.1
const FOLGA_DE_ANTECIPACAO := 0.1

var _folga_de_borda := 0.0
var _folga_de_antecipacao := 0.0


func atualizar(corpo: CharacterBody2D, delta: float, pediu: bool, segura: bool) -> void:
	"""Resolve o pulo do frame e aplica a gravidade. Chame antes de move_and_slide."""
	_contar_folgas(corpo, delta, pediu)
	if _folga_de_antecipacao > 0.0 and _folga_de_borda > 0.0:
		_saltar(corpo)
	elif not segura and corpo.velocity.y < VELOCIDADE_DE_TOQUE:
		corpo.velocity.y = VELOCIDADE_DE_TOQUE
	_aplicar_gravidade(corpo, delta)


func _contar_folgas(corpo: CharacterBody2D, delta: float, pediu: bool) -> void:
	_folga_de_borda = FOLGA_DE_BORDA if corpo.is_on_floor() else maxf(0.0, _folga_de_borda - delta)
	_folga_de_antecipacao = FOLGA_DE_ANTECIPACAO if pediu else maxf(0.0, _folga_de_antecipacao - delta)


func _saltar(corpo: CharacterBody2D) -> void:
	corpo.velocity.y = VELOCIDADE
	# Zerar as duas janelas: sem isso o mesmo toque gastaria o buffer de novo no
	# frame seguinte e viraria pulo duplo.
	_folga_de_borda = 0.0
	_folga_de_antecipacao = 0.0


func _aplicar_gravidade(corpo: CharacterBody2D, delta: float) -> void:
	if corpo.is_on_floor():
		return
	var gravidade := GRAVIDADE_DE_SUBIDA if corpo.velocity.y < 0.0 else GRAVIDADE_DE_QUEDA
	corpo.velocity.y += gravidade * delta
