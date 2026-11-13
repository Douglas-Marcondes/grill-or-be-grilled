"""As tres galinhas inimigas, cada uma com silhueta e figurino proprios.

Antes galo e atiradeira eram a galinha comum repintada. Agora a silhueta conta
o comportamento antes da cor: a galinha rasa e so brava; o Galo de Briga tem
peito estufado, cauda de foice e faixa na testa; a Atiradeira usa capacete e
cartucheira de ovos. O tom e de exercito de desenho animado -- a comida se
armou para nao virar churrasco.

Todas olham para a direita e pisam na ultima linha da tela (sprites.gd ancora
pelo pe). O ciclo de caminhada tem 4 quadros: as patas alternam, o corpo sobe
1px nos quadros de passada e a cabeca avanca junto, que e como galinha anda.
O quinto quadro e o bote: cabeca baixa, bico apontado para o heroi e cauda
empinada -- chicken_enemy.gd mostra enquanto o ataque esta sendo preparado.
"""

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA
from tela import Tela
from volume import Escultura

LARGURA = 36
ALTURA = 31
CHAO = ALTURA - 2
QUADROS_DE_PASSO = 4
QUADRO_DE_BOTE = 4
QUADROS = 5

## Por quadro: (avanco da pata de tras, avanco da pata da frente, pata erguida).
PASSOS = [(0, 0, None), (-3, 3, "tras"), (0, 0, None), (3, -3, "frente")]

ESTILOS = {
    "galinha": {"penas": "pena", "cauda": "pena", "figurino": None},
    "galo": {"penas": "pena_galo", "cauda": "pena_cauda", "figurino": "faixa"},
    "galinha_atiradeira": {"penas": "pena_caipira", "cauda": "pena_caipira",
                           "figurino": "capacete"},
}
PLUMAGENS = tuple(ESTILOS)


def galinha(quadro: int = 0, plumagem: str = "galinha") -> Tela:
    """Galinha inimiga num quadro da folha: 0 a 3 caminham, 4 e o bote.

    Exemplo: galinha(2, "galo") e o terceiro passo do Galo de Briga.
    """
    if plumagem not in ESTILOS:
        raise ValueError("plumagem desconhecida %r; esperado uma de %s"
                         % (plumagem, ", ".join(ESTILOS)))
    if not 0 <= quadro < QUADROS:
        raise ValueError("quadro de galinha fora da faixa: %d (esperado 0 a %d)"
                         % (quadro, QUADROS - 1))
    estilo = ESTILOS[plumagem]
    figura = Escultura(LARGURA, ALTURA)
    bote = quadro == QUADRO_DE_BOTE
    sobe = -1 if quadro % 2 and not bote else 0
    _patas(figura, 0 if bote else quadro, sobe)
    # No bote a cauda empina 2px e a cabeca desce 5: o corpo inteiro aponta.
    _cauda(figura, estilo, sobe - (2 if bote else 0))
    _corpo(figura, estilo["penas"], sobe)
    _cabeca(figura, estilo, 24 + (1 if quadro % 2 or bote else 0), 9 + sobe + (5 if bote else 0))
    _asa(figura, estilo["penas"], sobe, 1 if bote else quadro)
    if estilo["figurino"] == "capacete":
        _cartucheira(figura, sobe)
    return figura.render()


def _patas(figura: Escultura, quadro: int, sobe: int) -> None:
    tras, frente, erguida = PASSOS[quadro]
    _pata(figura, 13, 13 + tras, sobe, erguida == "tras")
    _pata(figura, 18, 18 + frente, sobe, erguida == "frente")


def _pata(figura: Escultura, quadril: int, pe: int, sobe: int, erguida: bool) -> None:
    """Canela fina e pe de tres dedos; a pata erguida encolhe 2px."""
    solo = CHAO - (2 if erguida else 0)
    figura.capsula((quadril, 22 + sobe), (pe, solo - 1), 0.8, "bico", borda=False,
                   clarear=0.0 if quadril > 15 else -0.3)
    for dedo in (-1, 0, 1, 2):
        figura.marcar(pe + dedo, solo, "bico", BASE if dedo else LUZ)
    figura.marcar(pe + 2, solo, "bico", SOMBRA)


def _cauda(figura: Escultura, estilo: dict, sobe: int) -> None:
    rampa = estilo["cauda"]
    if estilo["figurino"] == "faixa":
        _cauda_de_foice(figura, rampa, sobe)
        return
    for ponta, raio in (((3, 9), 2.4), ((5.5, 6), 2.2), ((8.5, 5), 1.9)):
        figura.capsula((10, 15 + sobe), (ponta[0], ponta[1] + sobe), raio, rampa,
                       raio_final=1.0)


def _cauda_de_foice(figura: Escultura, rampa: str, sobe: int) -> None:
    """Penas longas que sobem e caem em arco: a marca do galo."""
    arcos = (((9, 15), (4, 6), (0.5, 9)), ((9, 14), (6, 3), (1.5, 4)),
             ((10, 14), (9, 2), (5, 1)))
    for raiz, meio, ponta in arcos:
        figura.capsula((raiz[0], raiz[1] + sobe), (meio[0], meio[1] + sobe), 2.0, rampa,
                       raio_final=1.5)
        figura.capsula((meio[0], meio[1] + sobe), (ponta[0], ponta[1] + sobe), 1.5, rampa,
                       borda=False, raio_final=0.7)


def _corpo(figura: Escultura, penas: str, sobe: int) -> None:
    figura.elipse(15, 17.5 + sobe, 9, 7, penas)
    # Peito e pescoco numa forma so: o volume do papo e o que da o ar de
    # galinha gorda e brava.
    figura.capsula((20, 17 + sobe), (23.5, 11 + sobe), 4.8, penas, borda=False,
                   raio_final=3.8)
    figura.sombrear(14, 23 + sobe, 8, 2.5)


def _asa(figura: Escultura, penas: str, sobe: int, quadro: int) -> None:
    bate = -1 if quadro in (1, 3) else 0
    figura.elipse(13.5, 17 + sobe + bate, 5.5, 3.8, penas)
    base = 19 + sobe + bate
    figura.riscar([(10, base), (11, base + 1), (13, base), (14, base + 1),
                   (16, base), (17, base)])


def _cabeca(figura: Escultura, estilo: dict, x: int, y: int) -> None:
    if estilo["figurino"] != "capacete":
        _crista(figura, x, y, grande=estilo["figurino"] == "faixa")
    figura.elipse(x, y, 5, 4.6, estilo["penas"], borda=False)
    _barbela(figura, x, y)
    _bico(figura, x, y)
    _olho(figura, x, y)
    if estilo["figurino"] == "capacete":
        _capacete(figura, x, y)
    if estilo["figurino"] == "faixa":
        _faixa(figura, x, y)


def _crista(figura: Escultura, x: int, y: int, grande: bool) -> None:
    extra = 1.0 if grande else 0.0
    for dx, dy, rx, ry in ((-2.5, -4.6, 1.9, 2.2), (0, -5.4, 2.1, 2.6 + extra),
                           (2.6, -4.4, 1.8, 2.0 + extra * 0.5)):
        figura.elipse(x + dx, y + dy - extra * 0.5, rx, ry, "crista", borda=False)


def _barbela(figura: Escultura, x: int, y: int) -> None:
    figura.elipse(x + 3.2, y + 4.6, 1.5, 2.3, "crista")


def _bico(figura: Escultura, x: int, y: int) -> None:
    figura.poligono([(x + 3.6, y - 1.6), (x + 9, y + 0.6), (x + 3.6, y + 2.6)], "bico",
                    claridade=0.95, queda=0.22)


def _olho(figura: Escultura, x: int, y: int) -> None:
    """Olho preto com brilho e sobrancelha descendo para o bico: cara de brava."""
    for dx in (0, 1, 2):
        for dy in (-2, -1, 0):
            figura.marcar(x + dx, y + dy, "pena", BRILHO)
    for dx, dy in ((1, -1), (2, -1), (1, 0), (2, 0)):
        figura.marcar(x + dx, y + dy, "couro", CONTORNO)
    for dx, dy in ((-1, -4), (0, -4), (1, -3), (2, -3), (3, -2)):
        figura.marcar(x + dx, y + dy, "couro", CONTORNO)


def _capacete(figura: Escultura, x: int, y: int) -> None:
    """Capacete de soldado, meia cupula com aba, e a tira no queixo."""
    figura.elipse(x - 0.5, y - 1.5, 6.2, 5.6, "oliva", corte=(0, 0, LARGURA, y - 1.6))
    for dx in range(-7, 7):
        figura.marcar(x + dx, y - 2, "oliva", SOMBRA if dx < 3 else BASE)
    figura.marcar(x - 3, y - 6, "oliva", BRILHO)
    figura.marcar(x - 2, y - 6, "oliva", BRILHO)
    for dy in (-1, 0, 1, 2):
        figura.marcar(x - 3, y + dy, "couro", SOMBRA)


def _cartucheira(figura: Escultura, sobe: int) -> None:
    """Tira de couro atravessada no peito, com os ovos de municao."""
    for passo in range(10):
        x, y = 12 + passo, 13 + passo + sobe
        figura.marcar(x, y, "couro", SOMBRA)
        figura.marcar(x + 1, y, "couro", BASE)
        if passo % 3 == 1:
            figura.marcar(x + 1, y, "osso", BRILHO)
            figura.marcar(x + 1, y - 1, "osso", LUZ)


def _faixa(figura: Escultura, x: int, y: int) -> None:
    """Faixa branca de lutador na testa, com as pontas soltas para tras.
    Branca porque vermelha sumia na crista e nas penas de fogo do galo."""
    figura.capsula((x - 5, y - 4), (x - 10, y - 2), 1.0, "pano")
    figura.capsula((x - 5, y - 3), (x - 9, y + 2), 1.0, "pano")
    for dx in range(-5, 4):
        figura.marcar(x + dx, y - 5, "pano", LUZ if dx < 1 else BASE)
        figura.marcar(x + dx, y - 4, "pano", BASE if dx < 1 else SOMBRA)
    figura.marcar(x, y - 5, "crista", BASE)
