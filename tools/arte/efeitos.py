"""Efeitos de golpe: o rastro do corte da espada.

Era um arco desenhado em codigo (draw_arc em pixel_effect.gd), de traco liso
que destoava dos sprites. Aqui e uma meia-lua em quatro quadros, virada para a
direita: nasce em cima, enche, afina e some embaixo -- o caminho da lamina.
"""

import math

from rampas import tom
from tela import Tela

LARGURA = 30
ALTURA = 48
QUADROS_DE_CORTE = 4
# Centro do giro: a mao do heroi, a esquerda da celula.
_CENTRO = (-8.0, ALTURA / 2.0)
_RAIO = 30.0
## Por quadro: (angulo inicial, angulo final, espessura maxima), em graus.
_VARREDURA = [(-62, -8, 5.0), (-62, 50, 8.0), (-40, 62, 5.0), (15, 62, 2.5)]


def _tom_do_corte(profundidade: float) -> tuple[int, int, int, int]:
    """Branco no fio de fora, creme no miolo e laranja na cauda de dentro."""
    if profundidade < 0.35:
        return (255, 255, 255, 255)
    return tom("palha", 4) if profundidade < 0.75 else tom("fogo", 3)


def corte(quadro: int = 0) -> Tela:
    """Meia-lua do corte num dos quatro quadros da varredura."""
    if not 0 <= quadro < QUADROS_DE_CORTE:
        raise ValueError("quadro de corte invalido: %d (esperado 0 a %d)"
                         % (quadro, QUADROS_DE_CORTE - 1))
    inicio, fim, espessura = _VARREDURA[quadro]
    meio, abertura = (inicio + fim) / 2.0, (fim - inicio) / 2.0
    tela = Tela(LARGURA, ALTURA)
    for y in range(ALTURA):
        for x in range(LARGURA):
            dx, dy = x + 0.5 - _CENTRO[0], y + 0.5 - _CENTRO[1]
            afastamento = (math.degrees(math.atan2(dy, dx)) - meio) / abertura
            if abs(afastamento) >= 1.0:
                continue
            # Mais grossa no meio da varredura, afinando nas duas pontas.
            grossura = espessura * (1.0 - afastamento * afastamento)
            para_dentro = _RAIO - math.hypot(dx, dy)
            if 0.0 <= para_dentro < grossura:
                tela.definir(x, y, _tom_do_corte(para_dentro / grossura))
    return tela
