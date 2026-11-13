"""Escultura: sprites modelados em formas com volume, sombreados por rampa.

Desenhar sprite caractere a caractere (tela.de_ascii) funciona ate uns 16px;
num personagem de 30px com quatro tons por material, contar coluna a mao da
curva torta e sombra incoerente entre quadros. Aqui o personagem e montado com
elipses, capsulas e poligonos, cada um com uma rampa (rampas.py); a luz vem
sempre de cima e da esquerda, e o tom de cada pixel sai da inclinacao da forma
naquele ponto. Mudar a pose e mover as formas -- a sombra acompanha sozinha.

Cada forma nova ganha, por padrao, uma linha escura sobre o que ja estava
desenhado em volta dela: e o contorno interno que separa asa de corpo e braco
de tronco. O contorno de fora e pintado em render(), na cor escura do proprio
material (contorno colorido, nao preto).

Uso:
    figura = Escultura(16, 16)
    figura.elipse(8, 8, 5, 5, "pena")
    figura.marcar(9, 7, "crista", BRILHO)
    tela = figura.render()
"""

import math

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA, tom
from tela import Tela

Ponto = tuple[float, float]
Mascara = dict[tuple[int, int], float]

# Direcao da luz (x, y, z): de cima e da esquerda, um pouco para a frente.
_LUZ = (-0.42, -0.66, 0.62)
# Limiares de claridade que separam sombra / base / luz / brilho.
_FAIXAS = ((0.30, SOMBRA), (0.66, BASE), (0.85, LUZ))


def _claridade(normal_x: float, normal_y: float) -> float:
    """Claridade 0..1 de um ponto cuja superficie aponta para (nx, ny)."""
    resto = max(0.0, 1.0 - normal_x * normal_x - normal_y * normal_y)
    incidencia = (normal_x * _LUZ[0] + normal_y * _LUZ[1]
                  + math.sqrt(resto) * _LUZ[2])
    return max(0.0, min(1.0, 0.25 + 0.65 * incidencia))


def _nivel(claridade: float) -> int:
    for limite, nivel in _FAIXAS:
        if claridade < limite:
            return nivel
    return BRILHO


class Escultura:
    """Tela de formas com volume. Coordenadas em pixels de arte (float)."""

    def __init__(self, largura: int, altura: int) -> None:
        if largura <= 0 or altura <= 0:
            raise ValueError("Escultura exige tamanho positivo; recebi %dx%d"
                             % (largura, altura))
        self.largura = largura
        self.altura = altura
        self._rampa: dict[tuple[int, int], str] = {}
        self._nivel: dict[tuple[int, int], int] = {}

    # -- formas ---------------------------------------------------------

    def elipse(self, cx: float, cy: float, rx: float, ry: float, rampa: str,
               borda: bool = True, corte: tuple[float, float, float, float] | None = None,
               clarear: float = 0.0) -> None:
        """Elipse sombreada como esfera. `corte` (x0, y0, x1, y1) recorta a
        forma num retangulo -- meia elipse vira capacete, cupula, palpebra."""
        mascara: Mascara = {}
        for x, y in self._caixa(cx - rx, cy - ry, cx + rx, cy + ry, corte):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if nx * nx + ny * ny <= 1.0:
                mascara[(x, y)] = _claridade(nx, ny) + clarear
        self._assentar(mascara, rampa, borda)

    def capsula(self, inicio: Ponto, fim: Ponto, raio: float, rampa: str,
                borda: bool = True, raio_final: float | None = None,
                clarear: float = 0.0) -> None:
        """Membro: segmento grosso de pontas redondas, sombreado como cilindro.
        `raio_final` afina (ou engrossa) a ponta."""
        final = raio if raio_final is None else raio_final
        maior = max(raio, final)
        mascara: Mascara = {}
        caixa = self._caixa(min(inicio[0], fim[0]) - maior, min(inicio[1], fim[1]) - maior,
                            max(inicio[0], fim[0]) + maior, max(inicio[1], fim[1]) + maior)
        for x, y in caixa:
            afastamento = _afastamento(inicio, fim, raio, final, x + 0.5, y + 0.5)
            if afastamento:
                mascara[(x, y)] = _claridade(*afastamento) + clarear
        self._assentar(mascara, rampa, borda)

    def poligono(self, pontos: list[Ponto], rampa: str, claridade: float = 0.7,
                 borda: bool = True, queda: float = 0.0) -> None:
        """Forma chapada (bico, capa, lamina). `queda` escurece de cima para
        baixo, em claridade por pixel, para a forma nao ficar de um tom so."""
        topo = min(y for _, y in pontos)
        mascara: Mascara = {}
        caixa = self._caixa(min(x for x, _ in pontos), topo,
                            max(x for x, _ in pontos), max(y for _, y in pontos))
        for x, y in caixa:
            if _dentro(pontos, x + 0.5, y + 0.5):
                mascara[(x, y)] = claridade - queda * (y + 0.5 - topo)
        self._assentar(mascara, rampa, borda)

    # -- retoques -------------------------------------------------------

    def marcar(self, x: int, y: int, rampa: str, nivel: int) -> None:
        """Pinta um pixel direto num nivel da rampa: olho, brilho, botao."""
        if 0 <= x < self.largura and 0 <= y < self.altura:
            self._rampa[(x, y)] = rampa
            self._nivel[(x, y)] = nivel

    def riscar(self, pixels: list[tuple[int, int]], passo: int = -1) -> None:
        """Escurece (passo -1) ou clareia (+1) pixels ja pintados, sem trocar o
        material: marca de pena, dobra de pano, veio de madeira."""
        for posicao in pixels:
            if posicao in self._nivel:
                self._nivel[posicao] = max(CONTORNO, min(BRILHO, self._nivel[posicao] + passo))

    def sombrear(self, cx: float, cy: float, rx: float, ry: float, passo: int = -1) -> None:
        """Escurece o que ja esta pintado dentro de uma elipse: sombra que a
        cabeca projeta no peito, barriga na sombra."""
        pixels = [(x, y) for x, y in self._caixa(cx - rx, cy - ry, cx + rx, cy + ry)
                  if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0]
        self.riscar([p for p in pixels if self._nivel.get(p, CONTORNO) > SOMBRA], passo)

    # -- saida ----------------------------------------------------------

    def render(self, contorno: bool = True) -> Tela:
        """Converte em Tela, com o contorno externo na cor escura do material
        vizinho. Sem contorno para pecas que se fundem no cenario (capim)."""
        tela = Tela(self.largura, self.altura)
        for (x, y), rampa in self._rampa.items():
            tela.definir(x, y, tom(rampa, self._nivel[(x, y)]))
        if contorno:
            for (x, y), rampa in self._beirada().items():
                tela.definir(x, y, tom(rampa, CONTORNO))
        return tela

    # -- interno --------------------------------------------------------

    def _caixa(self, x0: float, y0: float, x1: float, y1: float,
               corte: tuple[float, float, float, float] | None = None) -> list[tuple[int, int]]:
        if corte:
            x0, y0 = max(x0, corte[0]), max(y0, corte[1])
            x1, y1 = min(x1, corte[2]), min(y1, corte[3])
        colunas = range(max(0, math.floor(x0)), min(self.largura, math.ceil(x1) + 1))
        linhas = range(max(0, math.floor(y0)), min(self.altura, math.ceil(y1) + 1))
        if not corte:
            return [(x, y) for y in linhas for x in colunas]
        return [(x, y) for y in linhas for x in colunas
                if corte[0] <= x + 0.5 <= corte[2] and corte[1] <= y + 0.5 <= corte[3]]

    def _assentar(self, mascara: Mascara, rampa: str, borda: bool) -> None:
        if borda:
            self._riscar_em_volta(mascara)
        for posicao, claridade in mascara.items():
            self._rampa[posicao] = rampa
            self._nivel[posicao] = _nivel(claridade)

    def _riscar_em_volta(self, mascara: Mascara) -> None:
        for x, y in mascara:
            for vizinho in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if vizinho not in mascara and vizinho in self._rampa:
                    self._nivel[vizinho] = CONTORNO

    def _beirada(self) -> dict[tuple[int, int], str]:
        """Pixels vazios encostados em pixel pintado, com a rampa do vizinho."""
        beirada: dict[tuple[int, int], str] = {}
        for (x, y), rampa in self._rampa.items():
            for vizinho in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if vizinho not in self._rampa:
                    beirada.setdefault(vizinho, rampa)
        return beirada


def _afastamento(inicio: Ponto, fim: Ponto, raio: float, raio_final: float,
                 x: float, y: float) -> tuple[float, float] | None:
    """Vetor do eixo da capsula ate o ponto, em unidades de raio; None fora."""
    dx, dy = fim[0] - inicio[0], fim[1] - inicio[1]
    comprimento = dx * dx + dy * dy
    posicao = 0.0
    if comprimento > 0.0:
        posicao = max(0.0, min(1.0, ((x - inicio[0]) * dx + (y - inicio[1]) * dy) / comprimento))
    raio_aqui = raio + (raio_final - raio) * posicao
    nx = (x - inicio[0] - dx * posicao) / raio_aqui
    ny = (y - inicio[1] - dy * posicao) / raio_aqui
    return (nx, ny) if nx * nx + ny * ny <= 1.0 else None


def _dentro(pontos: list[Ponto], x: float, y: float) -> bool:
    """Ponto dentro do poligono (regra par-impar)."""
    dentro = False
    anterior = pontos[-1]
    for atual in pontos:
        if (atual[1] > y) != (anterior[1] > y):
            cruzamento = atual[0] + (y - atual[1]) * (anterior[0] - atual[0]) / (anterior[1] - atual[1])
            if x < cruzamento:
                dentro = not dentro
        anterior = atual
    return dentro
