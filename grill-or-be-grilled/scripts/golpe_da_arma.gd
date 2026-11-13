extends RefCounted

## Movimento da arma durante o golpe: giro e avanco em funcao do progresso.
##
## A arma era um sprite parado que so dava um passo a frente no ataque -- a
## espada "golpeava" sem se mexer. Aqui cada arma tem a sua coreografia: a
## espada sobe atras do ombro e desce num arco, a varinha da um peteleco e o
## arco coiceia para tras ao soltar a flecha.
##
## O progresso vai de 0 (golpe acabou de sair) a 1 (acabou). Os angulos valem
## para o heroi olhando para a direita; player.gd espelha pelo `facing`.
##
## Exemplo:
##     arma.rotation = facing * GolpeDaArma.giro("Espada", 0.1)

## Fracao do golpe gasta no movimento de ida; o resto e a volta ao repouso.
const IDA := 0.4

## Por arma: angulo no inicio da ida, angulo no fim da ida (graus) e avanco
## maximo da mao (px; negativo e coice).
const COREOGRAFIA := {
	"Espada": [-115.0, 45.0, 5.0],
	"Varinha": [-50.0, 20.0, 3.0],
	"Arco": [0.0, 0.0, -3.0],
}


static func giro(arma: String, progresso: float) -> float:
	"""Rotacao da arma, em radianos, olhando para a direita."""
	var passos: Array = _passos(arma)
	if progresso >= 1.0:
		return 0.0
	if progresso < IDA:
		return deg_to_rad(lerpf(passos[0], passos[1], ease(progresso / IDA, 0.4)))
	return deg_to_rad(lerpf(passos[1], 0.0, (progresso - IDA) / (1.0 - IDA)))


static func avanco(arma: String, progresso: float) -> float:
	"""Quanto a mao se afasta do corpo, em pixels: cheio na ida, some na volta."""
	var passos: Array = _passos(arma)
	if progresso >= 1.0:
		return 0.0
	if progresso < IDA:
		return passos[2]
	return lerpf(passos[2], 0.0, (progresso - IDA) / (1.0 - IDA))


static func _passos(arma: String) -> Array:
	if not COREOGRAFIA.has(arma):
		push_error("arma sem coreografia de golpe: \"%s\"; esperado uma de %s" % [arma, COREOGRAFIA.keys()])
		return [0.0, 0.0, 0.0]
	return COREOGRAFIA[arma]
