extends CanvasModulate

## Escuridao ambiente da fase, mais fechada a cada regiao que se desce.
##
## Antes tudo era desenhado em brilho cheio: a tocha "acesa" nao iluminava nada
## e o porao tinha a mesma luz da fazenda ao luar. Com o CanvasModulate o mundo
## escurece e cada PointLight2D (tochas, braseiros, heroi) abre uma poca de luz
## -- e o que da atmosfera de masmorra. A interface fica num CanvasLayer proprio
## e nao e afetada.
##
## Segue a camera ativa, e nao o heroi, para valer tambem no menu e nas
## ferramentas de captura.
##
## Exemplo:
##     add_child(Iluminacao.new())
##     heroi.add_child(Iluminacao.luz(Iluminacao.COR_DO_HEROI, 0.55, 1.4))

const Terreno = preload("res://scripts/terreno.gd")

const AMBIENTE := {
	"fazenda": Color(0.66, 0.62, 0.82),
	"entrada": Color(0.46, 0.40, 0.52),
	"porao": Color(0.34, 0.32, 0.44),
}
const COR_DO_HEROI := Color(1.0, 0.92, 0.80)
const COR_DO_FOGO := Color(1.0, 0.62, 0.30)
## Quanto maior, mais rapido a luz muda ao cruzar a fronteira de regiao.
const RAPIDEZ_DA_TRANSICAO := 1.5
const LADO_DA_TEXTURA := 128

static var _textura: GradientTexture2D


func _ready() -> void:
	color = AMBIENTE["fazenda"]


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var alvo: Color = AMBIENTE[Terreno.regiao_em(camera.get_screen_center_position().x)]
	color = color.lerp(alvo, 1.0 - exp(-delta * RAPIDEZ_DA_TRANSICAO))


static func luz(cor: Color, energia: float, escala: float) -> PointLight2D:
	"""PointLight2D circular e suave, pronta para pendurar num no."""
	var ponto := PointLight2D.new()
	ponto.name = "Luz"
	ponto.texture = _textura_de_luz()
	ponto.color = cor
	ponto.energy = energia
	ponto.texture_scale = escala
	return ponto


static func _textura_de_luz() -> GradientTexture2D:
	# Uma textura para todas as luzes: sao dezenas de tochas na fase.
	if _textura:
		return _textura
	var degrade := Gradient.new()
	degrade.set_color(0, Color.WHITE)
	degrade.set_color(1, Color(1, 1, 1, 0))
	degrade.add_point(0.45, Color(1, 1, 1, 0.45))
	_textura = GradientTexture2D.new()
	_textura.gradient = degrade
	_textura.fill = GradientTexture2D.FILL_RADIAL
	_textura.fill_from = Vector2(0.5, 0.5)
	_textura.fill_to = Vector2(1.0, 0.5)
	_textura.width = LADO_DA_TEXTURA
	_textura.height = LADO_DA_TEXTURA
	return _textura
