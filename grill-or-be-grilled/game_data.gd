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

func _ready() -> void:
	var save := ConfigFile.new()
	if save.load("user://grill_or_be_grilled.cfg") == OK:
		gold = int(save.get_value("player", "gold", 0))
		strength_bonus = int(save.get_value("player", "strength_bonus", 0))
		health_bonus = int(save.get_value("player", "health_bonus", 0))
		armor_bonus = int(save.get_value("player", "armor_bonus", 0))
		owns_chicken_armor = bool(save.get_value("player", "chicken_armor", false))
		equipped_weapon = str(save.get_value("player", "equipped_weapon", ""))
		weapon_override = bool(save.get_value("player", "weapon_override", false))
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
	save.save("user://grill_or_be_grilled.cfg")

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
