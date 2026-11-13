extends Node2D

# Testes da Galinha Real: a onda de choque so pega quem esta no chao, a
# investida machuca no contato e a fase 2 comeca em metade da vida.
# Este no faz o papel da fase (o chefe chama metodos de "game").
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_do_chefe.tscn

const Chefe = preload("res://chicken_boss.gd")
const PISO_Y := 400.0

var _falhas: PackedStringArray = []
var enfurecida := 0

func update_boss_health(_atual: int, _maximo: int) -> void:
	pass

func shockwave_effect(_onde: Vector2, _alcance: float) -> void:
	pass

func boss_enraged() -> void:
	enfurecida += 1

func boss_defeated(_onde: Vector2) -> void:
	pass

func _ready() -> void:
	add_to_group("game")
	_criar_piso()
	await _testar_onda_poupa_quem_pula()
	await _testar_onda_pega_quem_fica()
	await _testar_investida_no_contato()
	_testar_fase_2()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("CHEFE_OK 4 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_onda_poupa_quem_pula() -> void:
	var alvo := AlvoFalso.new()
	alvo.no_chao = false
	var chefe := await _chefe_pousando(alvo)
	_exigir("onda poupa quem esta no ar", alvo.dano == 0, "tomou %d" % alvo.dano)
	chefe.queue_free()


func _testar_onda_pega_quem_fica() -> void:
	var alvo := AlvoFalso.new()
	var chefe := await _chefe_pousando(alvo)
	_exigir("onda pega quem esta no chao", alvo.dano == Chefe.DANO, "tomou %d" % alvo.dano)
	chefe.queue_free()


func _testar_investida_no_contato() -> void:
	var alvo := AlvoFalso.new()
	alvo.position = Vector2(60, PISO_Y)
	add_child(alvo)
	var chefe := _novo_chefe(alvo)
	chefe.facing = 1.0
	chefe.investindo = Chefe.DURACAO_DA_INVESTIDA
	for frame in 20:
		chefe._investir(1.0 / 60.0)
		chefe.move_and_slide()
		await get_tree().physics_frame
	_exigir("investida machuca no contato", alvo.dano > 0, "alvo intocado a 60px")
	chefe.queue_free()
	alvo.queue_free()


func _testar_fase_2() -> void:
	var alvo := AlvoFalso.new()
	var chefe := _novo_chefe(alvo)
	chefe.take_damage(chefe.max_health / 2)
	_exigir("fase 2 em metade da vida", chefe.fase == 1 and enfurecida == 1, "fase=%d avisos=%d" % [chefe.fase, enfurecida])
	chefe.queue_free()
	alvo.free()


func _chefe_pousando(alvo: AlvoFalso) -> CharacterBody2D:
	"""Chefe 30px acima do piso, ja saltando, com o alvo a 80px."""
	alvo.position = Vector2(80, PISO_Y)
	add_child(alvo)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var chefe := _novo_chefe(alvo)
	chefe.position = Vector2(0, PISO_Y - 30)
	chefe.saltando = true
	chefe.set_physics_process(false)
	for frame in 30:
		chefe.velocity.y += chefe.gravity / 60.0
		chefe.move_and_slide()
		chefe._pousar_se_saltava()
		await get_tree().physics_frame
	alvo.queue_free()
	return chefe


func _novo_chefe(alvo: AlvoFalso) -> CharacterBody2D:
	var chefe := CharacterBody2D.new()
	chefe.set_script(Chefe)
	chefe.position = Vector2(0, PISO_Y)
	chefe.target = alvo
	add_child(chefe)
	return chefe


func _criar_piso() -> void:
	var piso := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(1200, 20)
	forma.shape = retangulo
	forma.position = Vector2(0, PISO_Y + 10)
	piso.add_child(forma)
	add_child(piso)


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])


## Heroi falso: registra o dano. No chao, cai e pousa de verdade (is_on_floor
## e nativo e nao da para sobrescrever); "no ar", fica parado 60px acima do piso.
class AlvoFalso extends CharacterBody2D:
	var dano := 0
	var no_chao := true

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var forma := CollisionShape2D.new()
		var capsula := CapsuleShape2D.new()
		capsula.radius = 7
		capsula.height = 26
		forma.shape = capsula
		forma.position.y = -13
		add_child(forma)
		if not no_chao:
			position.y -= 60.0

	func _physics_process(delta: float) -> void:
		if no_chao:
			velocity.y += 1000.0 * delta
			move_and_slide()

	func take_damage(quanto: int, _origem: Vector2 = Vector2.INF) -> void:
		dano += quanto
