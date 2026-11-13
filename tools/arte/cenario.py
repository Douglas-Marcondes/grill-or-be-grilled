"""Texturas de terreno: miolo dos blocos, faixa de superficie, parede e franja.

Tudo repete sem emenda (ladrilho.py) e e aplicado como textura repetida em
Polygon2D por scripts/terreno.gd, que aproveita o layout editavel da fase.

Os ladrilhos tem 64px, nao 16: num bloco de 400x240 um tile de 16px repete 375
vezes e o olho ve a grade. Com 64px cabem pedras, veios e tabuas de tamanhos
diferentes, e a repeticao so aparece a cada quatro vezes mais chao.

As faixas de superficie tambem tem 64px de altura: os 10px de cima sao a
beirada onde se pisa (grama, tabua gasta, laje) e o resto e o miolo do bloco,
porque plataforma fina recebe a faixa inteira como textura (terreno.gd,
ALTURA_DE_SALIENCIA).
"""

import math

from ladrilho import Ladrilho, semeado
from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA, tom
from tela import Tela

LADO = 64
ALTURA_DA_BEIRADA = 10
ALTURA_DA_FRANJA = 6


# -- miolos ------------------------------------------------------------------

def _terra() -> Ladrilho:
    """Terra da fazenda: camadas onduladas, torroes e pedras enterradas."""
    piso = Ladrilho(LADO, LADO, "terra", SOMBRA)
    sorteio = semeado("terra")
    for _ in range(26):
        piso.mancha(sorteio.randrange(LADO), sorteio.randrange(LADO),
                    sorteio.randrange(3, 9), sorteio.randrange(1, 4), 1)
    for linha, fase in ((13, 0.0), (34, 1.7), (53, 3.1)):
        for x in range(LADO):
            y = linha + round(2.2 * math.sin(2 * math.pi * x / LADO * 2 + fase))
            piso.pintar(x, y, CONTORNO)
            piso.pintar(x, y + 1, BASE)
    for _ in range(6):
        piso.pedra(sorteio.randrange(LADO), sorteio.randrange(LADO),
                   sorteio.randrange(2, 6), sorteio.randrange(1, 4), "pedra")
    _salpicar(piso, sorteio, 46, LUZ)
    return piso


def _alvenaria(nome: str, rampa: str, musgo: bool, tons: tuple[int, ...] = (SOMBRA, BASE, BASE, BASE)) -> Ladrilho:
    """Pedras assentadas em fiadas de 16px, de largura sorteada: cada pedra
    tem luz no topo, sombra na base e junta escura em volta."""
    piso = Ladrilho(LADO, LADO, rampa)
    sorteio = semeado(nome)
    for fiada in range(LADO // 16):
        x = sorteio.randrange(8)
        while x < LADO + 8:
            largura = sorteio.choice([10, 13, 16, 19, 22])
            _pedra_de_alvenaria(piso, sorteio, x, fiada * 16, largura, sorteio.choice(tons))
            x += largura
    if musgo:
        for _ in range(14):
            x, y = sorteio.randrange(LADO), sorteio.randrange(LADO // 16) * 16
            piso.pintar(x, y, sorteio.choice([SOMBRA, BASE]), "grama")
            piso.pintar(x + 1, y, SOMBRA, "grama")
    return piso


def _pedra_de_alvenaria(piso: Ladrilho, sorteio, x: int, y: int, largura: int,
                        tom_da_pedra: int) -> None:
    piso.bloco(x, y, largura, 16, tom_da_pedra)
    piso.bloco(x + 1, y + 1, largura - 2, 1, tom_da_pedra + 1)
    piso.bloco(x + 1, y + 1, 1, 13, tom_da_pedra + 1)
    piso.bloco(x + 1, y + 14, largura - 1, 1, tom_da_pedra - 1)
    piso.bloco(x, y, largura, 1, CONTORNO)
    piso.bloco(x, y, 1, 16, CONTORNO)
    for _ in range(largura // 3):
        piso.mudar(x + sorteio.randrange(2, largura - 1), y + sorteio.randrange(3, 13),
                   sorteio.choice([-1, 1]))
    if sorteio.random() < 0.35:
        inicio = x + sorteio.randrange(3, largura - 3)
        for passo in range(sorteio.randrange(3, 7)):
            piso.pintar(inicio + passo // 2, y + 3 + passo, CONTORNO)


def _tabuado(nome: str, rampa: str) -> Ladrilho:
    """Tabuas horizontais de 16px com emenda, veio, no e prego."""
    piso = Ladrilho(LADO, LADO, rampa)
    sorteio = semeado(nome)
    for tabua in range(LADO // 16):
        topo = tabua * 16
        piso.bloco(0, topo, LADO, 16, sorteio.choice([SOMBRA, BASE, BASE]))
        _veios(piso, sorteio, topo)
        piso.bloco(0, topo, LADO, 1, CONTORNO)
        piso.bloco(0, topo + 1, LADO, 1, LUZ)
        piso.bloco(0, topo + 15, LADO, 1, SOMBRA)
        emenda = sorteio.randrange(LADO)
        piso.bloco(emenda, topo, 1, 16, CONTORNO)
        for prego in (emenda - 3, emenda + 3):
            piso.pintar(prego, topo + 4, LUZ, "metal")
            piso.pintar(prego, topo + 11, LUZ, "metal")
    return piso


def _ripado(nome: str, rampa: str) -> Ladrilho:
    """Parede de fundo do celeiro: ripas verticais escuras e uma viga.

    Vertical e de pouco contraste de proposito: as plataformas da entrada sao
    tabuas horizontais claras, e parede igual a elas escondia onde se pisa."""
    piso = Ladrilho(LADO, LADO, rampa, SOMBRA)
    sorteio = semeado(nome)
    for ripa in range(LADO // 8):
        x = ripa * 8
        piso.bloco(x, 0, 8, LADO, sorteio.choice([SOMBRA, SOMBRA, BASE]))
        piso.bloco(x, 0, 1, LADO, CONTORNO)
        for _ in range(3):
            inicio = sorteio.randrange(LADO)
            for dy in range(sorteio.randrange(5, 16)):
                piso.mudar(x + sorteio.randrange(2, 7), inicio + dy, -1)
    piso.bloco(0, 28, LADO, 6, BASE)
    piso.bloco(0, 28, LADO, 1, LUZ)
    piso.bloco(0, 34, LADO, 2, CONTORNO)
    return piso


def _veios(piso: Ladrilho, sorteio, topo: int) -> None:
    for _ in range(7):
        y, inicio = topo + sorteio.randrange(3, 14), sorteio.randrange(LADO)
        passo = sorteio.choice([-1, 1])
        for dx in range(sorteio.randrange(6, 22)):
            piso.mudar(inicio + dx, y, passo)
    if sorteio.random() < 0.7:
        x, y = sorteio.randrange(LADO), topo + sorteio.randrange(5, 11)
        piso.mancha(x, y, 2, 1, -1)
        piso.pintar(x, y, CONTORNO)


def _salpicar(piso: Ladrilho, sorteio, quantidade: int, nivel: int) -> None:
    for _ in range(quantidade):
        x, y = sorteio.randrange(LADO), sorteio.randrange(LADO)
        piso.pintar(x, y, nivel)
        piso.pintar(x, y + 1, CONTORNO)


# -- faixas de superficie ----------------------------------------------------

def _grama() -> Ladrilho:
    """Gramado da fazenda: fios claros no topo e borda de baixo em serra,
    com palha seca misturada."""
    piso = Ladrilho(LADO, LADO, "terra", SOMBRA)
    piso.copiar_de(_terra(), 0)
    sorteio = semeado("grama")
    for x in range(LADO):
        fundura = 6 + (x * 7 % 4) + sorteio.randrange(2)
        for y in range(fundura):
            nivel = LUZ if y < 2 else BASE if y < fundura - 2 else SOMBRA
            piso.pintar(x, y, nivel, "grama")
        piso.pintar(x, fundura, CONTORNO, "grama")
        if sorteio.random() < 0.3:
            piso.pintar(x, 0, BRILHO, "grama")
        if sorteio.random() < 0.16:
            piso.pintar(x, sorteio.randrange(1, 4), LUZ, "palha")
    return piso


def _tabua() -> Ladrilho:
    """Prancha gasta da entrada do celeiro: quina clara e pregos."""
    piso = Ladrilho(LADO, LADO, "madeira")
    piso.copiar_de(_tabuado("madeira", "madeira"), 0)
    sorteio = semeado("tabua")
    piso.bloco(0, 0, LADO, ALTURA_DA_BEIRADA, LUZ)
    piso.bloco(0, 0, LADO, 1, BRILHO)
    piso.bloco(0, 7, LADO, 2, BASE)
    piso.bloco(0, 9, LADO, 1, CONTORNO)
    for _ in range(10):
        inicio, y = sorteio.randrange(LADO), sorteio.randrange(2, 7)
        for dx in range(sorteio.randrange(4, 14)):
            piso.pintar(inicio + dx, y, BASE)
    for x in range(5, LADO, 21):
        piso.bloco(x, 0, 1, 9, SOMBRA)
        piso.pintar(x + 3, 3, BRILHO, "metal")
        piso.pintar(x + 3, 4, CONTORNO, "metal")
    return piso


def _laje() -> Ladrilho:
    """Lajes do porao: pedra clara e lisa, junta escura e musgo nas frestas."""
    piso = Ladrilho(LADO, LADO, "pedra")
    piso.copiar_de(_alvenaria("pedra", "pedra", True), 0)
    sorteio = semeado("laje")
    piso.bloco(0, 0, LADO, ALTURA_DA_BEIRADA, LUZ)
    piso.bloco(0, 0, LADO, 1, BRILHO)
    piso.bloco(0, 7, LADO, 2, BASE)
    piso.bloco(0, 9, LADO, 1, CONTORNO)
    x = 0
    while x < LADO:
        piso.bloco(x, 0, 1, 9, CONTORNO)
        piso.pintar(x - 1, 1, BASE, "grama")
        piso.pintar(x + 1, 0, LUZ, "grama")
        piso.pintar(x + 1, 1, BASE, "grama")
        x += sorteio.choice([13, 17, 21])
    for _ in range(18):
        piso.mudar(sorteio.randrange(LADO), sorteio.randrange(2, 7), -1)
    return piso


def _palha() -> Ladrilho:
    """Palha trancada do ninho: fios curtos em duas direcoes."""
    piso = Ladrilho(32, 16, "palha")
    sorteio = semeado("palha")
    for _ in range(70):
        x, y = sorteio.randrange(32), sorteio.randrange(16)
        nivel = sorteio.choice([SOMBRA, LUZ, LUZ, BRILHO])
        rumo = sorteio.choice([-1, 1])
        for passo in range(sorteio.randrange(2, 5)):
            piso.pintar(x + passo, y + passo * rumo, nivel)
    return piso


# -- franjas -----------------------------------------------------------------

def _franja(nome: str, rampa: str, niveis: list[int], maximo: int) -> Tela:
    """Fios de comprimento sorteado pendendo da beirada. E o que tira o corte
    reto embaixo da faixa -- borda reta e o que mais faz plataforma de pixel
    art parecer retangulo. O que nao e fio fica transparente."""
    tela = Tela(LADO, ALTURA_DA_FRANJA)
    sorteio = semeado("franja_%s" % nome)
    for x in range(LADO):
        tela.definir(x, 0, tom(rampa, niveis[0]))
        comprimento = sorteio.choice([0, 1, 1, 2, 2, 3, maximo])
        for y in range(1, 1 + comprimento):
            tela.definir(x, y, tom(rampa, niveis[min(y, len(niveis) - 1)]))
    return tela


FRANJAS = {
    "grama": lambda: _franja("grama", "grama", [CONTORNO, SOMBRA, SOMBRA, BASE, SOMBRA], 5),
    "laje": lambda: _franja("laje", "grama", [CONTORNO, SOMBRA, BASE, SOMBRA], 4),
    "tabua": lambda: _franja("tabua", "madeira", [CONTORNO, CONTORNO, SOMBRA], 3),
}

TILES = {
    "terra": lambda: _terra().render(),
    "pedra": lambda: _alvenaria("pedra", "pedra", True).render(),
    "madeira": lambda: _tabuado("madeira", "madeira").render(),
    "grama": lambda: _grama().render(),
    "palha": lambda: _palha().render(),
    "laje": lambda: _laje().render(),
    "tabua": lambda: _tabua().render(),
    "parede_celeiro": lambda: _ripado("parede_celeiro", "madeira_funda").render(),
    "parede_porao": lambda: _alvenaria("parede_porao", "pedra_funda", False, (SOMBRA,)).render(),
}
