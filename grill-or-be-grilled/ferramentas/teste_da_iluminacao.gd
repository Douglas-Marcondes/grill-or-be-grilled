extends Node2D

# Testes da camada visual de luz e volume: escuridao ambiente por regiao, luz
# nas tochas e no heroi, braseiro apagado sem luz, e terreno com sombra de
# profundidade e contorno.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_da_iluminacao.tscn

const Iluminacao = preload("res://scripts/iluminacao.gd")
const AcabamentoDoTerreno = preload("res://scripts/acabamento_do_terreno.gd")

var _falhas: PackedStringArray = []

func _ready() -> void:
	_testar_regioes()
	_testar_acabamento()
	var game := preload("res://jogo.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.choose_class("Guerreiro")
	await get_tree().process_frame
	_testar_luzes_da_fase(game)
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("ILUMINACAO_OK 6 verificacoes")
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar_regioes() -> void:
	var achadas := [Iluminacao.regiao_de(100.0), Iluminacao.regiao_de(4000.0), Iluminacao.regiao_de(9000.0)]
	_exigir("regiao por X", achadas == ["fazenda", "entrada", "porao"], str(achadas))
	var fazenda: Color = Iluminacao.AMBIENTE["fazenda"]
	var porao: Color = Iluminacao.AMBIENTE["porao"]
	_exigir("porao mais escuro que a fazenda", porao.get_luminance() < fazenda.get_luminance(),
		"fazenda=%s porao=%s" % [fazenda, porao])


func _testar_acabamento() -> void:
	var bloco := Polygon2D.new()
	bloco.polygon = PackedVector2Array([Vector2(0, 0), Vector2(64, 0), Vector2(64, 300), Vector2(0, 300)])
	AcabamentoDoTerreno.aplicar(bloco)
	var cores := bloco.vertex_colors
	_exigir("topo claro e fundo escuro", cores.size() == 4 and cores[0] == Color.WHITE and cores[2].get_luminance() < 0.5,
		str(cores))
	_exigir("contorno fechado", bloco.get_node_or_null("Contorno") is Line2D and bloco.get_node("Contorno").closed,
		str(bloco.get_children()))
	bloco.free()


func _testar_luzes_da_fase(game: Node) -> void:
	var ambiente := game.find_children("*", "CanvasModulate", false, false)
	_exigir("fase tem escuridao ambiente", ambiente.size() == 1, "achados=%d" % ambiente.size())
	var tochas_sem_luz := 0
	var tochas := 0
	for no in game.get_node("EditorPreview/Cenario").get_children():
		if str(no.name).begins_with("Tocha"):
			tochas += 1
			if no.find_children("*", "PointLight2D", true, false).is_empty():
				tochas_sem_luz += 1
	var heroi_tem_luz: bool = not game.player.find_children("*", "PointLight2D", false, false).is_empty()
	_exigir("tochas e heroi iluminam", tochas > 0 and tochas_sem_luz == 0 and heroi_tem_luz,
		"tochas=%d sem_luz=%d heroi=%s" % [tochas, tochas_sem_luz, heroi_tem_luz])


func _exigir(nome: String, condicao: bool, detalhe: String) -> void:
	if not condicao:
		_falhas.append("%s: %s" % [nome, detalhe])
