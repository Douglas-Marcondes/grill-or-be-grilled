"""Itens pequenos: ovos coletaveis, as tres armas e a armadura de galinha.

Ficam em sprites proprios, separados do heroi, para que trocar de arma na loja
nao exija redesenhar o personagem (player.gd pendura a arma na mao e a armadura
na cabeca).
"""

from rampas import BRILHO, LUZ, SOMBRA
from tela import Tela
from volume import Escultura

## Uma rampa por raridade, na ordem usada por egg_pickup.gd.
RAMPAS_DE_OVO = ["osso", "verde", "azul", "magia", "ouro"]


def ovo(raridade: int = 0) -> Tela:
    """Ovo coletavel de uma das cinco raridades, com pintas e brilho."""
    if not 0 <= raridade < len(RAMPAS_DE_OVO):
        raise ValueError("raridade de ovo invalida: %d (esperado 0 a %d)"
                         % (raridade, len(RAMPAS_DE_OVO) - 1))
    figura = Escultura(11, 13)
    figura.elipse(5.5, 7.2, 4.2, 4.6, RAMPAS_DE_OVO[raridade])
    figura.elipse(5.5, 5.4, 3.3, 4.0, RAMPAS_DE_OVO[raridade], borda=False)
    figura.riscar([(7, 8), (4, 9), (6, 10)])
    figura.marcar(4, 4, RAMPAS_DE_OVO[raridade], BRILHO)
    return figura.render()


def _espada() -> Tela:
    """Espada larga: cabo de couro, guarda de ouro e fio de luz na lamina."""
    figura = Escultura(25, 11)
    figura.capsula((2, 5.5), (6, 5.5), 1.3, "couro")
    figura.elipse(1.8, 5.5, 1.6, 1.6, "ouro")
    figura.poligono([(8, 3), (20, 3), (24, 5.5), (20, 8), (8, 8)], "metal", claridade=0.6)
    for x in range(8, 22):
        figura.marcar(x, 3, "metal", BRILHO)
        figura.marcar(x, 4, "metal", LUZ)
        figura.marcar(x, 7, "metal", SOMBRA)
    figura.riscar([(x, 5) for x in range(9, 20)])
    figura.capsula((7, 1.5), (7, 9.5), 1.2, "ouro")
    return figura.render()


def _arco() -> Tela:
    """Arco recurvo com a corda para o lado do heroi."""
    figura = Escultura(11, 21)
    for y in range(2, 19):
        figura.marcar(2, y, "pano", LUZ)
    for inicio, fim in (((2.5, 1.5), (7.5, 6)), ((7.5, 6), (8.5, 10.5)),
                        ((8.5, 10.5), (7.5, 15)), ((7.5, 15), (2.5, 19.5))):
        figura.capsula(inicio, fim, 1.3, "madeira", borda=False)
    figura.capsula((8.5, 8.5), (8.5, 12.5), 1.5, "couro")
    return figura.render()


def _varinha() -> Tela:
    """Varinha torta com uma estrela acesa na ponta."""
    figura = Escultura(19, 11)
    figura.capsula((1.5, 6.5), (11, 5.5), 1.2, "madeira", raio_final=0.9)
    figura.poligono([(14, 0.5), (15.4, 4), (18.5, 5.5), (15.4, 7), (14, 10.5), (12.6, 7),
                     (9.5, 5.5), (12.6, 4)], "magia", claridade=0.8)
    figura.elipse(14, 5.5, 1.6, 1.6, "magia", borda=False, clarear=0.5)
    return figura.render()


ARMAS = {"Espada": _espada, "Arco": _arco, "Varinha": _varinha}


def arma(nome: str) -> Tela:
    """Sprite da arma equipada, voltado para a direita, cabo a esquerda."""
    if nome not in ARMAS:
        raise ValueError("arma desconhecida: %r (esperado uma de %s)"
                         % (nome, ", ".join(ARMAS)))
    return ARMAS[nome]()


def armadura_galinha() -> Tela:
    """Crista e barbela da Galinha Real usadas como elmo: o trofeu comico."""
    figura = Escultura(18, 11)
    for x, altura in ((5.5, 3.2), (9, 4.2), (12.5, 3.0)):
        figura.elipse(x, 6.5 - altura * 0.5, 2.2, altura, "crista", borda=False)
    figura.poligono([(2.5, 6), (15.5, 6), (16.5, 9), (1.5, 9)], "crista", claridade=0.6)
    for x in range(2, 17):
        figura.marcar(x, 9, "crista", SOMBRA)
    figura.marcar(8, 3, "crista", BRILHO)
    return figura.render()
