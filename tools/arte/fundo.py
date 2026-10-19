"""Camadas de parallax do fundo: ceu noturno e silhuetas da fazenda.

Silhueta e construida geometricamente (telhado, torre, tronco) em vez de ASCII
art porque a faixa tem centenas de pixels de largura -- desenhar isso a mao em
texto seria ilegivel em diff. Os dois tons escuros existem para dar volume sem
competir com o primeiro plano: o fundo tem que ler como recorte contra o ceu.

Toda faixa e desenhada para repetir na horizontal (motion_mirroring no Godot),
entao nada encosta nas bordas laterais.
"""

import random

from paleta import cor
from tela import Tela, colar, retangulo

LARGURA_FAIXA = 320


def _semeado(nome: str) -> random.Random:
    return random.Random("grill-or-be-grilled/fundo/%s" % nome)


def _telhado(tela: Tela, x: int, y: int, largura: int, altura: int, tom: str) -> None:
    """Telhado trapezoidal: encolhe a cada linha subindo ate virar cumeeira."""
    for linha in range(altura):
        recuo = int(largura / 2.0 * linha / float(altura))
        retangulo(tela, x + recuo, y + altura - 1 - linha,
                  max(1, largura - recuo * 2), 1, tom)


def celeiro(tom: str = "silhueta", tom_luz: str = "janela_acesa") -> Tela:
    """Celeiro com telhado em duas aguas, porta e janelas acesas.

    As janelas em ambar sao o unico ponto quente do fundo: dao sinal de vida a
    fazenda e ancoram o olho no horizonte sem disputar com o primeiro plano."""
    largura, corpo_altura, telhado_altura = 46, 26, 14
    tela = Tela(largura, corpo_altura + telhado_altura + 4)
    base = telhado_altura + 4
    retangulo(tela, 0, base, largura, corpo_altura, tom)
    _telhado(tela, 0, 4, largura, telhado_altura, tom)
    retangulo(tela, largura // 2 - 3, 0, 6, 5, tom)          # lucarna
    retangulo(tela, largura // 2 - 6, base + 10, 12, 16, tom_luz)  # porta
    retangulo(tela, 6, base + 4, 5, 5, tom_luz)              # janelas
    retangulo(tela, largura - 11, base + 4, 5, 5, tom_luz)
    return tela


def silo(tom: str = "silhueta") -> Tela:
    """Silo cilindrico com cupula, mais alto que o celeiro."""
    largura, altura = 16, 54
    tela = Tela(largura, altura)
    retangulo(tela, 0, 8, largura, altura - 8, tom)
    for linha in range(8):
        recuo = int(largura / 2.0 * (7 - linha) / 8.0)
        retangulo(tela, recuo, linha, max(1, largura - recuo * 2), 1, tom)
    return tela


def moinho(tom: str = "silhueta") -> Tela:
    """Torre de moinho com as quatro pas em aspa."""
    largura, altura = 34, 62
    tela = Tela(largura, altura)
    centro, torre_topo = largura // 2, 22
    for linha in range(altura - torre_topo):
        meia = 3 + int(5 * linha / float(altura - torre_topo))
        retangulo(tela, centro - meia, torre_topo + linha, meia * 2, 1, tom)
    # Pa de 2px: com 1px a aspa desaparece na distancia do parallax.
    for passo in range(16):
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            x = centro + dx * passo
            y = torre_topo - 2 + dy * passo
            tela.definir(x, y, cor(tom))
            tela.definir(x, y + 1, cor(tom))
    return tela


def _galho(tela: Tela, x: int, y: int, rumo: int, passos: int, tom: str) -> None:
    """Galho que sobe afastando-se do tronco, engrossado em 2px na base."""
    for passo in range(passos):
        altura_galho = y - passo
        tela.definir(x + rumo * passo, altura_galho, cor(tom))
        if passo < passos // 2:
            tela.definir(x + rumo * passo, altura_galho + 1, cor(tom))


def arvore_seca(tom: str = "silhueta") -> Tela:
    """Arvore sem folhas, com copa cheia o bastante para ler como arvore.

    A primeira versao tinha dois galhos finos e lia como antena de TV: o que
    resolve e tronco mais grosso e varios galhos em alturas diferentes.
    """
    largura, altura = 26, 40
    tela = Tela(largura, altura)
    centro = largura // 2
    retangulo(tela, centro - 2, 14, 4, altura - 14, tom)
    retangulo(tela, centro - 4, altura - 3, 8, 3, tom)           # raiz alargada
    # Galhos sorteados: comprimento e altura iguais dos dois lados davam uma
    # simetria de candelabro, nao de arvore.
    sorteio = _semeado("arvore")
    for base in (21, 17, 13, 9, 6):
        for rumo in (-1, 1):
            if sorteio.random() < 0.15:
                continue
            _galho(tela, centro, base + sorteio.randrange(-1, 2), rumo,
                   sorteio.randrange(4, 10), tom)
    return tela


def arbusto(tom: str = "silhueta") -> Tela:
    largura, altura = 18, 10
    tela = Tela(largura, altura)
    for linha in range(altura):
        recuo = int(largura / 2.0 * (altura - 1 - linha) / (altura * 1.6))
        retangulo(tela, recuo, linha, largura - recuo * 2, 1, tom)
    return tela


def cerca(largura: int = LARGURA_FAIXA, tom: str = "silhueta_perto") -> Tela:
    """Cerca de madeira com montantes e duas travessas."""
    altura = 16
    tela = Tela(largura, altura)
    retangulo(tela, 0, 4, largura, 2, tom)
    retangulo(tela, 0, 10, largura, 2, tom)
    for x in range(2, largura, 18):
        retangulo(tela, x, 0, 3, altura, tom)
    return tela


def faixa_silhueta(largura: int = LARGURA_FAIXA) -> Tela:
    """Horizonte distante da fazenda, alinhado pelo pe da faixa."""
    altura = 72
    tela = Tela(largura, altura)
    pecas = [
        (arvore_seca(), 4),
        (celeiro(), 42),
        (silo(), 94),
        (arvore_seca(), 120),
        (moinho(), 158),
        (arbusto(), 202),
        (celeiro(), 226),
        (arvore_seca(), 288),
    ]
    for peca, x in pecas:
        colar(tela, peca, x, altura - peca.altura)
    return tela


def faixa_cerca(largura: int = LARGURA_FAIXA) -> Tela:
    """Camada media: cerca com arbustos na frente."""
    altura = 24
    tela = Tela(largura, altura)
    colar(tela, cerca(largura), 0, altura - 16)
    sorteio = _semeado("cerca")
    for _ in range(7):
        colar(tela, arbusto("silhueta_perto"), sorteio.randrange(largura - 18),
              altura - 10)
    return tela


# Matriz de Bayer 4x4: usada para misturar duas cores vizinhas do degrade sem
# inventar tons fora da paleta DB32. Faixa chapada deixa emenda dura visivel.
BAYER_4 = (
    (0, 8, 2, 10),
    (12, 4, 14, 6),
    (3, 11, 1, 9),
    (15, 7, 13, 5),
)


def _dither(tela: Tela, y: int, largura: int, tom_a: str, tom_b: str,
            mistura: float) -> None:
    """Pinta uma linha misturando dois tons na proporcao dada."""
    limite = mistura * 16.0
    for x in range(largura):
        escolhido = tom_b if BAYER_4[y % 4][x % 4] < limite else tom_a
        tela.definir(x, y, cor(escolhido))


def _degrade(tela: Tela, largura: int, altura: int, faixas: list[str]) -> None:
    """Degrade vertical com transicao ditherizada entre faixas vizinhas."""
    passos = len(faixas) - 1
    for y in range(altura):
        posicao = y / float(altura) * passos
        indice = min(int(posicao), passos - 1)
        _dither(tela, y, largura, faixas[indice], faixas[indice + 1],
                posicao - indice)


# Linha da tela onde fica o horizonte do jogo (o chao do mundo aparece por volta
# dela). O degrade tem de terminar aqui: se a bruma clara so chegar no rodape, a
# silhueta escura dos celeiros cai sobre ceu escuro e nao le como recorte.
LINHA_DO_HORIZONTE = 120


def ceu(largura: int = LARGURA_FAIXA, altura: int = 270) -> Tela:
    """Ceu noturno: degrade ditherizado ate o horizonte, mais estrelas."""
    tela = Tela(largura, altura)
    _degrade(tela, largura, LINHA_DO_HORIZONTE, ["ceu_alto", "ceu", "bruma"])
    retangulo(tela, 0, LINHA_DO_HORIZONTE, largura,
              altura - LINHA_DO_HORIZONTE, "bruma")
    sorteio = _semeado("estrelas")
    for _ in range(46):
        x, y = sorteio.randrange(largura), sorteio.randrange(LINHA_DO_HORIZONTE)
        tela.definir(x, y, cor("luar" if sorteio.random() < 0.3 else "luar_fraco"))
    return tela


def lua(raio: int = 11) -> Tela:
    """Lua cheia com uma cratera, desenhada uma vez (nao repete no parallax)."""
    lado = raio * 2 + 2
    tela = Tela(lado, lado)
    centro = lado // 2
    for y in range(lado):
        for x in range(lado):
            distancia = (x - centro) ** 2 + (y - centro) ** 2
            if distancia <= raio * raio:
                tom = "luar" if distancia < (raio - 2) ** 2 else "luar_fraco"
                tela.definir(x, y, cor(tom))
    for dx, dy in ((-3, -2), (-2, -2), (-3, -1), (2, 3), (3, 3), (1, -4)):
        tela.definir(centro + dx, centro + dy, cor("luar_fraco"))
    return tela


CAMADAS = {
    "ceu": ceu,
    "silhueta": faixa_silhueta,
    "cerca": faixa_cerca,
    "lua": lua,
}
