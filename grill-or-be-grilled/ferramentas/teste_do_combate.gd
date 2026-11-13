extends Node2D

# Testes da camada de combate: empurrao para longe de quem bateu, esquiva com
# invulnerabilidade e recarga, e hitstop que devolve o tempo do jogo.
# Este no faz o papel da fase (o heroi chama update_hud/player_died no pai).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_do_combate.tscn

const Jogador = preload("res://player.gd")
const Esquiva = preload("res://scripts/esquiva.gd")
const Impacto = preload("res://scripts/impacto.gd")

var _falhas: PackedStringArray = []
var mortes := 0

func update_hud() -> void:
	pass

func player_died() -> void:
	mortes += 1

func _ready() -> void:
	_criar_piso()
	await _testar_empurrao()
	await _testar_esquiva_protege()
	_testar_recarga_da_esquiva()
	await _testar_hitstop_devolve_o_tempo()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("COMBATE_OK 5 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_empurrao() -> void:
	var heroi := await _heroi()
	heroi.facing = 1.0
	heroi.take_damage(1, heroi.global_position + Vector2(20, 0))
	_exigir("golpe pela frente empurra para tras", heroi.velocity.x < 0.0, "vx=%.0f" % heroi.velocity.x)
	heroi.invulnerability = 0.0
	heroi.take_damage(1, heroi.global_position + Vector2(-20, 0))
	_exigir("golpe pelas costas empurra para a frente", heroi.velocity.x > 0.0, "vx=%.0f" % heroi.velocity.x)
	heroi.queue_free()
	await _esperar_o_tempo_voltar()


func _testar_esquiva_protege() -> void:
	var heroi := await _heroi()
	var vida: int = heroi.health
	heroi.esquiva.iniciar()
	heroi.take_damage(3, heroi.global_position + Vector2(10, 0))
	_exigir("esquiva ignora dano", heroi.health == vida, "vida %d -> %d" % [vida, heroi.health])
	heroi.queue_free()


func _testar_recarga_da_esquiva() -> void:
	var esquiva := Esquiva.new()
	esquiva.iniciar()
	_exigir("esquiva nao repete antes da recarga", not esquiva.iniciar(), "segunda esquiva saiu na hora")
	esquiva.atualizar(Esquiva.RECARGA + 0.01)
	_exigir("esquiva volta depois da recarga", esquiva.iniciar(), "nao recarregou em %.2fs" % Esquiva.RECARGA)


func _testar_hitstop_devolve_o_tempo() -> void:
	Impacto.golpe(get_tree(), Impacto.QUEDA_DO_CHEFE)
	await _esperar_o_tempo_voltar()
	_exigir("hitstop devolve time_scale=1", is_equal_approx(Engine.time_scale, 1.0), "time_scale=%.2f" % Engine.time_scale)


func _esperar_o_tempo_voltar() -> void:
	await get_tree().create_timer(0.5, true, false, true).timeout


func _heroi() -> CharacterBody2D:
	var heroi := CharacterBody2D.new()
	heroi.set_script(Jogador)
	heroi.position = Vector2(0, 399)
	heroi.configure("Guerreiro")
	add_child(heroi)
	await get_tree().physics_frame
	return heroi


func _criar_piso() -> void:
	var piso := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(800, 20)
	forma.shape = retangulo
	forma.position = Vector2(0, 410)
	piso.add_child(forma)
	add_child(piso)


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
