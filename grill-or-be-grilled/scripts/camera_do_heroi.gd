extends Camera2D

## Camera que segue o heroi: olha para onde ele anda e treme no impacto.
##
## O olhar a frente existe porque no viewport de 480x270 o jogador via so
## ~240px adiante e as galinhas comecavam a perseguir de fora da tela
## (PENDENCIAS.md, "Camera"). O tremor usa o modelo de "trauma" (Squirrel
## Eiserloh, GDC 2016): o deslocamento cresce com o quadrado do trauma, entao
## batida leve quase nao mexe e batida forte sacode de verdade.
##
## Exemplo:
##     var camera := CameraDoHeroi.new()
##     add_child(camera)
##     camera.direcao = -1.0   # passa a olhar para a esquerda
##     camera.tremer(0.4)

## Viewport de 270px de altura: olhar 120px acima jogaria o personagem para fora
## do quadro, entao a folga de cima caiu junto com a resolucao.
const FormatoDaTela = preload("res://scripts/formato_da_tela.gd")

const ALTURA_DO_OLHAR := -40.0
const OLHAR_A_FRENTE := 34.0
const VELOCIDADE_DO_OLHAR := 180.0
const TREMOR_MAXIMO := 6.0
const ALIVIO_DO_TRAUMA := 2.2

var direcao := 1.0
## Limite de baixo do quadro do jogo. Em pe a tela e mais alta que a faixa de
## 270px, e o limit_bottom real cresce junto com a sobra (ver _process).
var limite_de_baixo := 10000000
var _olhar := OLHAR_A_FRENTE
var _trauma := 0.0


func _ready() -> void:
	position = Vector2(0, ALTURA_DO_OLHAR)
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


func _process(delta: float) -> void:
	_olhar = move_toward(_olhar, direcao * OLHAR_A_FRENTE, VELOCIDADE_DO_OLHAR * delta)
	_trauma = maxf(0.0, _trauma - ALIVIO_DO_TRAUMA * delta)
	var sacudida := TREMOR_MAXIMO * _trauma * _trauma
	# Em pe, desce o centro da camera metade da sobra: o heroi aparece na faixa
	# de cima, no mesmo lugar que deitado, e a sobra de baixo e do painel.
	var sobra := FormatoDaTela.sobra(get_viewport())
	limit_bottom = limite_de_baixo + int(sobra)
	offset = Vector2(_olhar, sobra / 2.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * sacudida


func tremer(forca: float) -> void:
	"""Soma trauma de 0 a 1; o tremor some sozinho em menos de meio segundo."""
	_trauma = clampf(_trauma + forca, 0.0, 1.0)
