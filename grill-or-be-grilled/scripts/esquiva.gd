extends RefCounted

## Esquiva curta com invulnerabilidade: a resposta do jogador ao aviso de golpe.
##
## Sem ela a unica defesa era pular, e a investida e a onda de choque da
## Galinha Real pedem sair do lugar no chao. A janela de invulnerabilidade cobre
## a esquiva inteira e um pouco depois, como em Hollow Knight e Dead Cells: o
## jogador que acerta o tempo nao toma o golpe nem raspando no fim do movimento.
##
## Exemplo:
##     var esquiva := Esquiva.new()
##     if Input.is_action_just_pressed("esquivar"):
##         esquiva.iniciar()
##     esquiva.atualizar(delta)
##     if esquiva.ativa():
##         velocity.x = facing * Esquiva.VELOCIDADE

const VELOCIDADE := 430.0
const DURACAO := 0.18
const INVULNERAVEL_POR := 0.28
const RECARGA := 0.6

var _restante := 0.0
var _protecao := 0.0
var _recarga := 0.0


func iniciar() -> bool:
	"""Comeca a esquiva se ela ja recarregou. Devolve se comecou."""
	if _recarga > 0.0:
		return false
	_restante = DURACAO
	_protecao = INVULNERAVEL_POR
	_recarga = RECARGA
	return true


func atualizar(delta: float) -> void:
	_restante = maxf(0.0, _restante - delta)
	_protecao = maxf(0.0, _protecao - delta)
	_recarga = maxf(0.0, _recarga - delta)


func ativa() -> bool:
	return _restante > 0.0


func protege() -> bool:
	return _protecao > 0.0
