extends "res://chicken_enemy.gd"

## Galinha Atiradeira: guarda distancia e arremessa ovos em arco. Fica parada
## na faixa de tiro, recua se o heroi chega perto e so avanca se ele foge longe
## demais -- e o inimigo que obriga o jogador a fechar distancia em vez de
## esperar a galinha vir ate a espada.
##
## Exemplo: um Bot com metadata/tipo = "atiradeira" no jogo.tscn vira este inimigo.

const Projetil = preload("res://projectile.gd")

const DISTANCIA_MINIMA := 90.0
const DISTANCIA_MAXIMA := 230.0
const PREPARO_DO_ARREMESSO := 0.45
const RECARGA_DO_ARREMESSO := 1.9
const GRAVIDADE_DO_OVO := 700.0
## Tempo de voo do ovo: cresce com a distancia, para o arco nao virar linha reta
## de perto nem um balao lento de longe.
const VOO_MINIMO := 0.55
const VOO_MAXIMO := 1.0


func _perseguir() -> void:
	var distance := absf(_virar_para_o_alvo())
	if attack_windup > 0.0 or (distance >= DISTANCIA_MINIMA and distance <= DISTANCIA_MAXIMA):
		velocity.x = 0.0
	elif distance < DISTANCIA_MINIMA:
		_andar(-facing, speed * 0.7)
	else:
		_andar(facing, speed)


func _atacar(delta: float) -> void:
	if attack_windup > 0.0:
		attack_windup -= delta
		if attack_windup <= 0.0:
			_arremessar()
			Som.tocar("tiro")
			attack_cooldown = RECARGA_DO_ARREMESSO
	elif attack_cooldown <= 0.0 and _ameacada() and _na_faixa_de_tiro():
		attack_windup = PREPARO_DO_ARREMESSO


func _na_faixa_de_tiro() -> bool:
	"""De perto ela foge antes de atirar: arremesso a queima-roupa nao da tempo
	de reagir e deixaria a atiradeira sem fraqueza."""
	return absf(target.global_position.x - global_position.x) >= DISTANCIA_MINIMA


func _arremessar() -> void:
	if not is_instance_valid(target):
		return
	var saida := global_position + Vector2(facing * 10.0, -18.0)
	var ovo := Area2D.new()
	ovo.set_script(Projetil)
	ovo.global_position = saida
	var lancamento := arco_ate(target.global_position + Vector2(0, -12), saida)
	ovo.direction = lancamento.normalized()
	ovo.speed = lancamento.length()
	ovo.gravidade = GRAVIDADE_DO_OVO
	ovo.tipo = "ovo"
	ovo.target_mask = 1
	get_tree().current_scene.add_child(ovo)


static func arco_ate(alvo: Vector2, saida: Vector2) -> Vector2:
	"""Velocidade inicial para um projetil com GRAVIDADE_DO_OVO sair de `saida`
	e passar por `alvo`.

	Exemplo: arco_ate(Vector2(200, 0), Vector2.ZERO) -> Vector2(220, ~-318)
	"""
	var delta := alvo - saida
	var voo := clampf(absf(delta.x) / 220.0, VOO_MINIMO, VOO_MAXIMO)
	return Vector2(delta.x / voo, (delta.y - 0.5 * GRAVIDADE_DO_OVO * voo * voo) / voo)
