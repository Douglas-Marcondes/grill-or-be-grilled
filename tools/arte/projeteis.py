"""Projeteis: flecha, orbe de magia, pena da Galinha Real e ovo da atiradeira.

Eram retangulos de cor chapada (draw_rect em projectile.gd): a flecha do
arqueiro e a pena do chefe so se distinguiam pela cor. Cada um ganha silhueta
propria, apontando para a direita -- projectile.gd gira o sprite pela
velocidade, entao o ovo em arco e a pena em leque apontam para onde vao.

Uma folha so, na ordem de TIPOS em projectile.gd.
"""

from tela import Tela, colar, contornar, de_ascii

CORES = {
    "w": "madeira",
    "a": "aco",
    "A": "aco_luz",
    "p": "pena_sombra",
    "P": "pena",
    "m": "magia",
    "M": "magia_luz",
    "b": "branco",
    "f": "fogo_borda",
    "F": "fogo",
    "n": "fogo_nucleo",
    "o": "pena_luz",
    "O": "pena_sombra",
}

FLECHA = [
    "pP.........a..",
    ".PPwwwwwwwwaAA",
    "pP.........a..",
]

MAGIA = [
    "..mMm..",
    ".mMbMm.",
    "mMbbbMm",
    ".mMbMm.",
    "..mMm..",
]

PENA = [
    "..fFFFf...",
    "fFFnnnFFf.",
    "nnnnnnnnnn",
    "fFFnnnFFf.",
    "..fFFFf...",
]

OVO = [
    ".oo.",
    "oooo",
    "oooO",
    "ooOO",
    ".OO.",
]


def _projetil(linhas: list[str]) -> Tela:
    desenho = de_ascii(linhas, CORES)
    tela = Tela(desenho.largura + 2, desenho.altura + 2)
    colar(tela, desenho, 1, 1)
    contornar(tela, "tinta")
    return tela


def projeteis() -> list[Tela]:
    return [_projetil(FLECHA), _projetil(MAGIA), _projetil(PENA), _projetil(OVO)]
