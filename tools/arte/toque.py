"""Botoes de toque para jogar no celular: esquerda, direita, pular, atacar, esquivar.

Circulo translucido com icone no meio, no padrao de plataformistas mobile
(direcional a esquerda, acoes a direita). Duas folhas na mesma ordem de
BOTOES em scripts/controles_de_toque.gd: solta e apertada (aro aceso), que o
TouchScreenButton troca sozinho.
"""

from paleta import cor
from tela import Tela, pintar

LADO = 30
RAIO = 14

ICONES = {
    "esquerda": [
        "....o.....",
        "...oo.....",
        "..oooooooo",
        ".ooooooooo",
        "..oooooooo",
        "...oo.....",
        "....o.....",
    ],
    "direita": [
        ".....o....",
        ".....oo...",
        "oooooooo..",
        "ooooooooo.",
        "oooooooo..",
        ".....oo...",
        ".....o....",
    ],
    "pular": [
        "....o....",
        "...ooo...",
        "..ooooo..",
        ".ooooooo.",
        "...ooo...",
        "...ooo...",
        "...ooo...",
        "...ooo...",
    ],
    "atacar": [
        "........oo",
        ".......ooo",
        "......ooo.",
        ".....ooo..",
        "o...ooo...",
        ".oooo.....",
        "..oo......",
        ".o.oo.....",
        "o...o.....",
    ],
    "esquivar": [
        "..ooooo...",
        "..........",
        "ooooooooo.",
        "..........",
        "...ooooooo",
        "..........",
        ".oooooo...",
    ],
}

ORDEM = ["esquerda", "direita", "pular", "atacar", "esquivar"]


def _botao(icone: str, apertado: bool) -> Tela:
    tela = Tela(LADO, LADO)
    centro = LADO / 2.0 - 0.5
    miolo = (*cor("roxo_noite")[:3], 150)
    aro = cor("laranja" if apertado else "cinza_claro")
    for y in range(LADO):
        for x in range(LADO):
            distancia = ((x - centro) ** 2 + (y - centro) ** 2) ** 0.5
            if distancia <= RAIO - 1.5:
                tela.definir(x, y, miolo)
            elif distancia <= RAIO:
                tela.definir(x, y, aro)
    linhas = ICONES[icone]
    tom = "amarelo" if apertado else "creme"
    pintar(tela, (LADO - len(linhas[0])) // 2, (LADO - len(linhas)) // 2,
           linhas, {"o": tom})
    return tela


def botoes(apertado: bool) -> list[Tela]:
    return [_botao(icone, apertado) for icone in ORDEM]
