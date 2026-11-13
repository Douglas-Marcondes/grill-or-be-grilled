extends Node2D

# Testes dos inimigos comuns: o arco do ovo da atiradeira acerta o alvo, o galo
# machuca no bote, a atiradeira recua de perto, golpe + queda no mesmo frame
# contam uma morte so, e todo marcador da fase declara um tipo que existe.
# Este no faz o papel da fase (os inimigos chamam spawn_egg/enemy_defeated).
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_dos_inimigos.tscn

const Bestiario = preload("res://scripts/bestiario.gd")
const Atiradeira = preload("res://galinha_atiradeira.gd")
const Galo = preload("res://galo.gd")
const PISO_Y := 400.0

var _falhas: PackedStringArray = []
var mortes := 0

func spawn_egg(_onde: Vector2) -> void:
	pass

func enemy_defeated() -> void:
	mortes += 1

func _ready() -> void:
	add_to_group("game")
	_criar_piso()
	_testar_arco_do_ovo()
	await _testar_bote_do_galo()
	await _testar_atiradeira_recua()
	await _testar_morte_conta_uma_vez()
	_testar_marcadores_da_fase()
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("INIMIGOS_OK 5 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_arco_do_ovo() -> void:
	"""Integra a trajetoria pelo tempo de voo e confere que passa pelo alvo."""
	for alvo in [Vector2(200, 0), Vector2(-120, 40), Vector2(60, -50)]:
		var v := Atiradeira.arco_ate(alvo, Vector2.ZERO)
		var voo := absf(alvo.x) / v.x * signf(alvo.x) if not is_zero_approx(v.x) else 0.0
		var chegada := Vector2(v.x * voo, v.y * voo + 0.5 * Atiradeira.GRAVIDADE_DO_OVO * voo * voo)
		_exigir("arco do ovo ate %s" % alvo, chegada.distance_to(alvo) < 1.0, "chegou em %s" % chegada)


func _testar_bote_do_galo() -> void:
	var alvo := await _alvo_em(Vector2(100, PISO_Y))
	var galo := _inimigo(Galo, "galo", Vector2.ZERO)
	await _esperar(90)
	_exigir("bote do galo machuca", alvo.dano == Galo.DANO_DO_BOTE, "dano=%d" % alvo.dano)
	galo.queue_free()
	alvo.queue_free()


func _testar_atiradeira_recua() -> void:
	var alvo := await _alvo_em(Vector2(50, PISO_Y))
	var atiradeira := _inimigo(Atiradeira, "atiradeira", Vector2.ZERO)
	await _esperar(30)
	_exigir("atiradeira recua de perto", atiradeira.global_position.x < -5.0, "x=%.0f" % atiradeira.global_position.x)
	atiradeira.queue_free()
	alvo.queue_free()


func _testar_morte_conta_uma_vez() -> void:
	var galinha := _inimigo(Bestiario.script_de("galinha"), "galinha", Vector2(-300, 0))
	await get_tree().physics_frame
	mortes = 0
	galinha.take_damage(99)
	galinha._morrer(galinha.global_position)
	_exigir("morte conta uma vez", mortes == 1, "contou %d" % mortes)


func _testar_marcadores_da_fase() -> void:
	var fase := preload("res://jogo.tscn").instantiate()
	for marcador in fase.get_node("EditorPreview/Personagens/Bots").get_children():
		var tipo := str(marcador.get_meta("tipo", Bestiario.PADRAO))
		_exigir("tipo do %s existe" % marcador.name, Bestiario.TIPOS.has(tipo), "tipo=%s" % tipo)
	fase.free()


func _inimigo(script: GDScript, tipo: String, onde: Vector2) -> CharacterBody2D:
	var inimigo := CharacterBody2D.new()
	inimigo.set_script(script)
	inimigo.folha_do_sprite = Bestiario.folha_de(tipo)
	inimigo.position = onde + Vector2(0, PISO_Y)
	add_child(inimigo)
	return inimigo


func _alvo_em(onde: Vector2) -> AlvoFalso:
	var alvo := AlvoFalso.new()
	alvo.position = onde
	add_child(alvo)
	await get_tree().physics_frame
	return alvo


func _esperar(frames: int) -> void:
	for frame in frames:
		await get_tree().physics_frame


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


## Heroi falso no grupo "player": registra o dano e fica parado no chao.
class AlvoFalso extends CharacterBody2D:
	var dano := 0

	func _ready() -> void:
		add_to_group("player")
		collision_layer = 0

	func take_damage(quanto: int, _origem: Vector2 = Vector2.INF) -> void:
		dano += quanto
