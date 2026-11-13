extends RefCounted

## Os tipos de inimigo comum da fase: qual script comanda e qual folha veste.
##
## O tipo vem do marcador no jogo.tscn (metadata/tipo em cada Bot), entao trocar
## uma galinha por um galo e coisa de inspetor, nao de codigo. Sem metadado o
## marcador e galinha comum. fase1.gd usa isto para criar o inimigo e
## previa_do_editor.gd para mostrar no editor a variante certa.
##
## Exemplo:
##     var inimigo := CharacterBody2D.new()
##     inimigo.set_script(Bestiario.script_de("galo"))
##     inimigo.folha_do_sprite = Bestiario.folha_de("galo")

const PADRAO := "galinha"
const TIPOS := {
	"galinha": {"script": preload("res://chicken_enemy.gd"), "folha": "galinha"},
	"galo": {"script": preload("res://galo.gd"), "folha": "galo"},
	"atiradeira": {"script": preload("res://galinha_atiradeira.gd"), "folha": "galinha_atiradeira"},
}


static func tipo_do_marcador(marcador: Node) -> String:
	"""Tipo declarado no marcador; erro e galinha comum se o nome nao existir."""
	var tipo := str(marcador.get_meta("tipo", PADRAO))
	if not TIPOS.has(tipo):
		push_error("tipo de inimigo desconhecido %r em %s; esperado um de %s" % [tipo, marcador.name, ", ".join(TIPOS.keys())])
		return PADRAO
	return tipo


static func script_de(tipo: String) -> GDScript:
	return TIPOS[tipo]["script"]


static func folha_de(tipo: String) -> String:
	return TIPOS[tipo]["folha"]
