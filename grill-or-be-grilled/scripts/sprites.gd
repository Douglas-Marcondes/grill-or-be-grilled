extends RefCounted

## Monta os Sprite2D dos personagens a partir das folhas em Artes/gerado/.
##
## Convencao de ancoragem: a origem do personagem e o PE dele. Todo o codigo de
## fisica e de ataque ja trabalha assim (posicoes negativas sobem a partir do
## chao), entao o sprite e deslocado para que a base da celula caia na origem --
## assim trocar o desenho nao desloca colisao nem alcance de golpe.
##
## Exemplo:
##     var sprite := Sprites.montar(self, Sprites.GALINHA, 4)
##     sprite.frame = 2

const PASTA := "res://Artes/gerado/%s.png"

const GALINHA := "galinha"
const GALINHA_REAL := "galinha_real"
const OVOS := "ovos"

## Clarao branco de dano: multiplicar acima de 1 satura o sprite inteiro.
const CLARAO := Color(4.0, 4.0, 4.0)


static func caminho(nome: String) -> String:
	return PASTA % nome


static func anexar(dono: Node2D, nome: String, quadros: int,
		deslocamento: Vector2) -> Sprite2D:
	"""Cria o Sprite2D filho com o deslocamento pedido. Null se faltar arte."""
	if quadros < 1:
		push_error("anexar exige ao menos 1 quadro; recebi %d para %s" % [quadros, nome])
		return null
	var textura := load(caminho(nome)) as Texture2D
	if not textura:
		push_error("folha de sprite ausente: %s" % caminho(nome))
		return null
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.hframes = quadros
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = deslocamento
	dono.add_child(sprite)
	return sprite


static func celula(nome: String, quadros: int) -> Vector2:
	"""Tamanho de um quadro da folha, em pixels."""
	var textura := load(caminho(nome)) as Texture2D
	if not textura:
		return Vector2.ZERO
	return Vector2(float(textura.get_width()) / quadros, float(textura.get_height()))


static func montar(dono: Node2D, nome: String, quadros: int) -> Sprite2D:
	"""Cria o Sprite2D filho ja ancorado pelo pe. Devolve null se faltar arte."""
	var tamanho := celula(nome, quadros)
	return anexar(dono, nome, quadros,
			Vector2(-roundf(tamanho.x / 2.0), -tamanho.y))


static func montar_centrado(dono: Node2D, nome: String, quadros: int) -> Sprite2D:
	"""Cria o Sprite2D filho ancorado pelo CENTRO.

	Usado por aquilo que e posicionado por um ponto do corpo em vez do chao --
	uma arma e colocada pela altura da mao, e ancora-la pelo pe faz sprites de
	alturas diferentes (espada, arco, varinha) pararem cada um numa altura.
	"""
	var tamanho := celula(nome, quadros)
	return anexar(dono, nome, quadros,
			Vector2(-roundf(tamanho.x / 2.0), -roundf(tamanho.y / 2.0)))


static func quadro_do_passo(tempo: float, quadros: int) -> int:
	"""Indice ciclico do quadro de caminhada para um tempo de animacao."""
	return int(tempo) % quadros


static func virar(sprite: Sprite2D, direcao: float) -> void:
	if sprite and not is_zero_approx(direcao):
		sprite.flip_h = direcao < 0.0


static func piscar(sprite: Sprite2D, clarao: float, base: Color = Color.WHITE) -> void:
	"""Aplica o clarao de dano enquanto o temporizador estiver correndo; fora
	dele volta para `base`, o tom proprio do personagem (a Galinha Real
	enfurecida, por exemplo, fica avermelhada)."""
	if sprite:
		sprite.modulate = CLARAO if clarao > 0.0 else base
