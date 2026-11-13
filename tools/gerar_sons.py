#!/usr/bin/env python3
"""Gera os efeitos sonoros e a musica do Grill or Be Grilled em WAV.

Som chiptune sintetizado por codigo, no mesmo espirito de gerar_arte.py: onda
quadrada, triangular e ruido com envelope, como um console de 8 bits. Combina
com a pixel art e nao depende de banco de sons de terceiros (licenca). So usa a
biblioteca padrao do Python.

    python3 tools/gerar_sons.py

Escreve em grill-or-be-grilled/Artes/sons/. Rodar de novo sobrescreve a pasta;
som retocado a mao deve ficar fora dela.
"""

import math
import random
import struct
import wave
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "grill-or-be-grilled" / "Artes" / "sons"
TAXA = 22050


def _onda(forma: str, fase: float) -> float:
    """Amostra de -1 a 1 de uma onda periodica na fase (0..1)."""
    if forma == "quadrada":
        return 1.0 if fase % 1.0 < 0.5 else -1.0
    if forma == "pulso":
        return 1.0 if fase % 1.0 < 0.25 else -1.0
    if forma == "triangulo":
        return 4.0 * abs((fase % 1.0) - 0.5) - 1.0
    if forma == "ruido":
        return random.uniform(-1.0, 1.0)
    raise ValueError("forma de onda desconhecida %r; esperado quadrada, pulso, triangulo ou ruido" % forma)


def tom(inicio: float, fim: float, duracao: float, forma: str = "quadrada",
        volume: float = 0.5, ataque: float = 0.005) -> list[float]:
    """Varredura de frequencia de `inicio` a `fim` Hz com decaimento linear.

    Exemplo: tom(880, 220, 0.2) e um "piu" descendo.
    """
    total = int(TAXA * duracao)
    amostras, fase = [], 0.0
    for i in range(total):
        t = i / max(1, total - 1)
        fase += (inicio + (fim - inicio) * t) / TAXA
        envelope = min(1.0, i / max(1, TAXA * ataque)) * (1.0 - t)
        amostras.append(_onda(forma, fase) * volume * envelope)
    return amostras


def juntar(*partes: list[float]) -> list[float]:
    """Concatena trechos em sequencia."""
    return [amostra for parte in partes for amostra in parte]


def mixar(*camadas: list[float]) -> list[float]:
    """Soma trechos tocando juntos, com corte em -1..1."""
    tamanho = max(len(camada) for camada in camadas)
    soma = [0.0] * tamanho
    for camada in camadas:
        for i, amostra in enumerate(camada):
            soma[i] += amostra
    return [max(-1.0, min(1.0, amostra)) for amostra in soma]


def silencio(duracao: float) -> list[float]:
    return [0.0] * int(TAXA * duracao)


def salvar(nome: str, amostras: list[float]) -> None:
    with wave.open(str(DESTINO / ("%s.wav" % nome)), "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        arquivo.writeframes(b"".join(struct.pack("<h", int(a * 32767)) for a in amostras))


EFEITOS = {
    "pulo": lambda: tom(300, 620, 0.12, "pulso", 0.35),
    "golpe": lambda: tom(1400, 300, 0.09, "ruido", 0.35),
    "tiro": lambda: tom(900, 500, 0.1, "pulso", 0.3),
    "acerto": lambda: mixar(tom(220, 80, 0.1, "quadrada", 0.45), tom(2000, 400, 0.06, "ruido", 0.3)),
    "dano": lambda: juntar(tom(400, 150, 0.12, "quadrada", 0.5), tom(300, 90, 0.15, "quadrada", 0.4)),
    "esquiva": lambda: tom(1800, 600, 0.12, "ruido", 0.25),
    "aviso": lambda: juntar(tom(1200, 1200, 0.05, "pulso", 0.25), silencio(0.03), tom(1200, 1200, 0.05, "pulso", 0.25)),
    # Cacarejo: tres "co" rapidos subindo, o ultimo esticado.
    "cacarejo": lambda: juntar(tom(700, 500, 0.06, "pulso", 0.35), tom(800, 600, 0.06, "pulso", 0.35),
                               tom(1000, 520, 0.16, "pulso", 0.35)),
    "ovo": lambda: juntar(tom(988, 988, 0.06, "quadrada", 0.3), tom(1319, 1319, 0.12, "quadrada", 0.3)),
    "braseiro": lambda: mixar(juntar(tom(523, 523, 0.1, "triangulo", 0.5), tom(659, 659, 0.1, "triangulo", 0.5),
                                     tom(784, 784, 0.25, "triangulo", 0.5)),
                              tom(3000, 800, 0.45, "ruido", 0.12)),
    "pancada": lambda: mixar(tom(120, 40, 0.35, "quadrada", 0.6), tom(600, 100, 0.3, "ruido", 0.4)),
    "investida": lambda: tom(200, 500, 0.25, "ruido", 0.35),
    "vitoria": lambda: juntar(*(tom(f, f, d, "quadrada", 0.35) for f, d in
                                [(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.4)])),
    "derrota": lambda: juntar(*(tom(f, f * 0.97, 0.22, "triangulo", 0.5) for f in [392, 330, 262, 196])),
}

# Musica: 4 compassos em la menor (Am F C G), baixo triangular e arpejo em
# pulso. 112 bpm, colcheias. Volume baixo: e cama para os efeitos, nao primeiro plano.
ACORDES = [(220.0, [440, 523, 659]), (174.6, [349, 440, 523]),
           (130.8, [262, 330, 392]), (196.0, [392, 494, 587])]
COLCHEIA = 60.0 / 112.0 / 2.0


def musica() -> list[float]:
    trechos = []
    for volta in range(2):
        for baixo, notas in ACORDES:
            arpejo = juntar(*(tom(notas[i % 3] * (2 if volta and i % 4 == 3 else 1), notas[i % 3],
                                  COLCHEIA, "pulso", 0.09, 0.002) for i in range(8)))
            linha = juntar(*(tom(baixo, baixo, COLCHEIA * 2, "triangulo", 0.22) for _ in range(4)))
            trechos.append(mixar(arpejo, linha))
    return juntar(*trechos)


def main() -> None:
    random.seed(7)  # ruido reprodutivel: rodar de novo nao muda os arquivos
    DESTINO.mkdir(parents=True, exist_ok=True)
    for nome, gerar in EFEITOS.items():
        salvar(nome, gerar())
    salvar("musica_fase1", musica())
    print("efeitos: %d, musica: 1 -> %s" % (len(EFEITOS), DESTINO))


if __name__ == "__main__":
    main()
