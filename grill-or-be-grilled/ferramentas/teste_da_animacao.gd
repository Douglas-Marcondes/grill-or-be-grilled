extends Node2D

# Testes das poses do heroi (parado, subindo, caindo e esquivando escolhem o
# quadro certo da folha) e do visual dos projeteis (sprite por tipo, girando
# com a trajetoria; magia com luz propria).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_da_animacao.tscn

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
		print("ANIMACAO_OK 6 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


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
