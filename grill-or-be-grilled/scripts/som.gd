extends Node

## Autoload "Som": toca efeitos e a musica gerados por tools/gerar_sons.py.
##
## Um punhado de AudioStreamPlayer em rodizio deixa varios efeitos soarem juntos
## (golpe + acerto + cacarejo no mesmo frame) sem um cortar o outro. Cada efeito
## sai com um tom levemente sorteado: o mesmo "piu" repetido 30 vezes por fase
## cansa o ouvido, e a variacao e o truque classico para disfarcar.
##
## Exemplo:
##     Som.tocar("pulo")
##     Som.tocar_musica("musica_fase1")

const PASTA := "res://Artes/sons/%s.wav"
const CANAIS := 8
const VARIACAO_DE_TOM := 0.08
const VOLUME_DA_MUSICA_DB := -8.0

var _canais: Array[AudioStreamPlayer] = []
var _proximo := 0
var _musica: AudioStreamPlayer
var _cache := {}
## Sem tela (testes headless) ninguem ouve: o som e carregado -- arquivo
## faltando ainda da erro -- mas nao toca. Tocando, o quit() imediato dos
## testes deixava o playback preso no AudioServer ("resources still in use").
var _mudo := DisplayServer.get_name() == "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in CANAIS:
		var canal := AudioStreamPlayer.new()
		add_child(canal)
		_canais.append(canal)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = VOLUME_DA_MUSICA_DB
	add_child(_musica)


func tocar(nome: String) -> void:
	"""Toca um efeito de Artes/sons/ no proximo canal livre do rodizio."""
	var stream := _carregar(nome)
	if not stream or _mudo:
		return
	var canal := _canais[_proximo]
	_proximo = (_proximo + 1) % CANAIS
	canal.stream = stream
	canal.pitch_scale = 1.0 + randf_range(-VARIACAO_DE_TOM, VARIACAO_DE_TOM)
	canal.play()


func tocar_musica(nome: String) -> void:
	"""Toca a musica em loop; nao reinicia se ela ja estiver tocando."""
	var stream := _carregar(nome) as AudioStreamWAV
	if not stream or _mudo or (_musica.playing and _musica.stream == stream):
		return
	# Loop definido aqui e nao no .import: fica versionado junto do codigo e
	# sobrevive a regerar os WAVs.
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_musica.stream = stream
	_musica.play()


func parar_musica() -> void:
	_musica.stop()


func _carregar(nome: String) -> AudioStream:
	if not _cache.has(nome):
		var stream := load(PASTA % nome) as AudioStream
		if not stream:
			push_error("som ausente: %s (rode python3 tools/gerar_sons.py)" % (PASTA % nome))
		_cache[nome] = stream
	return _cache[nome]


func _exit_tree() -> void:
	# Solta os streams ao fechar o jogo: segurados no cache e nos canais, o
	# Godot acusava "resources still in use at exit".
	for canal in _canais + [_musica]:
		canal.stop()
		canal.stream = null
	_cache.clear()
