extends RefCounted

## Peso do golpe: congelamento curto do jogo (hitstop) e tremor da camera.
##
## Sem isso o acerto so trocava a cor do sprite e passava despercebido no meio
## da correria. O hitstop baixa Engine.time_scale e volta com um timer que
## ignora a escala de tempo -- senao o proprio timer congelaria junto.
##
## Exemplo:
##     Impacto.golpe(get_tree(), Impacto.ACERTO)

const ACERTO := {"pausa": 0.045, "tremor": 0.25}
const DANO_NO_HEROI := {"pausa": 0.09, "tremor": 0.55}
const PANCADA_DO_CHEFE := {"pausa": 0.0, "tremor": 0.6}
const QUEDA_DO_CHEFE := {"pausa": 0.3, "tremor": 1.0}

## Durante o hitstop o jogo nao para de vez: parado em 0 o Godot nao entrega
## physics_frame e qualquer coisa que espere um frame trava junto.
const ESCALA_CONGELADA := 0.05


static func golpe(arvore: SceneTree, perfil: Dictionary) -> void:
	"""Aplica pausa e tremor do perfil (ACERTO, DANO_NO_HEROI...)."""
	var camera := arvore.root.get_viewport().get_camera_2d()
	if camera and camera.has_method("tremer"):
		camera.tremer(perfil["tremor"])
	if perfil["pausa"] > 0.0:
		_congelar(arvore, perfil["pausa"])


static func _congelar(arvore: SceneTree, segundos: float) -> void:
	Engine.time_scale = ESCALA_CONGELADA
	await arvore.create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0
