extends Node2D

# Testes das poses do heroi (parado, golpeando, subindo, caindo e esquivando
# escolhem o quadro certo da folha), da coreografia da arma, do bote das
# galinhas e do visual dos projeteis (sprite por tipo, girando
# com a trajetoria; magia com luz propria).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_da_animacao.tscn

const GolpeDaArma = preload("res://scripts/golpe_da_arma.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Arqueiro")
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		inimigo.queue_free()
	await _esperar(20)
	var heroi: CharacterBody2D = game.player
	_exigir("folha com as poses", heroi.sprite.hframes == heroi.QUADROS_DO_HEROI, "hframes=%d" % heroi.sprite.hframes)
	_exigir("parado no chao usa o quadro 0", heroi._quadro_atual() == 0, "quadro=%d" % heroi._quadro_atual())
	_testar_golpe(game, heroi)
	heroi.global_position.y -= 120.0
	heroi.velocity = Vector2(0, -200)
	await get_tree().physics_frame
	var subindo: int = heroi._quadro_atual()
	heroi.velocity = Vector2(0, 200)
	await get_tree().physics_frame
	var caindo: int = heroi._quadro_atual()
	_exigir("subindo e caindo", subindo == heroi.QUADRO_DE_PULO and caindo == heroi.QUADRO_DE_QUEDA,
		"subindo=%d caindo=%d" % [subindo, caindo])
	heroi.esquiva.iniciar()
	_exigir("esquiva vence o ar", heroi._quadro_atual() == heroi.QUADRO_DE_ESQUIVA, "quadro=%d" % heroi._quadro_atual())
	_testar_projeteis()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("ANIMACAO_OK 11 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_golpe(game: Node, heroi: CharacterBody2D) -> void:
	heroi.attack()
	_exigir("golpe usa o quadro de golpe", heroi._quadro_atual() == heroi.QUADRO_DE_GOLPE, "quadro=%d" % heroi._quadro_atual())
	heroi.attack_timer = 0.0
	heroi.knockback = 0.2
	_exigir("tranco do dano usa o quadro de dano", heroi._quadro_atual() == heroi.QUADRO_DE_DANO, "quadro=%d" % heroi._quadro_atual())
	heroi.knockback = 0.0
	_exigir("espada sobe atras do ombro, desce a frente e repousa",
		GolpeDaArma.giro("Espada", 0.0) < -1.5 and GolpeDaArma.giro("Espada", GolpeDaArma.IDA) > 0.5
			and is_zero_approx(GolpeDaArma.giro("Espada", 1.0)),
		"giro=%s/%s/%s" % [GolpeDaArma.giro("Espada", 0.0), GolpeDaArma.giro("Espada", GolpeDaArma.IDA), GolpeDaArma.giro("Espada", 1.0)])
	_exigir("arco coiceia e nao gira",
		GolpeDaArma.avanco("Arco", 0.0) < 0.0 and is_zero_approx(GolpeDaArma.giro("Arco", 0.2)),
		"avanco=%s" % GolpeDaArma.avanco("Arco", 0.0))
	game.slash_effect(heroi.global_position, -1.0, false)
	var rastro: Node2D = game.get_child(game.get_child_count() - 1)
	_exigir("corte e sprite de 4 quadros virado para o golpe",
		rastro._corte != null and rastro._corte.hframes == 4 and rastro._corte.flip_h,
		"corte=%s" % rastro._corte)
	var galinha := CharacterBody2D.new()
	galinha.set_script(preload("res://chicken_enemy.gd"))
	add_child(galinha)
	galinha.attack_windup = 0.3
	galinha._animar()
	_exigir("galinha preparando o ataque mostra o bote",
		galinha.sprite.hframes == galinha.QUADROS and galinha.sprite.frame == galinha.QUADRO_DE_BOTE,
		"frame=%d" % galinha.sprite.frame)
	galinha.queue_free()


func _testar_projeteis() -> void:
	var magia := _projetil("magia", Vector2.RIGHT)
	_exigir("magia com sprite e luz",
		magia._sprite != null and magia._sprite.frame == 1 and not magia.find_children("*", "PointLight2D", false, false).is_empty(),
		"sprite=%s" % magia._sprite)
	var ovo := _projetil("ovo", Vector2.DOWN)
	_exigir("ovo aponta para onde cai", is_equal_approx(ovo._sprite.rotation, PI / 2.0),
		"rotacao=%s" % ovo._sprite.rotation)
	magia.queue_free()
	ovo.queue_free()


func _projetil(tipo: String, direcao: Vector2) -> Area2D:
	var tiro := Area2D.new()
	tiro.set_script(preload("res://projectile.gd"))
	tiro.tipo = tipo
	tiro.direction = direcao
	add_child(tiro)
	return tiro


func _esperar(frames: int) -> void:
	for frame in frames:
		await get_tree().physics_frame


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
