extends Node2D

# Teste das passagens: para cada par de trechos vizinhos da fase 1, poe o heroi
# correndo na saida do trecho e pula na borda com o pulo cheio. Falha se algum
# vao nao puder ser atravessado assim -- que e o que o jogador tenta primeiro.
#
# Existe por causa das pedras RotaAlta7/8/11/13, que pendiam sobre a saida do
# trecho anterior e faziam o heroi bater a cabeca nelas (PENDENCIAS.md,
# "Passagens travadas", 19/10/2026).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_das_passagens.tscn

const RECUO_DA_LARGADA := 140.0
const FRAMES_POR_PASSAGEM := 240
const FRAMES_SEGURANDO_O_PULO := 28
## Abaixo disso o heroi ja caiu no buraco, mesmo que a morte so venha depois.
const Y_DE_QUEDA := 700.0

var _falhas: PackedStringArray = []
var _segurando := 0

func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Guerreiro")
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		inimigo.queue_free()
	await get_tree().physics_frame
	var trechos := _trechos_ordenados(game.get_node("EditorPreview/Cenario"))
	for indice in trechos.size() - 1:
		await _atravessar(game.player, trechos[indice], trechos[indice + 1])
	await _testar_quina(game.player, trechos[2])
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("PASSAGENS_OK %d vaos" % (trechos.size() - 1))
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _trechos_ordenados(cenario: Node2D) -> Array[Rect2]:
	"""Caixas de mundo dos Trecho*, da esquerda para a direita."""
	var caixas: Array[Rect2] = []
	for arte in cenario.get_children():
		if arte is Polygon2D and str(arte.name).begins_with("Trecho"):
			caixas.append(_caixa(arte))
	caixas.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	return caixas


func _caixa(arte: Polygon2D) -> Rect2:
	var caixa := Rect2(arte.to_global(arte.polygon[0]), Vector2.ZERO)
	for ponto in arte.polygon:
		caixa = caixa.expand(arte.to_global(ponto))
	return caixa


func _atravessar(jogador: CharacterBody2D, de: Rect2, para: Rect2) -> void:
	jogador.global_position = Vector2(de.end.x - RECUO_DA_LARGADA, _topo_em(jogador, de.end.x - RECUO_DA_LARGADA) - 1.0)
	jogador.velocity = Vector2.ZERO
	jogador.health = jogador.max_health
	Input.action_press("andar_direita")
	for frame in FRAMES_POR_PASSAGEM:
		_pular_na_borda(jogador)
		await get_tree().physics_frame
		if jogador.global_position.y > Y_DE_QUEDA:
			break
		if jogador.is_on_floor() and jogador.global_position.x > para.position.x + 30.0:
			break
	Input.action_release("andar_direita")
	Input.action_release("pular")
	_segurando = 0
	var chegou := jogador.is_on_floor() and jogador.global_position.x > para.position.x + 30.0
	if not chegou:
		_falhas.append("vao x=%.0f -> x=%.0f: heroi parou em (%.0f, %.0f), esperado em pe depois de x=%.0f" % [de.end.x, para.position.x, jogador.global_position.x, jogador.global_position.y, para.position.x + 30.0])


func _testar_quina(jogador: CharacterBody2D, trecho: Rect2) -> void:
	"""Cair na quina de um trecho nao pode prender o heroi: o colisor em capsula
	pousava no canto 3px abaixo do topo e ficava parado contra ele com a direcao
	apertada (PENDENCIAS.md, "Sem assistencia de degrau", Trecho3 x=1225)."""
	# Salto de 66px antes da quina e o que o teste de fumaca pegou: o heroi
	# pousava a 3px do topo e ficava parado. Os vizinhos cobrem a mesma quina
	# por cima e por baixo.
	for recuo in range(56, 70, 2):
		jogador.set_physics_process(true)
		jogador.global_position = Vector2(trecho.position.x - recuo, trecho.position.y - 75.0)
		jogador.velocity = Vector2(270.0, 150.0)
		Input.action_press("andar_direita")
		for frame in 60:
			await get_tree().physics_frame
		Input.action_release("andar_direita")
		var caiu_no_vao := jogador.global_position.y > Y_DE_QUEDA
		if not caiu_no_vao and jogador.global_position.x < trecho.position.x + 40.0:
			_falhas.append("quina x=%.0f, salto %.0fpx antes: heroi preso em (%.0f, %.0f)" % [trecho.position.x, recuo, jogador.global_position.x, jogador.global_position.y])


func _pular_na_borda(jogador: CharacterBody2D) -> void:
	"""Segura o pulo cheio quando o chao acaba logo a frente."""
	if _segurando > 0:
		_segurando -= 1
		if _segurando == 0:
			Input.action_release("pular")
		return
	if jogador.is_on_floor() and is_inf(_topo_em(jogador, jogador.global_position.x + 10.0)):
		Input.action_press("pular")
		_segurando = FRAMES_SEGURANDO_O_PULO


func _topo_em(jogador: CharacterBody2D, x: float) -> float:
	"""Y da superficie mais alta em x abaixo de y=200, ou INF se for buraco."""
	var consulta := PhysicsRayQueryParameters2D.create(Vector2(x, 200.0), Vector2(x, Y_DE_QUEDA), 1)
	consulta.exclude = [jogador.get_rid()]
	var acerto := jogador.get_world_2d().direct_space_state.intersect_ray(consulta)
	return INF if acerto.is_empty() else (acerto["position"] as Vector2).y
