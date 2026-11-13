extends Area2D

## Braseiro de checkpoint: apagado ate o heroi passar, depois aceso para sempre.
##
## Acender cura o heroi e marca o ponto de volta: com 3 vidas, cair ou apanhar
## devolve o jogador ao ultimo braseiro em vez do comeco dos 10000px da fase.
## Fogueira propria (tigela de pedra com lenha, Artes/gerado/braseiro.png): o
## castical de tocha de 7x10px que vinha antes sumia no cenario e o jogador
## passava pelo checkpoint sem ver. Acesa, a lenha vira brasa e a chama da
## tocha (scripts/tochas.gd) aparece em dobro sobre ela, com halo e luz.
##
## Exemplo: um no em EditorPreview/Personagens/Braseiros no jogo.tscn vira um
## braseiro na posicao do marcador (o pe do castical).

const Tochas = preload("res://scripts/tochas.gd")

const Sprites = preload("res://scripts/sprites.gd")

## Quadros de braseiro.png e altura da lenha acima do pe, onde a chama pousa.
const QUADRO_APAGADO := 0
const QUADRO_ACESO := 1
const ALTURA_DA_LENHA := 7.0
## Chama da fogueira e o dobro da de tocha: escala inteira mantem o pixel.
const ESCALA_DA_CHAMA := Vector2(2, 2)

var aceso := false
var tocha: Node2D
var fogueira: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(24, 60)
	forma.shape = retangulo
	forma.position.y = -30
	add_child(forma)
	fogueira = Sprites.montar(self, "braseiro", 2)
	tocha = Tochas.Tocha.new()
	tocha.position.y = -ALTURA_DA_LENHA
	add_child(tocha)
	tocha.suporte.hide()
	tocha.chama.scale = ESCALA_DA_CHAMA
	_mostrar_chama(false)
	body_entered.connect(_on_body_entered)


func _mostrar_chama(visivel: bool) -> void:
	for parte in [tocha.chama, tocha.halo, tocha.luz]:
		if parte:
			parte.visible = visivel
	if fogueira:
		fogueira.frame = QUADRO_ACESO if visivel else QUADRO_APAGADO


func _on_body_entered(body: Node2D) -> void:
	if aceso or not body.is_in_group("player"):
		return
	aceso = true
	Som.tocar("braseiro")
	_mostrar_chama(true)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.checkpoint_reached(global_position)
