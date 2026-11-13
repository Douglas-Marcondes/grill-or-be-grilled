"""Adornos de primeiro plano: pecas espalhadas no topo das plataformas.

Nao bloqueiam nada; quebram a monotonia do bloco liso e contam onde se esta:
fazenda, entrada do celeiro, porao.

Uma folha por regiao, todos os quadros alinhados pelo pe (tela.folha), lida por
scripts/adornos.gd. A ordem dos quadros importa: os primeiros sao os comuns
(capim, flor) e os ultimos os raros -- o peso de sorteio esta la.
"""

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA
from tela import Tela
from volume import Escultura


def _capim(altura: int = 9) -> Tela:
    """Tufo de capim, sem contorno: ele deve se fundir no gramado."""
    figura = Escultura(13, altura)
    for base, ponta in ((2, 0), (4, 3), (6, 6), (8, 9), (10, 12), (6, 4), (7, 10)):
        figura.capsula((base + 0.5, altura), (ponta + 0.5, 1 + (base * 3) % 4), 0.7, "grama",
                       borda=False, clarear=0.2 if ponta < base else -0.1)
    return figura.render(contorno=False)


def _flores() -> Tela:
    figura = Escultura(13, 10)
    for x, y, rampa in ((2.5, 4.5, "crista"), (6.5, 2.5, "ouro"), (10.5, 5.5, "pano")):
        figura.capsula((x, 10), (x, y), 0.6, "grama", borda=False)
        figura.elipse(x, y, 1.9, 1.9, rampa, borda=False)
        figura.marcar(int(x), int(y), "ouro", SOMBRA)
    return figura.render(contorno=False)


def _pedra(rampa: str = "pedra") -> Tela:
    figura = Escultura(12, 8)
    figura.elipse(4.5, 5.5, 3.6, 3.2, rampa, corte=(0, 0, 12, 7))
    figura.elipse(8.5, 5.5, 2.4, 2.2, rampa, corte=(0, 0, 12, 7))
    return figura.render()


def _abobora() -> Tela:
    """Abobora de gomos com cara de lanterna: ate a horta esta de mau humor."""
    figura = Escultura(17, 15)
    figura.capsula((8.5, 4), (9.5, 1.5), 1.0, "grama")
    for x, raio in ((4.5, 3.6), (12.5, 3.6), (8.5, 4.6)):
        figura.elipse(x, 9, raio, 4.8, "abobora")
    for x, y in ((6, 8), (11, 8), (7, 11), (8, 12), (9, 12), (10, 11)):
        figura.marcar(x, y, "abobora", CONTORNO)
    figura.marcar(6, 7, "abobora", CONTORNO)
    figura.marcar(11, 7, "abobora", CONTORNO)
    return figura.render()


def _fardo_de_feno() -> Tela:
    """Fardo retangular amarrado com duas cordas."""
    figura = Escultura(24, 15)
    figura.poligono([(2, 3), (22, 3), (22, 14), (2, 14)], "palha", claridade=0.78, queda=0.035)
    for x in range(2, 22):
        figura.marcar(x, 3, "palha", BRILHO if x % 3 else LUZ)
    figura.riscar([(4, 7), (5, 8), (10, 6), (11, 10), (14, 8), (18, 11), (19, 6), (7, 12)])
    figura.riscar([(3, 5), (12, 5), (16, 9), (20, 8)], 1)
    for x in (8, 16):
        for y in range(3, 14):
            figura.marcar(x, y, "couro", BASE if y < 6 else SOMBRA)
    return figura.render()


def _saco() -> Tela:
    """Saco de milho amarrado na boca, com remendo."""
    figura = Escultura(16, 16)
    figura.elipse(8, 10, 6.2, 5.6, "pano", corte=(0, 0, 16, 15))
    figura.capsula((8, 5), (8, 2.5), 2.4, "pano", raio_final=2.9)
    for x in range(6, 11):
        figura.marcar(x, 5, "couro", BASE)
    for x, y in ((9, 10), (10, 10), (9, 11), (10, 11)):
        figura.marcar(x, y, "crista", BASE)
    figura.riscar([(5, 12), (6, 13), (11, 8)])
    return figura.render()


def _caixote() -> Tela:
    """Caixote de ripas com travessa em X."""
    figura = Escultura(18, 18)
    figura.poligono([(1.5, 2), (16.5, 2), (16.5, 17), (1.5, 17)], "madeira", claridade=0.7,
                    queda=0.02)
    for passo in range(11):
        figura.riscar([(4 + passo, 5 + passo), (14 - passo, 5 + passo)], 1)
        figura.riscar([(4 + passo, 6 + passo), (14 - passo, 6 + passo)])
    for x in range(2, 16):
        for y, passo in ((2, 2), (3, 1), (16, -1)):
            figura.riscar([(x, y)], passo)
    for y in range(4, 16):
        figura.riscar([(2, y)], 1)
        figura.riscar([(15, y)], -1)
    for x, y in ((3, 3), (14, 3), (3, 15), (14, 15)):
        figura.marcar(x, y, "metal", LUZ)
    return figura.render()


def _barril() -> Tela:
    """Barril bojudo com dois aros de ferro."""
    figura = Escultura(16, 20)
    figura.capsula((8, 6), (8, 14), 6.0, "madeira")
    figura.poligono([(3, 1.5), (13, 1.5), (13, 4), (3, 4)], "madeira", claridade=0.9, borda=False)
    figura.poligono([(3, 16), (13, 16), (13, 19), (3, 19)], "madeira", claridade=0.3, borda=False)
    for x in (5, 8, 11):
        figura.riscar([(x, y) for y in range(3, 18)])
    for y in (5, 14):
        for x in range(2, 14):
            figura.marcar(x, y, "metal", LUZ if x < 6 else BASE if x < 11 else SOMBRA)
    return figura.render()


def _osso() -> Tela:
    figura = Escultura(15, 7)
    figura.capsula((3.5, 3.5), (11.5, 3.5), 1.1, "osso", borda=False)
    for x in (2.5, 12.5):
        for y in (2.2, 4.8):
            figura.elipse(x, y, 1.5, 1.4, "osso", borda=False)
    return figura.render()


def _casca() -> Tela:
    """Meia casca de ovo quebrada, com a borda em dente."""
    figura = Escultura(11, 8)
    figura.elipse(5.5, 3, 4.2, 4.2, "osso", corte=(0, 3, 11, 8))
    for x in (2, 4, 6, 8):
        figura.marcar(x, 2, "osso", LUZ)
    return figura.render()


def _cogumelo(largura: int, altura: int) -> Tela:
    """Cogumelo vermelho de pintas brancas."""
    figura = Escultura(largura, altura)
    meio = largura / 2.0
    chapeu = altura * 0.55
    figura.capsula((meio, altura), (meio, chapeu), largura * 0.16, "osso")
    figura.elipse(meio, chapeu, meio - 1, chapeu - 1, "cogumelo", corte=(0, 0, largura, chapeu))
    for x, y in ((0.3, 0.55), (0.6, 0.3), (0.75, 0.7)):
        figura.marcar(int(largura * x), int(chapeu * y), "osso", BRILHO)
    return figura.render()


def fazenda() -> list[Tela]:
    return [_capim(), _flores(), _pedra(), _abobora(), _fardo_de_feno()]


def entrada() -> list[Tela]:
    return [_saco(), _capim(6), _caixote(), _barril(), _pedra()]


def porao() -> list[Tela]:
    return [_osso(), _cogumelo(9, 8), _casca(), _cogumelo(15, 13), _pedra()]


REGIOES = {
    "fazenda": fazenda,
    "entrada": entrada,
    "porao": porao,
}
