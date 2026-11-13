"""Adereços do cenario: tocha de chama animada, poste, braseiro e halo.

O halo e um sprite aditivo, nao um Light2D. Numa cena com 33 tochas isso evita
depender do suporte de luz 2D do renderizador GL Compatibility e da controle
exato do raio. Ele e feito de aneis translucidos: de dia quase some contra o
ceu claro, e no porao escuro e o que faz a tocha parecer acesa.

As medidas do poste e do castical sao lidas por scripts/tochas.gd
(ALTURA_DO_POSTE, ALTURA_DO_CASTICAL, LARGURA_DO_POSTE).
"""

import math

from rampas import BASE, LUZ, tom
from tela import Tela
from volume import Escultura

POSTE_ALTURA = 34
POSTE_LARGURA = 7
CASTICAL_ALTURA = 10
QUADROS_DE_CHAMA = 4

## Por quadro: (desvio da ponta em x, altura). A ponta danca e a altura pulsa,
## que e o que faz fogo parecer fogo em vez de triangulo piscando.
_DANCA = [(0.0, 12.0), (-1.5, 10.5), (0.5, 12.5), (1.5, 10.0)]
## Camadas da chama, de fora para dentro: (escala, claridade chapada).
_CAMADAS = [(1.0, 0.2), (0.74, 0.5), (0.5, 0.75), (0.26, 1.0)]


def _gota(centro: float, base: float, largura: float, altura: float,
          desvio: float) -> list[tuple[float, float]]:
    """Contorno de uma labareda: bojo redondo embaixo, ponta fina em cima."""
    bojo = altura * 0.34
    pontos = [(centro + desvio, base - altura)]
    for passo in range(9):
        angulo = math.pi * passo / 8.0
        pontos.append((centro + largura * math.cos(angulo),
                       base - bojo + bojo * math.sin(angulo)))
    return pontos


def tocha_chama(quadro: int = 0) -> Tela:
    """Labareda em quatro tons, num dos quatro quadros da danca."""
    if not 0 <= quadro < QUADROS_DE_CHAMA:
        raise ValueError("quadro de chama invalido: %d (esperado 0 a %d)"
                         % (quadro, QUADROS_DE_CHAMA - 1))
    desvio, altura = _DANCA[quadro]
    figura = Escultura(11, 15)
    for escala, claridade in _CAMADAS:
        figura.poligono(_gota(5.5, 14.0, 4.2 * escala, altura * escala, desvio * escala),
                        "fogo", claridade=claridade, borda=False)
    return figura.render()


def tocha_suporte() -> Tela:
    """Castical: cuia de ferro com aro e um cabo curto."""
    figura = Escultura(9, CASTICAL_ALTURA)
    figura.capsula((4.5, 5), (4.5, 9), 1.2, "madeira")
    figura.elipse(4.5, 1.5, 3.6, 4.0, "metal", corte=(0, 1, 9, 6))
    for x in range(1, 8):
        figura.marcar(x, 1, "metal", LUZ if x < 4 else BASE)
    return figura.render()


def poste() -> Tela:
    """Poste de madeira para a tocha ao ar livre: sem parede na fazenda, a
    tocha ficava pendurada no ceu. O castical encaixa no topo."""
    figura = Escultura(POSTE_LARGURA, POSTE_ALTURA)
    figura.capsula((3.5, 1.5), (3.5, POSTE_ALTURA + 2), 1.6, "madeira")
    figura.riscar([(3, y) for y in (6, 7, 15, 16, 17, 25)])
    figura.poligono([(1, POSTE_ALTURA - 3), (6, POSTE_ALTURA - 3), (6, POSTE_ALTURA),
                     (1, POSTE_ALTURA)], "madeira", claridade=0.4)
    return figura.render()


def braseiro(quadro: int = 0) -> Tela:
    """Fogueira do checkpoint: roda de pedras com lenha cruzada. Quadro 0
    apagado, 1 em brasa (braseiro.gd usa esses indices e poe a chama)."""
    if quadro not in (0, 1):
        raise ValueError("quadro de braseiro invalido: %d (esperado 0 ou 1)" % quadro)
    figura = Escultura(26, 14)
    lenha = "fogo" if quadro else "madeira"
    for inicio, fim in (((6, 9), (19, 3)), ((20, 9), (7, 3)), ((13, 10), (13, 2))):
        figura.capsula(inicio, fim, 1.6, lenha, clarear=0.25 if quadro else 0.0)
    for x, raio in ((3.5, 2.6), (8.5, 2.9), (13, 2.6), (17.5, 2.9), (22.5, 2.6)):
        figura.elipse(x, 12 - raio, raio, raio, "pedra")
    return figura.render()


def brilho(raio: int = 26) -> Tela:
    """Halo radial em aneis translucidos, para blend aditivo."""
    lado = raio * 2
    tela = Tela(lado, lado)
    cor_do_fogo = tom("fogo", LUZ)[:3]
    for y in range(lado):
        for x in range(lado):
            distancia = math.hypot(x + 0.5 - raio, y + 0.5 - raio) / raio
            if distancia < 1.0:
                anel = int((1.0 - distancia) * 5)
                tela.definir(x, y, cor_do_fogo + ((18, 40, 70, 110, 160)[anel],))
    return tela


PROPS = {
    "tocha_suporte": tocha_suporte,
    "brilho": brilho,
    "poste": poste,
}
