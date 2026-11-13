extends Node2D

# Ferramenta de desenvolvimento: abre o jogo, posiciona a camera em pontos
# marcantes da fase e grava PNGs para comparar o visual antes/depois.
const PONTOS := {
	"fazenda": Vector2(300, 430),
	"penhasco": Vector2(2900, 400),
	"entrada": Vector2(4600, 400),
	"porao": Vector2(7600, 400),
	"ninho": Vector2(9650, 420),
}

func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	for f in 4:
		await RenderingServer.frame_post_draw
	_gravar("menu")
	GameData.viu_prologo = true
	game.show_class_select()
	for f in 4:
		await RenderingServer.frame_post_draw
	_gravar("escolha_de_heroi")
	game.choose_class("Guerreiro")
	await get_tree().process_frame
	# Herói parado diante do primeiro braseiro, com a placa da região na tela.
	game.player.global_position = Vector2(2402, 428)
	game.player.camera.reset_smoothing()
	for f in 90:
		await RenderingServer.frame_post_draw
	_gravar("braseiro_e_aviso")
	var cam := Camera2D.new()
	add_child(cam)
	for nome in PONTOS:
		cam.global_position = PONTOS[nome]
		cam.make_current()
		for f in 6:
			await RenderingServer.frame_post_draw
		_gravar(nome)
	get_tree().quit()

func _gravar(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://ferramentas/capturas")
	get_viewport().get_texture().get_image().save_png("res://ferramentas/capturas/%s.png" % nome)
