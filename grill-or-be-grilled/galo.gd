extends "res://chicken_enemy.gd"

## Galo de Briga: aguenta mais golpes e, em vez de bicar, avisa e dispara uma
## investida curta pelo chao que machuca no contato. A resposta e a mesma da
## investida da Galinha Real, em escala menor: esquivar atraves dele ou pular.
##
## Exemplo: um Bot com metadata/tipo = "galo" no jogo.tscn vira este inimigo.

const ALCANCE_DO_BOTE := 140.0
const PREPARO_DO_BOTE := 0.55
const DURACAO_DO_BOTE := 0.4
const VELOCIDADE_DO_BOTE := 320.0
const RECARGA_DO_BOTE := 1.6
const DANO_DO_BOTE := 2

var investindo := 0.0
var acertou := false


func configure_progression(progress: float) -> void:
	super(progress)
	health += 3


func _perseguir() -> void:
	if investindo > 0.0 or attack_windup > 0.0:
		return
	_virar_para_o_alvo()
	_andar(facing, speed * 0.8)


func _atacar(delta: float) -> void:
	if investindo > 0.0:
		_investir(delta)
	elif attack_windup > 0.0:
		velocity.x = 0.0
		attack_windup -= delta
		if attack_windup <= 0.0:
			investindo = DURACAO_DO_BOTE
			acertou = false
	elif attack_cooldown <= 0.0 and _alvo_no_alcance_do_bote():
		attack_windup = PREPARO_DO_BOTE


func _investir(delta: float) -> void:
	investindo = maxf(0.0, investindo - delta)
	velocity.x = facing * VELOCIDADE_DO_BOTE if _has_floor_ahead(facing) else 0.0
	if investindo <= 0.0:
		attack_cooldown = RECARGA_DO_BOTE
	if not acertou and _player_in_peck_range():
		acertou = true
		target.take_damage(DANO_DO_BOTE, global_position)


func _alvo_no_alcance_do_bote() -> bool:
	return is_instance_valid(target) and absf(target.global_position.x - global_position.x) < ALCANCE_DO_BOTE and absf(target.global_position.y - global_position.y) < 30.0


func take_damage(amount: int, origem: Vector2 = Vector2.INF) -> void:
	# Investindo, o galo nao recua: e o que deixa o bote perigoso de encarar.
	var embalado := investindo > 0.0
	super(amount, origem)
	if embalado:
		hit_stun = 0.0
		velocity.x = facing * VELOCIDADE_DO_BOTE
