extends Node2D

# Teste de fumaca: roda a fase por alguns segundos com o jogador vivo para que
# IA das galinhas, boss, ovos e tochas executem de verdade, e falha se o Godot
# registrar qualquer erro de script.
func _ready() -> void:
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Arqueiro")
	await get_tree().process_frame
	var jogador = game.player
	for passo in 420:
		if is_instance_valid(jogador):
			jogador.velocity.x = 180.0
			if passo % 40 == 0:
				jogador.attack()
		await get_tree().physics_frame
	print("SMOKE_OK galinhas_restantes=%d" % get_tree().get_nodes_in_group("enemies").size())
	get_tree().quit()
