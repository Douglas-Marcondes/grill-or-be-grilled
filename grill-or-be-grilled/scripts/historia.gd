extends RefCounted

## Todo o texto narrativo da fase 1, num lugar so.
##
## A historia: a Fazenda Brasa Viva assava o melhor frango da regiao gracas a
## Chama do Ninho. Cansadas da grelha, as galinhas a roubaram e se entocaram no
## porao do celeiro sob a Galinha Real. O heroi desce para trazer a Chama de
## volta -- "ou voce grelha, ou e grelhado". O epilogo deixa a Galinha Real
## fugir pelo tunel, gancho para as proximas fases.
##
## Exemplo:
##     show_message(Historia.FALA_DO_CHEFE_AO_VER_O_HEROI, 4.0)

const PROLOGO := [
	"Por gerações, a Fazenda Brasa Viva assou o melhor frango da região. O segredo era a Chama do Ninho, um braseiro que nunca se apagava.",
	"Até a noite em que as galinhas cansaram da grelha. Guiadas pela Galinha Real, elas roubaram a Chama e se entocaram no porão do celeiro.",
	"Sem a Chama, a fazenda esfria e escurece. Alguém precisa descer até o ninho e trazê-la de volta.\nNa fazenda é assim: ou você grelha, ou é grelhado.",
]

const CHAMADA_DO_MENU := "A Chama do Ninho foi roubada e a fazenda está esfriando.\nDesça até o ninho da Galinha Real e traga-a de volta."
## Arma e estilo de cada classe, na carta da escolha de heroi. Cabe numa
## linha da carta de 92px (uns 14 caracteres): mais que isso quebra e vaza.
const CLASSES := {
	"Guerreiro": "Espada · perto",
	"Arqueiro": "Arco · longe",
	"Mago": "Varinha · luz",
}

const DICA_DE_TECLADO := "Mover: A/D ou setas   Pular: Espaço/W   Atacar: J/clique   Esquivar: Shift/L\nControle: analógico, A pula, X ataca, B esquiva"
const DICA_DE_TOQUE := "Setas à esquerda para andar. À direita: pular, atacar e esquivar."


static func dica_de_controles(tem_toque: bool) -> String:
	"""Dica do menu conforme o aparelho: no celular nao ha teclado para citar.

	Exemplo: Historia.dica_de_controles(DisplayServer.is_touchscreen_available())"""
	return DICA_DE_TOQUE if tem_toque else DICA_DE_TECLADO


const INICIO_DA_FASE := "Siga as penas até o celeiro. Os braseiros do caminho guardam um pouco da Chama."

## Texto de cada placa (Marco* no jogo.tscn), mostrado quando o heroi passa por ela.
const PLACAS := {
	"Marco1": "O galinheiro está vazio. Rastros de pena apontam para o celeiro.",
	"Marco2": "Ovos por toda parte. As galinhas caipiras daqui arremessam sem dó.",
	"Marco3": "Rabiscado a bico nas tábuas: \"NUNCA MAIS GRELHA\". Os galos treinam aqui.",
	"Marco4": "O calor vem de baixo. A Chama do Ninho está perto, e as guardiãs mais velhas a vigiam.",
	"Marco5": "No centro do ninho, a Galinha Real choca a Chama roubada.",
}

## Recados a cada quarto das galinhas derrotadas.
const AVANCO := [
	"As galinhas recuam. Alguém está mandando que elas protejam o caminho.",
	"Restos de carvão no chão: elas carregaram a Chama por aqui.",
	"O cacarejo fica mais grave. A Galinha Real sabe que você está chegando.",
]
const TODAS_DERROTADAS := "Nenhuma guardiã restou. Só a Galinha Real entre você e a Chama."

const FALA_DO_CHEFE_AO_VER_O_HEROI := "GALINHA REAL: \"Cem anos de churrasco, cozinheiro. Hoje quem vai para a brasa é você!\""
const FALA_DO_CHEFE_ENFURECIDA := "GALINHA REAL: \"Minhas penas estão pegando fogo! Agora é sério!\""
const QUEDA_DO_CHEFE := "A Galinha Real larga a Chama do Ninho e foge cacarejando pelo túnel!"

const EPILOGO := "A Chama volta para a fazenda e as luzes se acendem de novo.\nMas, lá no fundo do túnel, ecoa um cacarejo: \"Isto não acabou, cozinheiro...\""
const ARMADURA_GANHA := "A Galinha Real deixou cair a armadura: bico, crista e barbela desbloqueados!"
const ARMADURA_PERDIDA := "A armadura dela sumiu na fuga. Talvez na próxima."
const DERROTA := "Você virou omelete! Os ovos desta tentativa foram perdidos."


static func recado_de_avanco(derrotadas: int, total: int) -> String:
	"""Recado ao cruzar 1/4, 2/4 e 3/4 das galinhas; vazio fora desses pontos.

	Exemplo: recado_de_avanco(11, 22) -> AVANCO[1]
	"""
	if total < 4:
		return ""
	for quarto in AVANCO.size():
		if derrotadas == ceili(total * (quarto + 1) / 4.0):
			return AVANCO[quarto]
	return ""
