extends Area2D

## Braseiro de checkpoint: apagado ate o heroi passar, depois aceso para sempre.
##
## Acender cura o heroi e marca o ponto de volta: com 3 vidas, cair ou apanhar
## devolve o jogador ao ultimo braseiro em vez do comeco dos 10000px da fase.
## Reaproveita a tocha do cenario (scripts/tochas.gd) fincada no chao: apagado
## mostra so o castical, aceso ganha chama e halo.
##
## Exemplo: um no em EditorPreview/Personagens/Braseiros no jogo.tscn vira um
## braseiro na posicao do marcador (o pe do castical).

const Tochas = preload("res://scripts/tochas.gd")

## Altura do castical da tocha: ancorado pelo topo, sobe isso para pisar no chao.
const ALTURA_DO_CASTICAL := 10.0

var aceso := false
var tocha: Node2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(24, 60)
	forma.shape = retangulo
	forma.position.y = -30
	add_child(forma)
	tocha = Tochas.Tocha.new()
	tocha.position.y = -ALTURA_DO_CASTICAL
	add_child(tocha)
	_mostrar_chama(false)
	body_entered.connect(_on_body_entered)


func _mostrar_chama(visivel: bool) -> void:
	for parte in [tocha.chama, tocha.halo]:
		if parte:
			parte.visible = visivel


func _on_body_entered(body: Node2D) -> void:
	if aceso or not body.is_in_group("player"):
		return
	aceso = true
	_mostrar_chama(true)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.checkpoint_reached(global_position)
