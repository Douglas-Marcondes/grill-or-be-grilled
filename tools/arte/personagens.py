"""Sprites dos personagens, desenhados pixel a pixel como ASCII art.

A galinha e um redesenho ampliado da arte original de Artes/GalinhaAndando*.png:
mesma silhueta (corpo oval, cauda erguida, crista de tres bicos, bico e barbela)
e mesma leitura, so que em resolucao maior e com sombra, para caber na escala do
jogo sem perder a identidade que Douglas e Jorge ja tinham definido.

Corpo e pernas sao desenhados separados e compostos: o ciclo de caminhada muda
so a posicao das pernas, entao escrever quatro corpos inteiros seria repetir a
mesma arte quatro vezes (e quadruplicar o custo de qualquer ajuste).
"""

from tela import (Tela, colar, contornar, de_ascii, oval, pintar, retangulo,
                  sombrear_abaixo)

# Mapa comum: minuscula e sombra, maiuscula e luz.
PENAS = {
    "o": "tinta",
    "W": "pena_luz",
    "w": "pena",
    "s": "pena_sombra",
    "c": "crista",
    "C": "crista_luz",
    "b": "bico",
    "B": "bico_sombra",
    "e": "tinta",
}

CORPO_GALINHA = [
    "...............c.c.c......",
    "..............ccCcCcc.....",
    "..............occccco.....",
    ".............oWWWWWWWWo...",
    "...oo......oWWWWWWWWWWo...",
    "..oWWo.....oWWWWWWWeWWobb.",
    "..oWWWo....oWWWWWWWeWWoBbb",
    ".oWWWWWo...oWWWWWWWWWWoBb.",
    ".oWWWWWWo..oWWWWWWWWWWWoc.",
    ".oWWWWWWWWooWWWWWWWWWWWoc.",
    "..oWWWWWWWWWWWWWWWWWWWWo..",
    "..oWWWWWWWWWWWWWWWWWWWo...",
    "...owWWWWWWWWWWWWWWWWWo...",
    "....owwWWWWWWWWWWWWWo.....",
    ".....osswWWWWWWWWWWo......",
    "......ossssWWWWWWWo.......",
    ".......ooooooooooo........",
]

# Pernas desenhadas a parte; o ciclo so desloca cada pata na horizontal.
PERNA = ["b", "b", "b", "b"]
PE = ["bbb"]

## Deslocamento (pata de tras, pata da frente) por quadro do ciclo de caminhada.
PASSOS_GALINHA = [(0, 0), (3, -1), (0, 0), (-1, 3)]


def _pata(tela: Tela, x: int, y: int) -> None:
    pintar(tela, x, y, PERNA, {"b": "bico"})
    pintar(tela, x - 1, y + len(PERNA), PE, {"b": "bico_sombra"})


def galinha(quadro: int = 0) -> Tela:
    """Galinha inimiga num quadro do ciclo de caminhada (0 a 3)."""
    if not 0 <= quadro < len(PASSOS_GALINHA):
        raise ValueError(
            "quadro de galinha fora da faixa: %d (esperado 0 a %d)"
            % (quadro, len(PASSOS_GALINHA) - 1)
        )
    corpo = de_ascii(CORPO_GALINHA, PENAS)
    tela = Tela(corpo.largura, corpo.altura + 6)
    # Quadros impares levantam o corpo em 1px: o leve sobe-desce e o que faz a
    # caminhada parecer peso, nao deslizamento.
    altura_corpo = 1 if quadro % 2 else 0
    colar(tela, corpo, 0, altura_corpo)
    atras, frente = PASSOS_GALINHA[quadro]
    _pata(tela, 8 + atras, corpo.altura + altura_corpo - 1)
    _pata(tela, 15 + frente, corpo.altura + altura_corpo - 1)
    return tela


## A Galinha Real e construida com primitivas, nao com ASCII art: ela precisa
## ter o tamanho do proprio colisor (cerca de 40x46) e, nessa escala, curva
## desenhada contando caractere sai irregular.
LARGURA_BOSS = 44
ALTURA_BOSS = 46


def _crista_real(tela: Tela, centro_x: int, base_y: int) -> None:
    """Crista de cinco bicos: o que distingue a Rainha da galinha comum.

    Os bicos se apoiam numa base continua -- desenhados soltos, o contorno cerca
    cada um e a crista vira cinco blocos vermelhos flutuando.
    """
    retangulo(tela, centro_x - 9, base_y - 3, 19, 4, "crista")
    for indice, altura in enumerate((4, 7, 9, 7, 4)):
        x = centro_x - 9 + indice * 4
        retangulo(tela, x, base_y - altura, 4, altura, "crista")
        retangulo(tela, x, base_y - altura, 4, 2, "crista_luz")


def _bico_real(tela: Tela, x: int, y: int) -> None:
    for linha in range(5):
        largura = 7 - abs(linha - 2) * 2
        retangulo(tela, x, y + linha, largura, 1,
                  "bico" if linha < 3 else "bico_sombra")


def _barbela(tela: Tela, x: int, y: int) -> None:
    oval(tela, x, y, 3, 5, "crista")
    oval(tela, x - 1, y - 1, 2, 3, "crista_luz")


def _pluma(tela: Tela, x: int, y: int, comprimento: int, inclinacao: float,
           grossura: int) -> None:
    """Pluma que afina ate a ponta, saindo da garupa para cima e para TRAS.

    A cauda cresce no sentido -X: somando em X ela entrava no corpo e sumia.
    """
    for passo in range(comprimento):
        espessura = max(1, grossura - passo * grossura // comprimento)
        retangulo(tela, x - int(passo * 0.5), y - int(passo * inclinacao),
                  espessura, espessura, "pena_luz")


def _cauda_real(tela: Tela, x: int, y: int) -> None:
    """Tres plumas em leque, afinando na ponta, para cima e para tras."""
    for comprimento, inclinacao, grossura in ((16, 1.0, 5), (20, 0.65, 6),
                                              (17, 0.25, 5)):
        _pluma(tela, x, y, comprimento, inclinacao, grossura)


def galinha_real(quadro: int = 0) -> Tela:
    """Galinha Real: a mesma linguagem visual da galinha comum, em escala de
    chefe -- corpo mais pesado, crista de cinco bicos e cauda em leque."""
    tela = Tela(LARGURA_BOSS, ALTURA_BOSS)
    # Quadros alternados respiram 1px, igual a galinha comum.
    respiro = 1 if quadro % 2 else 0
    _cauda_real(tela, 14, 30 + respiro)
    oval(tela, 22, 28 + respiro, 16, 11, "pena_luz")     # corpo
    oval(tela, 29, 15 + respiro, 9, 9, "pena_luz")       # cabeca
    sombrear_abaixo(tela, 31 + respiro, "pena_luz", "pena")
    sombrear_abaixo(tela, 36 + respiro, "pena", "pena_sombra")
    _crista_real(tela, 29, 7 + respiro)
    _bico_real(tela, 38, 14 + respiro)
    _barbela(tela, 36, 23 + respiro)
    retangulo(tela, 32, 13 + respiro, 2, 3, "tinta")
    contornar(tela, "tinta")
    _pata_real(tela, 16, 38 + respiro)
    _pata_real(tela, 26, 38 + respiro)
    return tela


def _pata_real(tela: Tela, x: int, y: int) -> None:
    retangulo(tela, x, y, 3, ALTURA_BOSS - y - 2, "bico")
    retangulo(tela, x - 2, ALTURA_BOSS - 2, 7, 2, "bico_sombra")


# Jogador: o 't' e a cor da tunica, trocada por classe, e o 'h' o chapeu.
HEROI = {
    "o": "tinta",
    "P": "pele",
    "p": "pele_sombra",
    "e": "tinta",
    "T": "tunica_luz",
    "t": "tunica",
    "u": "tunica_sombra",
    "L": "madeira_sombra",
    "l": "tinta",
    "h": "chapeu",
    "H": "chapeu_luz",
    "B": "madeira",
}

CORPO_HEROI = [
    "......oooooo......",
    ".....ohhhhhho.....",
    "....oHHHHHHHHo....",
    "....oooooooooo....",
    ".....oPPPPPPo.....",
    ".....oPePPePo.....",
    ".....oPPPPPPo.....",
    ".....opPPPPpo.....",
    "......oPPPPo......",
    "......oooooo......",
    ".....ottttto......",
    "....otTTTTTTo.....",
    "...oPotTTTTTToPo..",
    "...oPotTTTTTToPo..",
    "...oPotTTTTTToPo..",
    "...ooootTTTTToooo.",
    "......ouuuuuo.....",
    "......oLLLLLo.....",
    "......oLLLLLo.....",
    "......oLLoLLo.....",
    "......oLLoLLo.....",
    "......oLLoLLo.....",
    "......oLLoLLo.....",
    "......oLLoLLo.....",
    ".....oBBBoBBBo....",
    ".....ooooooooo....",
]

## Pernas do heroi sao parte do corpo; a caminhada desloca so as duas colunas
## de baixo, entao o ciclo e feito recortando e recolando essa faixa.
LINHA_DAS_PERNAS = 19
PASSOS_HEROI = [(0, 0), (1, -1), (0, 0), (-1, 1)]


def heroi(classe: str = "Guerreiro", quadro: int = 0) -> Tela:
    """Heroi de uma das tres classes, num quadro do ciclo de caminhada."""
    # HEROI mapeia caractere -> papel; a classe mapeia papel -> cor DB32. O
    # sprite e o mesmo desenho com a tunica e o chapeu repintados.
    cores = _cores_da_classe(classe)
    mapa = {letra: cores.get(papel, papel) for letra, papel in HEROI.items()}
    inteiro = de_ascii(CORPO_HEROI, mapa)
    tela = Tela(inteiro.largura, inteiro.altura)
    altura_corpo = 1 if quadro % 2 else 0
    for y in range(LINHA_DAS_PERNAS):
        for x in range(inteiro.largura):
            tela.definir(x, y + altura_corpo, inteiro.ler(x, y))
    atras, frente = PASSOS_HEROI[quadro]
    _mover_faixa(tela, inteiro, LINHA_DAS_PERNAS, 0, 9, atras)
    _mover_faixa(tela, inteiro, LINHA_DAS_PERNAS, 9, inteiro.largura, frente)
    return tela


def _mover_faixa(destino: Tela, origem: Tela, linha: int, x_inicio: int,
                 x_fim: int, deslocamento: int) -> None:
    """Copia uma faixa horizontal da origem deslocada no eixo X."""
    for y in range(linha, origem.altura):
        for x in range(x_inicio, x_fim):
            pixel = origem.ler(x, y)
            if pixel[3]:
                destino.definir(x + deslocamento, y, pixel)


CORES_POR_CLASSE = {
    "Guerreiro": {"tunica": "azul_petroleo", "tunica_luz": "azul_claro",
                  "tunica_sombra": "azul_escuro", "chapeu": "vermelho",
                  "chapeu_luz": "rosa_vermelho"},
    "Arqueiro": {"tunica": "verde_musgo", "tunica_luz": "verde",
                 "tunica_sombra": "oliva", "chapeu": "verde_agua",
                 "chapeu_luz": "verde_limao"},
    "Mago": {"tunica": "roxo", "tunica_luz": "rosa",
             "tunica_sombra": "vinho", "chapeu": "azul_escuro",
             "chapeu_luz": "azul"},
}


def _cores_da_classe(classe: str) -> dict[str, str]:
    if classe not in CORES_POR_CLASSE:
        raise ValueError(
            "classe desconhecida: %r (esperado uma de %s)"
            % (classe, ", ".join(CORES_POR_CLASSE))
        )
    return CORES_POR_CLASSE[classe]


OVO = [
    "..ooo..",
    ".oCCco.",
    "oCCccco",
    "oCcccco",
    "occccco",
    "occccco",
    ".occco.",
    "..ooo..",
]

## Uma cor por raridade, na ordem usada por egg_pickup.gd.
CORES_DE_OVO = ["creme", "verde_agua", "azul_claro", "rosa", "amarelo"]


def ovo(raridade: int = 0) -> Tela:
    """Ovo coletavel de uma das cinco raridades."""
    if not 0 <= raridade < len(CORES_DE_OVO):
        raise ValueError(
            "raridade de ovo invalida: %d (esperado 0 a %d)"
            % (raridade, len(CORES_DE_OVO) - 1)
        )
    tom = CORES_DE_OVO[raridade]
    return de_ascii(OVO, {"o": "tinta", "C": "branco", "c": tom})


# Armas: sprites proprios, filhos do heroi, para que trocar de arma na loja nao
# exija redesenhar o personagem inteiro (a mesma separacao que o codigo ja fazia
# quando o jogador era desenhado por draw_rect).
ARMAS = {
    "Espada": [
        "....................",
        ".........oooooooooo.",
        "..ooooooommmmmmmmmo.",
        ".oMMMMoooAAAAAAAAAo.",
        "..ooooooommmmmmmmmo.",
        ".........oooooooooo.",
        "....................",
    ],
    "Arco": [
        ".ooo..",
        ".oAAo.",
        "..oAAo",
        ".e.oAo",
        "e..oAo",
        ".e.oAo",
        "..oAAo",
        ".oAAo.",
        ".ooo..",
    ],
    "Varinha": [
        "........ooo..",
        "oooooooooGGo.",
        "oMMMMMMMoGGo.",
        "oooooooooGGo.",
        "........ooo..",
    ],
}

CORES_DE_ARMA = {
    "o": "tinta",
    "m": "aco",
    "A": "aco_luz",
    "M": "madeira_luz",
    "e": "palha_luz",
    "G": "magia_luz",
}


def arma(nome: str) -> Tela:
    """Sprite da arma equipada, voltado para a direita."""
    if nome not in ARMAS:
        raise ValueError(
            "arma desconhecida: %r (esperado uma de %s)"
            % (nome, ", ".join(ARMAS))
        )
    return de_ascii(ARMAS[nome], CORES_DE_ARMA)


# Armadura cômica dropada pela Galinha Real: crista e barbela vestidas na cabeca
# do heroi. Fica numa folha propria para ser sobreposta a qualquer classe.
ARMADURA_GALINHA = [
    "......c.c.c.......",
    ".....ccCcCcc......",
    ".....occcccco.....",
    "......oooooo......",
]


def armadura_galinha() -> Tela:
    """Crista de galinha usada como elmo pelo heroi."""
    return de_ascii(ARMADURA_GALINHA, PENAS)
