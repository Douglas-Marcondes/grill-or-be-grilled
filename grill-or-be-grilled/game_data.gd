extends Node

var selected_class := "Guerreiro"
var gold := 0
var strength_bonus := 0
var health_bonus := 0
var armor_bonus := 0
var owns_chicken_armor := false
var run_eggs := 0
var run_gold := 0
var last_sale := 0
var phase_won := false
var equipped_weapon := ""
var weapon_override := false
var owned_weapons: Array[String] = []
var viu_prologo := false

## Precos da loja do acampamento: melhoria permanente -> [preco, atributo, ganho].
const MELHORIAS := {
	"forca": [20, "strength_bonus", 5],
	"vida": [20, "health_bonus", 5],
	"armadura": [25, "armor_bonus", 1],
}
const PRECO_DE_ARMA := 15

## Testes e ferramentas (cenas em res://ferramentas/) gravam num save proprio:
## antes, rodar o teste de fumaca mexia nas moedas e no prologo do jogador.
const SAVE_DO_JOGO := "user://grill_or_be_grilled.cfg"
const SAVE_DAS_FERRAMENTAS := "user://ferramentas.cfg"
var caminho_do_save := SAVE_DO_JOGO

func _ready() -> void:
	for argumento in OS.get_cmdline_args():
		if argumento.begins_with("res://ferramentas/"):
			caminho_do_save = SAVE_DAS_FERRAMENTAS
	var save := ConfigFile.new()
	if save.load(caminho_do_save) == OK:
		gold = int(save.get_value("player", "gold", 0))
		strength_bonus = int(save.get_value("player", "strength_bonus", 0))
		health_bonus = int(save.get_value("player", "health_bonus", 0))
		armor_bonus = int(save.get_value("player", "armor_bonus", 0))
		owns_chicken_armor = bool(save.get_value("player", "chicken_armor", false))
		equipped_weapon = str(save.get_value("player", "equipped_weapon", ""))
		weapon_override = bool(save.get_value("player", "weapon_override", false))
		viu_prologo = bool(save.get_value("player", "viu_prologo", false))
		for weapon in save.get_value("player", "owned_weapons", []):
			owned_weapons.append(str(weapon))

func save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("player", "gold", gold)
	save.set_value("player", "strength_bonus", strength_bonus)
	save.set_value("player", "health_bonus", health_bonus)
	save.set_value("player", "armor_bonus", armor_bonus)
	save.set_value("player", "chicken_armor", owns_chicken_armor)
	save.set_value("player", "equipped_weapon", equipped_weapon)
	save.set_value("player", "weapon_override", weapon_override)
	save.set_value("player", "owned_weapons", owned_weapons)
	save.set_value("player", "viu_prologo", viu_prologo)
	save.save(caminho_do_save)

func begin_run() -> void:
	run_eggs = 0
	run_gold = 0
	phase_won = false

func finish_run() -> void:
	last_sale = run_eggs
	gold += last_sale
	run_gold = 0
	run_eggs = 0
	phase_won = true

func fail_run() -> void:
	run_eggs = 0
	run_gold = 0
	last_sale = 0
	phase_won = false

func comprar_melhoria(tipo: String) -> bool:
	"""Compra uma melhoria de MELHORIAS e salva. Falso se faltar moeda.

	Exemplo: GameData.comprar_melhoria("forca")
	"""
	if not MELHORIAS.has(tipo):
		push_error("melhoria desconhecida %r; esperado uma de %s" % [tipo, ", ".join(MELHORIAS.keys())])
		return false
	var preco: int = MELHORIAS[tipo][0]
	if gold < preco:
		return false
	gold -= preco
	set(MELHORIAS[tipo][1], int(get(MELHORIAS[tipo][1])) + MELHORIAS[tipo][2])
	save_progress()
	return true

func comprar_arma(arma: String) -> bool:
	"""Compra (se preciso) e equipa a arma. Falso se faltar moeda.

	Exemplo: GameData.comprar_arma("Arco")
	"""
	if not owned_weapons.has(arma):
		if gold < PRECO_DE_ARMA:
			return false
		gold -= PRECO_DE_ARMA
		owned_weapons.append(arma)
	equipped_weapon = arma
	weapon_override = true
	save_progress()
	return true
