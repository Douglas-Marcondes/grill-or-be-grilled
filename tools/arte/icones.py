"""Icones do HUD: coracao, chama de vida (acesa e apagada), ovo, galinha, moeda.

O HUD era uma linha de texto ("Guerreiro  50/50  Vidas: 3  Ovos: 0..."), que o
jogador tem de ler em vez de bater o olho. Plataformistas trocam rotulo por
icone: a vida e a Chama do Ninho, o mesmo simbolo da historia.

Uma folha so, na ordem de Icone em scripts/hud.gd. Todos com contorno escuro
para ler sobre o ceu claro da fazenda e sobre o painel do HUD.
"""

from tela import Tela, colar, contornar, de_ascii

CORES = {
    "r": "crista",
    "R": "crista_luz",
    "f": "fogo_borda",
    "F": "fogo",
    "n": "fogo_nucleo",
    "s": "pedra_sombra",
    "S": "pedra",
    "B": "pena_luz",
    "b": "pena_sombra",
    "o": "tinta",
    "y": "bico",
    "m": "palha_sombra",
    "Y": "ouro",
}

CORACAO = [
    ".rr.rr.",
    "rRRrrrr",
    "rRrrrrr",
    ".rrrrr.",
    "..rrr..",
    "...r...",
]

CHAMA = [
    "..f..",
    ".fF..",
    ".fFf.",
    "fFnFf",
    "fFnFf",
    "fnnnf",
    ".fff.",
]

OVO = [
    ".BBB.",
    "BBBBb",
    "BBBBb",
    "BBBbb",
    ".bbb.",
]

GALINHA = [
    "..rr...",
    ".rRr...",
    ".BBBB..",
    "BBoBBy.",
    "BBBBByy",
    ".BBBb..",
    "..bb...",
]

MOEDA = [
    ".mmmm.",
    "mYYYYm",
    "mYmmYm",
    "mYmmYm",
    "mYYYYm",
    ".mmmm.",
]


def _icone(linhas: list[str]) -> Tela:
    desenho = de_ascii(linhas, CORES)
    tela = Tela(desenho.largura + 2, desenho.altura + 2)
    colar(tela, desenho, 1, 1)
    contornar(tela, "tinta")
    return tela


def _apagada() -> Tela:
    """Mesma chama em cinza: a vida perdida continua no lugar, apagada, para o
    jogador ver quantas tinha e nao so quantas restam."""
    cinza = [linha.replace("n", "S").replace("F", "S").replace("f", "s")
             for linha in CHAMA]
    return _icone(cinza)


def icones() -> list[Tela]:
    return [_icone(CORACAO), _icone(CHAMA), _apagada(), _icone(OVO),
            _icone(GALINHA), _icone(MOEDA)]
