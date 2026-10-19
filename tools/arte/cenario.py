"""Texturas de terreno e fundo, geradas de forma deterministica e sem emenda.

Textura de preenchimento nao se desenha bem como ASCII art: o que importa e que
ela repita sem costura visivel. Entao aqui o ruido e sorteado com semente fixa
(mesmo PNG a cada execucao) e toda vizinhanca usa modulo da largura/altura, o
que garante que a borda direita case com a esquerda e a de baixo com a de cima.

Cada tile tem 16x16 e e aplicado como textura repetida em Polygon2D pelo
scripts/terreno.gd, aproveitando o layout da fase que ja e editavel no Godot.
"""

import random

from tela import Tela, retangulo
from paleta import cor

LADO = 16


def _semeado(nome: str) -> random.Random:
    """Gerador estavel por tile: a arte nao muda entre execucoes do script."""
    return random.Random("grill-or-be-grilled/%s" % nome)


def _salpicar(tela: Tela, sorteio: random.Random, nome: str, quantidade: int) -> None:
    pixel = cor(nome)
    for _ in range(quantidade):
        tela.definir(sorteio.randrange(LADO), sorteio.randrange(LADO), pixel)


def _pedrinha(tela: Tela, x: int, y: int, claro: str, escuro: str) -> None:
    """Pedrinha de 2x2 com luz em cima e sombra embaixo, envolvendo a borda."""
    tela.definir(x % LADO, y % LADO, cor(claro))
    tela.definir((x + 1) % LADO, y % LADO, cor(claro))
    tela.definir(x % LADO, (y + 1) % LADO, cor(escuro))
    tela.definir((x + 1) % LADO, (y + 1) % LADO, cor(escuro))


def tile_terra() -> Tela:
    """Terra batida da fazenda: base media, torroes e pedrinhas."""
    tela = Tela(LADO, LADO)
    # Base escura de proposito: a plataforma tem 240px de altura e, clara, vira
    # uma mancha que domina a tela. Escura ela recua e a faixa de palha no topo
    # -- que e a parte que importa, onde se pisa -- ganha destaque.
    retangulo(tela, 0, 0, LADO, LADO, "terra_sombra")
    sorteio = _semeado("terra")
    _salpicar(tela, sorteio, "terra", 30)
    _salpicar(tela, sorteio, "terra_luz", 10)
    for _ in range(3):
        _pedrinha(tela, sorteio.randrange(LADO), sorteio.randrange(LADO),
                  "terra_luz", "terra_sombra")
    return tela


def tile_pedra() -> Tela:
    """Alvenaria do porao: duas fiadas de 8px com junta alternada."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "pedra")
    sorteio = _semeado("pedra")
    for fiada in range(2):
        topo = fiada * 8
        retangulo(tela, 0, topo, LADO, 1, "pedra_sombra")
        junta = 0 if fiada == 0 else 8
        retangulo(tela, junta, topo, 1, 8, "pedra_sombra")
        retangulo(tela, 0, topo + 1, LADO, 1, "pedra_luz")
    _salpicar(tela, sorteio, "pedra_sombra", 18)
    _salpicar(tela, sorteio, "pedra_luz", 10)
    return tela


def tile_madeira() -> Tela:
    """Tabuas horizontais da entrada: veio, junta e prego."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "madeira")
    sorteio = _semeado("madeira")
    for tabua in range(2):
        topo = tabua * 8
        retangulo(tela, 0, topo, LADO, 1, "madeira_sombra")
        for _ in range(3):
            y = topo + sorteio.randrange(2, 7)
            inicio = sorteio.randrange(LADO)
            for passo in range(sorteio.randrange(4, 9)):
                tela.definir((inicio + passo) % LADO, y, cor("madeira_luz"))
        tela.definir(2 + tabua * 8, topo + 4, cor("pedra_luz"))
    return tela


def tile_palha() -> Tela:
    """Faixa de palha seca: fios diagonais sobre base quente."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "palha")
    sorteio = _semeado("palha")
    # Fios curtos e em duas direcoes: diagonal longa e sempre no mesmo sentido
    # cria um padrao visivel de 16 em 16 pixels quando a faixa se repete.
    for _ in range(22):
        x, y = sorteio.randrange(LADO), sorteio.randrange(LADO)
        tom = "palha_luz" if sorteio.random() < 0.55 else "palha_sombra"
        rumo = 1 if sorteio.random() < 0.5 else -1
        for passo in range(sorteio.randrange(2, 4)):
            tela.definir((x + passo) % LADO, (y + passo * rumo) % LADO, cor(tom))
    return tela


def tile_musgo() -> Tela:
    """Faixa de musgo do porao: manchas verdes sobre pedra umida."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "musgo")
    sorteio = _semeado("musgo")
    _salpicar(tela, sorteio, "grama_sombra", 30)
    _salpicar(tela, sorteio, "grama_luz", 16)
    return tela


def tile_tabua() -> Tela:
    """Faixa de tabua gasta, usada no trecho de transicao."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "madeira_luz")
    sorteio = _semeado("tabua")
    for _ in range(5):
        y = sorteio.randrange(LADO)
        retangulo(tela, 0, y, LADO, 1, "madeira")
    _salpicar(tela, sorteio, "madeira_sombra", 12)
    return tela


def tile_parede_celeiro() -> Tela:
    """Fundo da fazenda: ripado vertical de celeiro, bem dessaturado."""
    tela = Tela(LADO, LADO)
    retangulo(tela, 0, 0, LADO, LADO, "madeira_sombra")
    for x in range(0, LADO, 4):
        retangulo(tela, x, 0, 1, LADO, "tinta")
    sorteio = _semeado("parede_celeiro")
    _salpicar(tela, sorteio, "madeira", 14)
    return tela


def tile_parede_porao() -> Tela:
    """Fundo do porao: alvenaria escura, mais apagada que o chao."""
    tela = Tela(LADO, LADO)
    # Bem mais escura que a alvenaria do chao: parede de fundo que compete em
    # brilho com a plataforma confunde o que da para pisar.
    retangulo(tela, 0, 0, LADO, LADO, "ceu")
    for fiada in range(2):
        topo = fiada * 8
        retangulo(tela, 0, topo, LADO, 1, "tinta")
        retangulo(tela, 0 if fiada == 0 else 8, topo, 1, 8, "tinta")
    sorteio = _semeado("parede_porao")
    _salpicar(tela, sorteio, "pedra_sombra", 14)
    return tela


TILES = {
    "terra": tile_terra,
    "pedra": tile_pedra,
    "madeira": tile_madeira,
    "palha": tile_palha,
    "musgo": tile_musgo,
    "tabua": tile_tabua,
    "parede_celeiro": tile_parede_celeiro,
    "parede_porao": tile_parede_porao,
}
