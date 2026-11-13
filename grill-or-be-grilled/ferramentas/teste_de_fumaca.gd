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
## Sonda o chao a 30, 60 e 90px: degrau alto tem de ser visto de longe, senao o
## pulo sai tarde e o heroi bate de frente nele.
const DISTANCIAS_DE_SONDAGEM := [30.0, 60.0, 90.0]
const ALTURA_DA_SONDA := 110.0
const ALCANCE_DA_SONDA := 190.0
## Desnivel para cima que ja exige pulo, e distancia maxima para pular por causa
## de buraco (buraco longe ainda nao e problema; degrau longe ja e).
const DESNIVEL_QUE_EXIGE_PULO := 4.0
const DISTANCIA_DE_BURACO := 60.0
## Quanto o autopilot leva a fase em 10s. Nao e a fase inteira: cada vao e
## coberto por teste_das_passagens. O que este teste garante e o contrato da
## camada de controle com a fase de verdade: as acoes existem, movem o heroi no
## meio das galinhas e ele atravessa a fazenda vivo.
const AVANCO_MINIMO := 1500.0
## Frames segurando o pulo. Precisa passar dos 0.43s de subida do arco cheio,
## senao o corte de altura variavel encurta o salto e o teste cai nas lacunas
## culpando a fase pelo que e so o driver soltando o botao cedo.
const FRAMES_SEGURANDO_O_PULO := 28
const FRAMES_NA_ARENA := 480

var _segurando_o_pulo := 0

func _ready() -> void:
	for acao in ACOES:
		if not InputMap.has_action(acao):
			printerr("FALHOU: falta a acao '%s' no input map (project.godot [input])" % acao)
			get_tree().quit(1)
			return
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
		if OS.has_environment("RASTRO") and passo % 20 == 0:
			print("passo=%d x=%.0f y=%.0f vida=%d vx=%.0f chao=%s esq=%s kb=%.2f ts=%.2f" % [passo, jogador.global_position.x, jogador.global_position.y, jogador.health, jogador.velocity.x, jogador.is_on_floor(), jogador.esquiva.ativa(), jogador.knockback, Engine.time_scale])
		if game.screen != "playing":
			break
	for acao in ACOES:
		Input.action_release(acao)
	var avancou := jogador.global_position.x - partiu_de
	# Falha com quit(1) e nao com assert: assert em --headless pausa o Godot no
	# depurador e o teste fica pendurado ate o timeout em vez de falhar.
	var falha := ""
	if game.screen != "playing":
		falha = "O heroi nao sobreviveu a travessia: tela=%s em x=%.0f" % [game.screen, jogador.global_position.x]
	elif avancou < AVANCO_MINIMO:
		falha = "O heroi avancou so %.0fpx; esperado ao menos %.0fpx" % [avancou, AVANCO_MINIMO]
	if not falha.is_empty():
		printerr("FALHOU: %s" % falha)
		get_tree().quit(1)
		return
	var vidas_antes: int = game.vidas
	var dano_no_chefe := await _lutar_na_arena(game)
	if game.vidas < vidas_antes:
		# Com 999 de vida so a queda mata: a arena tinha uma fresta no fim do
		# mundo e a Galinha Real caia por ela, travando a luta.
		falha = "o heroi caiu para fora da arena"
	elif dano_no_chefe <= 0:
		falha = "a luta na arena nao feriu a Galinha Real"
	if not falha.is_empty():
		printerr("FALHOU: %s" % falha)
		get_tree().quit(1)
		return
	print("SMOKE_OK avancou=%.0fpx galinhas_restantes=%d dano_no_chefe=%d" % [avancou, get_tree().get_nodes_in_group("enemies").size(), dano_no_chefe])
	get_tree().quit()


func _lutar_na_arena(game: Node) -> int:
	"""Leva o heroi ate a Galinha Real e luta 8s com ataque, pulo e esquiva, para
	que os tres golpes do chefe e as duas fases rodem com a fase de verdade.
	Devolve quanto de vida o chefe perdeu."""
	var jogador: CharacterBody2D = game.player
	var chefe: CharacterBody2D = game.boss
	jogador.global_position = chefe.global_position + Vector2(-160, -20)
	jogador.health = 999
	for passo in FRAMES_NA_ARENA:
		if not is_instance_valid(chefe) or game.screen != "playing":
			break
		var lado := "andar_direita" if chefe.global_position.x > jogador.global_position.x + 20.0 else "andar_esquerda"
		Input.action_press(lado)
		_alternar("atacar", passo, 12)
		_alternar("pular", passo, 70)
		_alternar("esquivar", passo, 95)
		await get_tree().physics_frame
		if OS.has_environment("RASTRO") and passo % 15 == 0:
			print("arena passo=%d heroi=(%.0f,%.0f) chefe=(%.0f,%.0f) vidas=%d" % [passo, jogador.global_position.x, jogador.global_position.y, chefe.global_position.x, chefe.global_position.y, game.vidas])
		Input.action_release(lado)
	for acao in ACOES + ["esquivar"]:
		Input.action_release(acao)
	if OS.has_environment("RASTRO"):
		print("arena: chefe_valido=%s vidas=%d tela=%s" % [is_instance_valid(chefe), game.vidas, game.screen])
	return 24 if not is_instance_valid(chefe) else chefe.max_health - chefe.health


func _alternar(acao: String, passo: int, periodo: int) -> void:
	if passo % periodo == 0:
		Input.action_press(acao)
	elif passo % periodo == 3:
		Input.action_release(acao)

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
