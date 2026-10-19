extends Node2D

# Teste de fumaca: atravessa a fase 1 com o jogador vivo para que IA das
# galinhas, boss, ovos e tochas executem de verdade, e falha se o Godot
# registrar erro de script ou se o heroi morrer no caminho.
#
# Dirige o heroi pelas ACOES do input map, nao por velocity direta: e assim que
# o jogador joga, e e o unico jeito de o teste cobrir aceleracao, atrito,
# coyote time e buffer de pulo. O pulo sai por raycast de borda e nao por
# temporizador, senao o teste cai nas lacunas por azar de fase e nao por
# regressao de verdade.

const ACOES := ["andar_esquerda", "andar_direita", "pular", "atacar"]
const PASSOS := 600
## Sonda o chao a 30, 60 e 90px: so a borda nao basta porque as pedras
## RotaAlta7/8/11/13 pendem sobre a saida do trecho anterior, e la o pulo tem de
## sair ANTES da pedra, senao o heroi bate a cabeca nela.
const DISTANCIAS_DE_SONDAGEM := [30.0, 60.0, 90.0]
const ALTURA_DA_SONDA := 110.0
const ALCANCE_DA_SONDA := 190.0
## Desnivel para cima que ja exige pulo, e distancia maxima para pular por causa
## de buraco (buraco longe ainda nao e problema; degrau longe ja e).
const DESNIVEL_QUE_EXIGE_PULO := 4.0
const DISTANCIA_DE_BURACO := 60.0
## Quanto o autopilot leva a fase em 10s. Nao e a fase inteira de proposito: o
## piloto automatico pula sempre com forca total e passa por cima das pedras
## RotaAlta, e varias passagens da fase exigem precisao que ele nao tem (ver
## PENDENCIAS.md, "Passagens travadas"). O que este teste garante e o contrato
## da camada de controle: as acoes existem, movem o heroi de verdade e ele
## atravessa a fazenda vivo.
const AVANCO_MINIMO := 1500.0
## Frames segurando o pulo. Precisa passar dos 0.43s de subida do arco cheio,
## senao o corte de altura variavel encurta o salto e o teste cai nas lacunas
## culpando a fase pelo que e so o driver soltando o botao cedo.
const FRAMES_SEGURANDO_O_PULO := 28

var _segurando_o_pulo := 0

func _ready() -> void:
	for acao in ACOES:
		assert(InputMap.has_action(acao), "Falta a acao '%s' no input map (project.godot [input])" % acao)
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Arqueiro")
	await get_tree().process_frame
	var jogador: CharacterBody2D = game.player
	var partiu_de := jogador.global_position.x
	for passo in PASSOS:
		_dirigir(jogador, passo)
		await get_tree().physics_frame
		if game.screen != "playing":
			break
	for acao in ACOES:
		Input.action_release(acao)
	var avancou := jogador.global_position.x - partiu_de
	assert(game.screen == "playing", "O heroi nao sobreviveu a travessia: tela=%s em x=%.0f" % [game.screen, jogador.global_position.x])
	assert(avancou >= AVANCO_MINIMO, "O heroi avancou so %.0fpx; esperado ao menos %.0fpx" % [avancou, AVANCO_MINIMO])
	print("SMOKE_OK avancou=%.0fpx galinhas_restantes=%d" % [avancou, get_tree().get_nodes_in_group("enemies").size()])
	get_tree().quit()

func _dirigir(jogador: CharacterBody2D, passo: int) -> void:
	"""Anda sempre para a direita, pula ao ver a borda e ataca a cada 0.67s."""
	Input.action_press("andar_direita")
	_segurar_pulo(jogador)
	if passo % 40 == 0:
		Input.action_press("atacar")
	elif passo % 40 == 4:
		Input.action_release("atacar")

func _segurar_pulo(jogador: CharacterBody2D) -> void:
	if _segurando_o_pulo > 0:
		_segurando_o_pulo -= 1
		if _segurando_o_pulo == 0:
			Input.action_release("pular")
		return
	if jogador.is_on_floor() and _precisa_pular(jogador):
		Input.action_press("pular")
		_segurando_o_pulo = FRAMES_SEGURANDO_O_PULO


func _precisa_pular(jogador: CharacterBody2D) -> bool:
	"""Pula por degrau assim que ele aparece na sonda mais distante, e por buraco
	so quando ele chega perto."""
	for distancia in DISTANCIAS_DE_SONDAGEM:
		var superficie := _superficie_a_frente(jogador, distancia)
		if is_inf(superficie):
			return distancia <= DISTANCIA_DE_BURACO
		if jogador.global_position.y - superficie > DESNIVEL_QUE_EXIGE_PULO:
			return true
	return false


func _superficie_a_frente(jogador: CharacterBody2D, distancia: float) -> float:
	"""Y do chao a `distancia` a frente, ou INF se nao houver chao ali. A sonda
	comeca acima da cabeca para tambem achar superficie mais ALTA que o pe."""
	var inicio := jogador.global_position + Vector2(distancia, -ALTURA_DA_SONDA)
	var consulta := PhysicsRayQueryParameters2D.create(inicio, inicio + Vector2(0.0, ALCANCE_DA_SONDA), 1)
	consulta.exclude = [jogador.get_rid()]
	var acerto := jogador.get_world_2d().direct_space_state.intersect_ray(consulta)
	return INF if acerto.is_empty() else (acerto["position"] as Vector2).y
