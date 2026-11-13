extends RefCounted

## Peso do golpe: som, congelamento curto do jogo (hitstop) e tremor da camera.
##
## Sem isso o acerto so trocava a cor do sprite e passava despercebido no meio
## da correria. O hitstop baixa Engine.time_scale e volta com um timer que
## ignora a escala de tempo -- senao o proprio timer congelaria junto.
##
## Exemplo:
##     Impacto.golpe(get_tree(), Impacto.ACERTO)

const ACERTO := {"pausa": 0.045, "tremor": 0.25, "som": "acerto"}
const DANO_NO_HEROI := {"pausa": 0.09, "tremor": 0.55, "som": "dano"}
const PANCADA_DO_CHEFE := {"pausa": 0.0, "tremor": 0.6, "som": "pancada"}
const QUEDA_DO_CHEFE := {"pausa": 0.3, "tremor": 1.0, "som": "pancada"}

## Durante o hitstop o jogo nao para de vez: parado em 0 o Godot nao entrega
## physics_frame e qualquer coisa que espere um frame trava junto.
const ESCALA_CONGELADA := 0.05


static func golpe(arvore: SceneTree, perfil: Dictionary) -> void:
	"""Aplica som, pausa e tremor do perfil (ACERTO, DANO_NO_HEROI...)."""
	Som.tocar(perfil["som"])
	var camera := arvore.root.get_viewport().get_camera_2d()
	if camera and camera.has_method("tremer"):
		camera.tremer(perfil["tremor"])
	if perfil["pausa"] > 0.0:
		_congelar(arvore, perfil["pausa"])


static func _congelar(arvore: SceneTree, segundos: float) -> void:
	Engine.time_scale = ESCALA_CONGELADA
	await arvore.create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0
