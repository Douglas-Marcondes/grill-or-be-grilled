"""Adereços do cenario: tocha com chama animada e halo de luz.

O halo e um sprite aditivo, nao um Light2D. Numa cena com 33 tochas isso evita
depender do suporte de luz 2D do renderizador GL Compatibility e da controle
exato do raio e do degrade -- e, em pixel art, o degrade precisa ser ditherizado
de proposito, coisa que luz dinamica nao faz.
"""

import random

from paleta import cor
from tela import Tela, de_ascii, retangulo

CORES_DE_TOCHA = {
    "o": "tinta",
    "m": "madeira",
    "M": "madeira_luz",
    "f": "fogo_borda",
    "F": "fogo",
    "n": "fogo_nucleo",
}

SUPORTE = [
    ".ooooo.",
    "oMMMMMo",
    "oMmmmMo",
    "oMmmmMo",
    ".oMmMo.",
    ".oMmMo.",
    ".oMmMo.",
    ".oMmMo.",
    ".oMmMo.",
    "..ooo..",
]

## Quatro quadros de chama: a altura e a largura do nucleo mudam a cada quadro,
## que e o que faz fogo parecer fogo em vez de triangulo piscando.
CHAMAS = [
    [
        "...f...",
        "..fFf..",
        ".fFnFf.",
        ".fFnFf.",
        "fFFnFFf",
        "fFFFFFf",
        ".fffff.",
    ],
    [
        "..f....",
        "..fFf..",
        ".fFnFf.",
        "fFFnFFf",
        "fFFnFFf",
        ".fFFFf.",
        ".fffff.",
    ],
    [
        "....f..",
        "..ffFf.",
        ".fFnFf.",
        ".fFnFf.",
        "fFFnFFf",
        ".fFFFf.",
        ".fffff.",
    ],
    [
        "...f...",
        "..fFff.",
        ".ffFnf.",
        ".fFnFf.",
        "fFFnFFf",
        "fFFFFFf",
        ".fffff.",
    ],
]

_BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def tocha_suporte() -> Tela:
    return de_ascii(SUPORTE, CORES_DE_TOCHA)


def tocha_chama(quadro: int = 0) -> Tela:
    if not 0 <= quadro < len(CHAMAS):
        raise ValueError(
            "quadro de chama invalido: %d (esperado 0 a %d)"
            % (quadro, len(CHAMAS) - 1)
        )
    return de_ascii(CHAMAS[quadro], CORES_DE_TOCHA)


def brilho(raio: int = 26) -> Tela:
    """Halo radial ditherizado, para ser desenhado em blend aditivo.

    Degrade liso num jogo de pixel art mostra faixas; o dither de Bayer quebra a
    transicao em pontos e mantem a imagem coerente com o resto da arte.
    """
    lado = raio * 2
    tela = Tela(lado, lado)
    centro = raio
    for y in range(lado):
        for x in range(lado):
            distancia = ((x - centro) ** 2 + (y - centro) ** 2) ** 0.5
            if distancia >= raio:
                continue
            intensidade = 1.0 - distancia / raio
            limite = intensidade * intensidade * 16.0
            if intensidade > 0.8 or _BAYER[y % 4][x % 4] < limite:
                tom = "fogo_nucleo" if intensidade > 0.72 else "fogo"
                tela.definir(x, y, cor(tom))
    return tela


PROPS = {
    "tocha_suporte": tocha_suporte,
    "brilho": brilho,
}
