"""Ladrilho: grade de textura que repete sem emenda, pintada por rampa.

Textura de terreno precisa casar a borda direita com a esquerda e a de baixo
com a de cima. Aqui toda escrita passa por modulo da largura e da altura, entao
uma pedra desenhada em cima da borda reaparece do outro lado e a costura some.
Cada pixel guarda (rampa, nivel) -- os niveis de rampas.py -- e so vira cor em
render(), o que deixa clarear e escurecer por cima do que ja foi pintado.

Uso:
    piso = Ladrilho(64, 64, "terra")
    piso.pedra(20, 30, 4, 2, "pedra")
    tela = piso.render()
"""

import random

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA, tom
from tela import Tela


def semeado(nome: str) -> random.Random:
    """Gerador estavel por textura: a arte nao muda entre execucoes."""
    return random.Random("grill-or-be-grilled/%s" % nome)


class Ladrilho:
    def __init__(self, largura: int, altura: int, rampa: str, nivel: int = BASE) -> None:
        if largura <= 0 or altura <= 0:
            raise ValueError("Ladrilho exige tamanho positivo; recebi %dx%d"
                             % (largura, altura))
        self.largura = largura
        self.altura = altura
        self._rampa = [[rampa] * largura for _ in range(altura)]
        self._nivel = [[nivel] * largura for _ in range(altura)]

    def pintar(self, x: int, y: int, nivel: int, rampa: str | None = None) -> None:
        """Define o nivel (e, se dada, a rampa) de um pixel, dando a volta."""
        x, y = x % self.largura, y % self.altura
        self._nivel[y][x] = max(CONTORNO, min(BRILHO, nivel))
        if rampa:
            self._rampa[y][x] = rampa

    def nivel(self, x: int, y: int) -> int:
        return self._nivel[y % self.altura][x % self.largura]

    def mudar(self, x: int, y: int, passo: int) -> None:
        """Clareia (+) ou escurece (-) o pixel sem trocar o material."""
        self.pintar(x, y, self.nivel(x, y) + passo)

    def bloco(self, x: int, y: int, largura: int, altura: int, nivel: int,
              rampa: str | None = None) -> None:
        for dy in range(altura):
            for dx in range(largura):
                self.pintar(x + dx, y + dy, nivel, rampa)

    def mancha(self, cx: int, cy: int, rx: int, ry: int, passo: int) -> None:
        """Mancha eliptica que clareia ou escurece: quebra o tom chapado."""
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx / rx) ** 2 + (dy / ry) ** 2 <= 1.0:
                    self.mudar(cx + dx, cy + dy, passo)

    def pedra(self, cx: int, cy: int, rx: int, ry: int, rampa: str) -> None:
        """Pedra embutida: luz em cima e a esquerda, sombra embaixo, e uma
        linha escura no pe que a faz parecer enterrada."""
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                distancia = (dx / (rx + 0.3)) ** 2 + (dy / (ry + 0.3)) ** 2
                if distancia > 1.0:
                    continue
                inclinacao = dx / (rx + 0.3) * 0.5 + dy / (ry + 0.3)
                nivel = LUZ if inclinacao < -0.35 else BASE if inclinacao < 0.45 else SOMBRA
                self.pintar(cx + dx, cy + dy, nivel, rampa)
                if distancia > 0.6 and dy > 0:
                    self.pintar(cx + dx, cy + dy + 1, CONTORNO)

    def render(self) -> Tela:
        tela = Tela(self.largura, self.altura)
        for y in range(self.altura):
            for x in range(self.largura):
                tela.definir(x, y, tom(self._rampa[y][x], self._nivel[y][x]))
        return tela

    def copiar_de(self, origem: "Ladrilho", da_linha: int) -> None:
        """Copia as linhas de `origem` a partir de `da_linha` (a parte de baixo
        de uma faixa de superficie e o miolo do bloco)."""
        for y in range(da_linha, min(self.altura, origem.altura)):
            for x in range(self.largura):
                self._rampa[y][x] = origem._rampa[y][x % origem.largura]
                self._nivel[y][x] = origem._nivel[y][x % origem.largura]
