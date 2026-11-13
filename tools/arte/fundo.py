"""Camadas de parallax do fundo: fim de tarde na fazenda.

O fundo antigo era noite com silhuetas pretas -- escuro e sem graca para um
jogo comico. Agora e a hora do churrasco: ceu azul virando pessego no
horizonte, nuvens gordas, serra ao longe, celeiros vermelhos, moinho e silo
pintados em cor, colinas de plantacao e uma cerca com girassois.

Profundidade vem de nevoa, nao de preto: quanto mais longe a camada, mais ela
e puxada para a cor do ar (`_enevoar`), como em fundo pintado de arcade.

Toda faixa repete na horizontal (Parallax2D em jogo.tscn), entao nada encosta
nas bordas laterais e todo perfil ondulado usa senos de periodo inteiro.
"""

import math

from ladrilho import semeado
from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA, tom
from tela import Tela, colar
from volume import Escultura

LARGURA = 640
ALTURA_DO_CEU = 270
# Linha da tela onde a serra encontra as colinas (as camadas de jogo.tscn sao
# posicionadas em volta dela).
LINHA_DO_HORIZONTE = 178

_BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
_AR = (232, 208, 200)

## Degrade do ceu: (linha, cor). Azul no alto, creme e pessego no horizonte.
_CEU = [(0, (38, 84, 160)), (50, (70, 132, 204)), (100, (132, 190, 226)),
        (140, (214, 226, 214)), (160, (250, 226, 170)), (LINHA_DO_HORIZONTE, (250, 190, 132)),
        (ALTURA_DO_CEU, (250, 190, 132))]
_ALTURA_DA_BANDA = 7


def _cor_do_ceu(y: float) -> tuple[int, int, int, int]:
    for (y0, cor0), (y1, cor1) in zip(_CEU, _CEU[1:]):
        if y <= y1:
            mistura = (y - y0) / float(y1 - y0)
            return tuple(round(a + (b - a) * mistura) for a, b in zip(cor0, cor1)) + (255,)
    return _CEU[-1][1] + (255,)


def _pintar_degrade(tela: Tela) -> None:
    """Degrade em bandas com a emenda ditherizada: liso demais deixa de ser
    pixel art, e banda seca vira listra."""
    for y in range(tela.altura):
        banda, resto = divmod(y, _ALTURA_DA_BANDA)
        atual = _cor_do_ceu(banda * _ALTURA_DA_BANDA)
        proxima = _cor_do_ceu((banda + 1) * _ALTURA_DA_BANDA)
        limite = (resto + 1) * 16 // (_ALTURA_DA_BANDA + 1)
        for x in range(tela.largura):
            tela.definir(x, y, proxima if _BAYER[y % 4][x % 4] < limite - 4 else atual)


def _nuvem(largura: int, altura: int, nome: str) -> Tela:
    """Cumulo de base reta: varias bolhas, a de cima clara, a base rosada."""
    figura = Escultura(largura, altura)
    sorteio = semeado("nuvem/%s" % nome)
    base = altura - 2
    for indice in range(largura // 7):
        x = 8 + indice * (largura - 16) / max(1, largura // 7 - 1)
        raio = sorteio.uniform(0.45, 1.0) * altura * 0.55 * (1.0 - abs(x / largura - 0.5))
        figura.elipse(x, base - raio * 0.7, raio + 4, raio + 1, "nuvem", borda=False,
                      corte=(0, 0, largura, base), clarear=0.12)
    return figura.render(contorno=False)


def _serra(tela: Tela, base: int, altura: int, fase: float, cor_clara, cor_escura) -> None:
    """Cordilheira distante: face esquerda de cada pico no sol, direita na sombra."""
    def topo(x: int) -> float:
        angulo = 2.0 * math.pi * x / tela.largura
        return base - altura * (0.55 + 0.3 * math.sin(angulo * 3 + fase)
                                + 0.15 * abs(math.sin(angulo * 11 + fase * 2)))
    for x in range(tela.largura):
        subindo = topo(x + 2) < topo(x)
        for y in range(round(topo(x)), base):
            tela.definir(x, y, cor_clara if subindo and y < topo(x) + 9 else cor_escura)


def ceu() -> Tela:
    """Ceu de fim de tarde com nuvens e duas serras ao longe."""
    tela = Tela(LARGURA, ALTURA_DO_CEU)
    _pintar_degrade(tela)
    for x, y, largura, altura in ((20, 28, 110, 30), (190, 70, 150, 38), (400, 20, 90, 24),
                                  (470, 92, 130, 30), (300, 118, 80, 18), (60, 112, 90, 20)):
        colar(tela, _nuvem(largura, altura, "%d" % x), x, y)
    _serra(tela, LINHA_DO_HORIZONTE, 34, 0.4, (196, 190, 220, 255), (164, 166, 208, 255))
    _serra(tela, LINHA_DO_HORIZONTE, 20, 2.3, (160, 170, 190, 255), (128, 146, 176, 255))
    return tela


def sol(raio: int = 12) -> Tela:
    """Sol baixo com halo em aneis translucidos (nao repete no parallax)."""
    lado = raio * 4
    tela = Tela(lado, lado)
    centro = lado / 2.0
    for y in range(lado):
        for x in range(lado):
            distancia = math.hypot(x + 0.5 - centro, y + 0.5 - centro)
            if distancia <= raio:
                tela.definir(x, y, (255, 250, 214, 255) if distancia < raio - 2 else (255, 236, 150, 255))
            elif distancia <= raio * 2:
                anel = int((distancia - raio) / raio * 3)
                tela.definir(x, y, (255, 240, 180, (96, 56, 24)[anel]))
    return tela


# -- pecas da fazenda distante ----------------------------------------------

def _celeiro() -> Tela:
    """Celeiro vermelho de telhado quebrado, porta com X branco e janela."""
    figura = Escultura(60, 52)
    figura.poligono([(4, 26), (56, 26), (56, 50), (4, 50)], "celeiro", claridade=0.75, queda=0.012)
    figura.poligono([(2, 27), (10, 13), (22, 5), (38, 5), (50, 13), (58, 27)], "telha",
                    claridade=0.8, queda=0.02)
    figura.poligono([(12, 27), (17, 17), (25, 11), (35, 11), (43, 17), (48, 27)], "celeiro",
                    claridade=0.8, queda=0.02)
    figura.poligono([(22, 32), (38, 32), (38, 50), (22, 50)], "madeira_funda", claridade=0.7)
    for passo in range(16):
        figura.marcar(22 + passo, 33 + passo, "pano", LUZ)
        figura.marcar(37 - passo, 33 + passo, "pano", LUZ)
    for x in range(22, 39):
        figura.marcar(x, 32, "pano", BRILHO)
    figura.poligono([(27, 15), (33, 15), (33, 22), (27, 22)], "pano", claridade=0.95)
    figura.poligono([(28, 16), (32, 16), (32, 21), (28, 21)], "madeira_funda", claridade=0.4)
    for x in range(6, 56, 5):
        figura.riscar([(x, y) for y in range(29, 50)])
    return figura.render()


def _silo() -> Tela:
    figura = Escultura(22, 62)
    figura.capsula((11, 12), (11, 70), 8.5, "metal")
    figura.elipse(11, 10, 8.5, 7, "telha", corte=(0, 0, 22, 10))
    for y in (22, 34, 46, 58):
        figura.riscar([(x, y) for x in range(3, 20)])
    return figura.render()


def _moinho() -> Tela:
    """Moinho de vento: torre de madeira e quatro pas de pano em aspa."""
    figura = Escultura(60, 70)
    figura.poligono([(24, 28), (36, 28), (40, 68), (20, 68)], "madeira", claridade=0.75, queda=0.008)
    figura.poligono([(22, 29), (30, 20), (38, 29)], "telha", claridade=0.8)
    figura.poligono([(27, 54), (33, 54), (33, 68), (27, 68)], "madeira_funda", claridade=0.6)
    for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        ponta = (30 + dx * 22, 27 + dy * 22)
        figura.capsula((30, 27), ponta, 1.0, "madeira_funda")
        figura.poligono([(30 + dx * 6, 27 + dy * 6), ponta,
                         (ponta[0] - dx * 3 + dy * 5 * dx * dx, ponta[1] - dy * 3 - dx * 5 * dy * dy),
                         (30 + dx * 3 + dy * 5, 27 + dy * 3 - dx * 5)], "pano", claridade=0.85)
    figura.elipse(30, 27, 2.2, 2.2, "metal")
    return figura.render()


def _arvore(nome: str, altura: int = 44) -> Tela:
    """Arvore de copa em bolhas: tres ou quatro tufos sobrepostos."""
    figura = Escultura(40, altura)
    sorteio = semeado("arvore/%s" % nome)
    figura.capsula((20, altura - 2), (20, altura * 0.5), 2.4, "madeira", raio_final=1.6)
    for _ in range(5):
        figura.elipse(20 + sorteio.uniform(-9, 9), altura * 0.36 + sorteio.uniform(-6, 7),
                      sorteio.uniform(7, 10), sorteio.uniform(6, 8), "grama")
    return figura.render()


def _monte_de_feno() -> Tela:
    figura = Escultura(24, 16)
    figura.elipse(12, 12, 10, 10, "palha", corte=(0, 0, 24, 14))
    figura.riscar([(6, 9), (9, 6), (14, 8), (17, 11), (11, 11)])
    return figura.render()


def _arbusto(nome: str) -> Tela:
    figura = Escultura(28, 16)
    sorteio = semeado("arbusto/%s" % nome)
    for x in (7, 13, 20):
        figura.elipse(x, 11 + sorteio.uniform(-1, 1), sorteio.uniform(5, 7), sorteio.uniform(5, 6.5),
                      "grama", borda=False, corte=(0, 0, 28, 15))
    return figura.render()


def _girassol() -> Tela:
    figura = Escultura(12, 22)
    figura.capsula((6, 20), (6, 8), 0.7, "grama", borda=False)
    figura.elipse(3.5, 14, 2.2, 1.2, "grama", borda=False)
    figura.elipse(8.5, 16, 2.2, 1.2, "grama", borda=False)
    figura.elipse(6, 6, 4.6, 4.6, "ouro")
    figura.elipse(6, 6, 2.2, 2.2, "couro", borda=False)
    return figura.render()


def _enevoar(tela: Tela, quanto: float) -> Tela:
    """Puxa as cores para o tom do ar: e o que afasta a camada."""
    for y in range(tela.altura):
        for x in range(tela.largura):
            pixel = tela.ler(x, y)
            if pixel[3]:
                tela.definir(x, y, tuple(round(c + (a - c) * quanto)
                                         for c, a in zip(pixel[:3], _AR)) + (255,))
    return tela


def faixa_fazenda() -> Tela:
    """Horizonte da fazenda, alinhado pelo pe. Espacamento irregular de
    proposito: pecas a intervalos parecidos viram padrao repetido."""
    tela = Tela(LARGURA, 72)
    pecas = [(_arvore("a"), 6), (_celeiro(), 44), (_silo(), 100), (_monte_de_feno(), 128),
             (_arvore("b", 38), 158), (_moinho(), 204), (_monte_de_feno(), 270),
             (_arvore("c"), 300), (_arvore("d", 36), 326), (_celeiro(), 380),
             (_monte_de_feno(), 446), (_moinho(), 474), (_silo(), 540), (_silo(), 560),
             (_arvore("e"), 594)]
    for peca, x in pecas:
        colar(tela, peca, x, tela.altura - peca.altura)
    return _enevoar(tela, 0.48)


def _perfil(x: int, base: float, ondas: tuple[tuple[int, float, float], ...]) -> int:
    angulo = 2.0 * math.pi * x / LARGURA
    return round(base + sum(amplitude * math.sin(angulo * periodo + fase)
                            for periodo, amplitude, fase in ondas))


def faixa_colinas(altura: int = 110) -> Tela:
    """Duas colinas de plantacao descendo ate o rodape: fecham o vazio que
    aparecia em todo buraco da fase. A de tras e clara e enevoada; a da frente
    tem fileiras de lavoura e escurece para baixo."""
    tela = Tela(LARGURA, altura)
    for x in range(LARGURA):
        tras = _perfil(x, 8, ((2, 5, 0.0), (5, 2.5, 1.3)))
        frente = _perfil(x, 26, ((3, 6, 2.0), (7, 2, 0.5)))
        for y in range(tras, altura):
            tela.definir(x, y, _tom_da_colina(x, y, tras, frente))
    return tela


def _na_banda(x: int, y: int, fundura: int, inicio: int, largura: int = 8) -> bool:
    """Passou da linha `inicio`? A transicao e ditherizada so em `largura`
    linhas -- dither na colina inteira virava chuvisco."""
    if fundura < inicio:
        return False
    return fundura >= inicio + largura or _BAYER[y % 4][x % 4] < (fundura - inicio) * 16 // largura


def _tom_da_colina(x: int, y: int, tras: int, frente: int) -> tuple[int, int, int, int]:
    if y < frente:
        fundura = y - tras
        nivel = BRILHO if fundura < 2 else LUZ if fundura < 9 or (x + y * 2) % 14 < 2 else BASE
        return tom("colina", nivel)
    fundura = y - frente
    if fundura < 2:
        return tom("colina_perto", LUZ)
    if _na_banda(x, y, fundura, 62):
        return tom("colina_perto", CONTORNO)
    lavoura = (x + fundura * 3) % 16 < 2
    if _na_banda(x, y, fundura, 26) or lavoura:
        return tom("colina_perto", SOMBRA)
    return tom("colina_perto", BASE)


def faixa_cerca() -> Tela:
    """Camada do meio: cerca de madeira com arbustos e girassois na frente."""
    altura = 34
    tela = Tela(LARGURA, altura)
    colar(tela, _cerca(), 0, altura - 20)
    sorteio = semeado("cerca")
    for indice in range(11):
        x = 10 + indice * 57 + sorteio.randrange(-12, 12)
        if indice % 3 == 1:
            for passo in range(sorteio.randrange(2, 4)):
                colar(tela, _girassol(), x + passo * 9, altura - 22 + passo % 2 * 2)
        else:
            colar(tela, _arbusto("%d" % indice), x, altura - 16)
    return _enevoar(tela, 0.22)


def _cerca() -> Tela:
    """Mouroes a cada 20px e duas travessas, com a quina de cima no sol."""
    figura = Escultura(LARGURA, 20)
    for y in (6, 12):
        figura.poligono([(0, y), (LARGURA, y), (LARGURA, y + 3), (0, y + 3)], "madeira",
                        claridade=0.7, queda=0.14, borda=False)
    for x in range(4, LARGURA, 20):
        figura.poligono([(x, 3), (x + 2, 1), (x + 4, 3), (x + 4, 20), (x, 20)], "madeira",
                        claridade=0.8, queda=0.025)
        figura.marcar(x + 1, 3, "madeira", BRILHO)
    return figura.render()


CAMADAS = {
    "ceu": ceu,
    "fazenda": faixa_fazenda,
    "colinas": faixa_colinas,
    "cerca": faixa_cerca,
    "sol": sol,
}
