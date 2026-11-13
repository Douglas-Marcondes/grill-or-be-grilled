"""Galinha Real: a chefe da fase 1, gorda, coroada e de capa.

Segue a linguagem das galinhas comuns (galinhas.py) em escala de chefe, e o
figurino e o que diz "rainha": coroa de ouro com pedras, capa vermelha de
arminho e um olhar de quem nunca foi contrariada. Tem o tamanho do proprio
colisor (chicken_boss.gd) para o jogador ler o que pode acerta-lo.

Dois quadros que respiram: o corpo incha 1px e a cabeca sobe.
"""

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA
from tela import Tela
from volume import Escultura

LARGURA = 62
ALTURA = 58
CHAO = ALTURA - 2
QUADROS = 2


def galinha_real(quadro: int = 0) -> Tela:
    """Galinha Real num dos dois quadros de respiracao.

    Exemplo: galinha_real(1) e o quadro de peito cheio.
    """
    if not 0 <= quadro < QUADROS:
        raise ValueError("quadro da Galinha Real invalido: %d (esperado 0 ou 1)" % quadro)
    figura = Escultura(LARGURA, ALTURA)
    folego = quadro % 2
    _patas(figura)
    _cauda(figura, folego)
    _capa(figura, folego)
    _corpo(figura, folego)
    _asa(figura, folego)
    _cabeca(figura, 43, 17 - folego)
    return figura.render()


def _patas(figura: Escultura) -> None:
    for x, escuro in ((22, -0.3), (33, 0.0)):
        figura.capsula((x, 44), (x, CHAO - 1), 1.7, "bico", borda=False, clarear=escuro)
        for dedo in range(-3, 5):
            figura.marcar(x + dedo, CHAO, "bico", LUZ if dedo < 1 else BASE)
            figura.marcar(x + dedo, CHAO - 1, "bico", BASE if abs(dedo) < 2 else SOMBRA)


def _cauda(figura: Escultura, folego: int) -> None:
    """Leque de quatro plumas grandes, abrindo para cima e para tras."""
    for ponta, raio in (((2, 24), 4.0), ((4, 15), 4.2), ((9, 9), 4.0), ((16, 7), 3.4)):
        figura.capsula((17, 32 - folego), ponta, raio, "pena", raio_final=1.6)
        figura.riscar([(int(ponta[0]) + 2, int(ponta[1]) + 2),
                       (int(ponta[0]) + 3, int(ponta[1]) + 4)])


def _capa(figura: Escultura, folego: int) -> None:
    """Capa vermelha dos ombros ate o chao, com barra de arminho pintado."""
    y = -folego
    figura.poligono([(34, 22 + y), (40, 26 + y), (22, 30 + y), (9, 44), (5, 51), (20, 51),
                     (16, 36 + y)], "crista", claridade=0.72, queda=0.012)
    figura.riscar([(12, 46), (13, 44), (14, 42), (17, 46), (17, 44), (19, 39), (20, 37)])
    figura.poligono([(5, 49), (20, 49), (21, 53), (4, 53)], "pano", claridade=0.9, queda=0.1)
    for x in (7, 11, 15, 18):
        figura.marcar(x, 51, "pano", CONTORNO)


def _corpo(figura: Escultura, folego: int) -> None:
    figura.elipse(27, 34 - folego * 0.5, 18, 14 + folego * 0.5, "pena")
    figura.capsula((37, 32), (42, 24 - folego), 9.5, "pena", borda=False, raio_final=7.5)
    figura.sombrear(27, 46, 15, 4)
    # Gola de arminho fechando a capa no pescoco.
    figura.capsula((35, 25 - folego), (47, 27 - folego), 2.2, "pano")
    for x in (37, 41, 45):
        figura.marcar(x, 26 - folego, "pano", CONTORNO)
    figura.elipse(48, 28 - folego, 1.8, 1.8, "ouro")


def _asa(figura: Escultura, folego: int) -> None:
    y = 35 - folego
    figura.elipse(26, y, 10.5, 7, "pena")
    for x in (18, 22, 26, 30, 34):
        figura.riscar([(x, y + 4), (x + 1, y + 5), (x + 1, y + 3)])


def _cabeca(figura: Escultura, x: int, y: int) -> None:
    for dx, dy, rx, ry in ((-6, -7, 2.6, 3), (5.5, -6.5, 2.4, 2.8)):
        figura.elipse(x + dx, y + dy, rx, ry, "crista", borda=False)
    figura.elipse(x, y, 8.6, 8, "pena", borda=False)
    figura.elipse(x + 6, y + 8.5, 2.6, 4.2, "crista")
    figura.poligono([(x + 6, y - 2), (x + 15, y + 2), (x + 6, y + 5)], "bico",
                    claridade=0.95, queda=0.12)
    figura.riscar([(x + dx, y + 2) for dx in range(7, 13)], -2)
    _olhar(figura, x, y)
    _coroa(figura, x, y - 7)


def _olhar(figura: Escultura, x: int, y: int) -> None:
    """Olho grande de palpebra caida e sobrancelha grossa: desprezo real."""
    for dx in range(1, 6):
        for dy in range(-3, 2):
            figura.marcar(x + dx, y + dy, "pena", BRILHO)
    for dx, dy in ((3, -1), (4, -1), (3, 0), (4, 0), (3, 1), (4, 1)):
        figura.marcar(x + dx, y + dy, "couro", CONTORNO)
    figura.marcar(x + 3, y - 1, "pena", BRILHO)
    for dx in range(0, 7):
        altura = y - 5 + dx // 2
        figura.marcar(x + dx, altura, "couro", CONTORNO)
        figura.marcar(x + dx, altura + 1, "roxo" if dx < 6 else "couro", BASE if dx < 6 else CONTORNO)


def _coroa(figura: Escultura, x: int, y: int) -> None:
    """Coroa de tres pontas com pedra em cada uma, torta para tras."""
    figura.poligono([(x - 6, y + 1), (x + 5, y + 2), (x + 6, y - 7), (x + 3, y - 3),
                     (x, y - 9), (x - 3, y - 4), (x - 7, y - 8)], "ouro",
                    claridade=0.9, queda=0.035)
    for dx in range(-5, 5):
        figura.marcar(x + dx, y, "ouro", SOMBRA)
    for dx, dy, rampa in ((-6, -8, "crista"), (0, -9, "azul"), (5, -7, "crista"), (0, -2, "magia")):
        figura.marcar(x + dx, y + dy, rampa, LUZ)
    figura.marcar(x - 2, y - 4, "ouro", BRILHO)
