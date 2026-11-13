extends Node

# Teste dos sons: todo nome tocado no codigo (Som.tocar, Som.tocar_musica e o
# "som" dos perfis de Impacto) tem WAV importado em Artes/sons/. Nome errado
# so dava erro no meio do jogo, na hora do golpe.
#
#   ./Godot_v4.7.2-stable_linux.x86_64 --headless --path grill-or-be-grilled \
#       res://ferramentas/teste_dos_sons.tscn

const Impacto = preload("res://scripts/impacto.gd")
const Som = preload("res://scripts/som.gd")
const PASTAS := ["res://", "res://scripts/"]

var _falhas: PackedStringArray = []

func _ready() -> void:
	var nomes := _nomes_no_codigo()
	for perfil in [Impacto.ACERTO, Impacto.DANO_NO_HEROI, Impacto.PANCADA_DO_CHEFE, Impacto.QUEDA_DO_CHEFE]:
		nomes[perfil["som"]] = true
	if nomes.size() < 10:
		_falhas.append("achei so %d nomes de som no codigo; a busca quebrou?" % nomes.size())
	for nome in nomes:
		if not ResourceLoader.exists(Som.PASTA % nome):
			_falhas.append("som \"%s\" usado no codigo nao existe em %s" % [nome, Som.PASTA % nome])
	for falha in _falhas:
		printerr("FALHOU: %s" % falha)
	if _falhas.is_empty():
		print("SONS_OK %d sons conferidos" % nomes.size())
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _nomes_no_codigo() -> Dictionary:
	var achados := {}
	var busca := RegEx.create_from_string("Som\\.tocar(?:_musica)?\\(\"([a-z0-9_]+)\"")
	for pasta in PASTAS:
		for arquivo in DirAccess.get_files_at(pasta):
			if not arquivo.ends_with(".gd"):
				continue
			for achado in busca.search_all(FileAccess.get_file_as_string(pasta + arquivo)):
				achados[achado.get_string(1)] = true
	return achados
