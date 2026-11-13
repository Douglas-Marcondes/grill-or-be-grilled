"""Projeteis: flecha, orbe de magia, pena da Galinha Real e ovo da atiradeira.

Cada um tem silhueta propria, apontando para a direita -- projectile.gd gira o
sprite pela velocidade, entao o ovo em arco e a pena em leque apontam para onde
vao. Uma folha so, na ordem de TIPOS em projectile.gd.
"""

from rampas import BRILHO
from tela import Tela
from volume import Escultura


def _flecha() -> Tela:
    figura = Escultura(19, 9)
    figura.capsula((4, 4.5), (14, 4.5), 0.7, "madeira", borda=False)
    figura.poligono([(13, 2), (18, 4.5), (13, 7)], "metal", claridade=0.9, queda=0.12)
    figura.poligono([(1, 1.5), (5, 1.5), (7, 4.5), (5, 7.5), (1, 7.5), (3, 4.5)], "crista",
                    claridade=0.8, queda=0.08)
    return figura.render()


def _magia() -> Tela:
    """Orbe com nucleo claro e faiscas nos quatro cantos."""
    figura = Escultura(13, 13)
    figura.elipse(6.5, 6.5, 4.4, 4.4, "magia")
    figura.elipse(5.6, 5.6, 2.0, 2.0, "magia", borda=False, clarear=0.6)
    for x, y in ((1, 6), (11, 6), (6, 1), (6, 11)):
        figura.marcar(x, y, "magia", BRILHO)
    return figura.render()


def _pena() -> Tela:
    """Pena branca de ponta vermelha, afiada como dardo."""
    figura = Escultura(17, 9)
    figura.poligono([(1, 4.5), (6, 1.5), (13, 2.5), (16, 4.5), (13, 6.5), (6, 7.5)], "pena",
                    claridade=0.9, queda=0.1)
    figura.poligono([(11, 2.5), (16, 4.5), (11, 6.5)], "crista", claridade=0.8, borda=False)
    figura.riscar([(x, 4) for x in range(2, 12)])
    return figura.render()


def _ovo() -> Tela:
    figura = Escultura(9, 10)
    figura.elipse(4.5, 5.4, 3.2, 3.6, "osso")
    figura.elipse(4.5, 4.2, 2.5, 3.0, "osso", borda=False)
    return figura.render()


def projeteis() -> list[Tela]:
    return [_flecha(), _magia(), _pena(), _ovo()]
