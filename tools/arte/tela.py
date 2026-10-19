"""Tela de pixels: ASCII art -> PNG.

Sprites sao escritos como blocos de texto onde cada caractere e uma cor. E
legivel em diff, editavel sem ferramenta, e o PNG gerado abre no Aseprite para
Douglas e Jorge continuarem a mao.

Uso:
    tela = Tela(8, 3)
    pintar(tela, 0, 0, ["ooo", "o.o", "ooo"], {"o": "palha"})
    salvar(tela, "bloco.png")
"""

from PIL import Image

from paleta import TRANSPARENTE, cor

Pixel = tuple[int, int, int, int]


class Tela:
    """Grade RGBA mutavel de tamanho fixo, indexada em pixels de arte."""

    def __init__(self, largura: int, altura: int) -> None:
        if largura <= 0 or altura <= 0:
            raise ValueError(
                "Tela exige largura e altura positivas; recebi %dx%d"
                % (largura, altura)
            )
        self.largura = largura
        self.altura = altura
        self._pixels: list[Pixel] = [TRANSPARENTE] * (largura * altura)

    def definir(self, x: int, y: int, pixel: Pixel) -> None:
        """Pinta um pixel, ignorando coordenadas fora da tela (clipping)."""
        if 0 <= x < self.largura and 0 <= y < self.altura:
            self._pixels[y * self.largura + x] = pixel

    def ler(self, x: int, y: int) -> Pixel:
        if not (0 <= x < self.largura and 0 <= y < self.altura):
            return TRANSPARENTE
        return self._pixels[y * self.largura + x]

    def para_imagem(self) -> Image.Image:
        imagem = Image.new("RGBA", (self.largura, self.altura))
        imagem.putdata(self._pixels)
        return imagem


def pintar(tela: Tela, x: int, y: int, linhas: list[str], mapa: dict[str, str]) -> None:
    """Carimba ASCII art em (x, y). '.' e espaco ficam transparentes."""
    for dy, linha in enumerate(linhas):
        for dx, caractere in enumerate(linha):
            if caractere in (".", " "):
                continue
            if caractere not in mapa:
                raise ValueError(
                    "caractere %r na linha %d nao esta no mapa (chaves: %s)"
                    % (caractere, dy, "".join(sorted(mapa)))
                )
            tela.definir(x + dx, y + dy, cor(mapa[caractere]))


def de_ascii(linhas: list[str], mapa: dict[str, str]) -> Tela:
    """Cria uma Tela do tamanho exato do bloco ASCII.

    Exige que todas as linhas tenham o mesmo comprimento: num sprite escrito a
    mao, uma linha curta desalinha a figura inteira em silencio, e o erro e
    quase impossivel de achar olhando o PNG.
    """
    altura = len(linhas)
    largura = max((len(linha) for linha in linhas), default=0)
    for indice, linha in enumerate(linhas):
        if len(linha) != largura:
            raise ValueError(
                "linha %d tem %d caracteres, esperado %d (as demais linhas): %r"
                % (indice, len(linha), largura, linha)
            )
    tela = Tela(largura, altura)
    pintar(tela, 0, 0, linhas, mapa)
    return tela


def retangulo(tela: Tela, x: int, y: int, largura: int, altura: int, nome: str) -> None:
    pixel = cor(nome)
    for dy in range(altura):
        for dx in range(largura):
            tela.definir(x + dx, y + dy, pixel)


def colar(destino: Tela, origem: Tela, x: int, y: int) -> None:
    """Compoe origem sobre destino respeitando transparencia (alpha binario)."""
    for dy in range(origem.altura):
        for dx in range(origem.largura):
            pixel = origem.ler(dx, dy)
            if pixel[3]:
                destino.definir(x + dx, y + dy, pixel)


def folha(quadros: list[Tela], colunas: int = 0) -> Tela:
    """Monta um spritesheet em grade uniforme do maior quadro.

    Godot le a folha por celulas de tamanho fixo (hframes/vframes), entao todos
    os quadros ficam centrados horizontalmente e alinhados pelo pe -- um sprite
    que cresce no ataque nao desloca o personagem no chao.
    """
    if not quadros:
        raise ValueError("folha() exige ao menos um quadro; recebi lista vazia")
    colunas = colunas or len(quadros)
    linhas = (len(quadros) + colunas - 1) // colunas
    celula_l = max(quadro.largura for quadro in quadros)
    celula_a = max(quadro.altura for quadro in quadros)
    destino = Tela(celula_l * colunas, celula_a * linhas)
    for indice, quadro in enumerate(quadros):
        coluna, linha = indice % colunas, indice // colunas
        deslocamento_x = (celula_l - quadro.largura) // 2
        deslocamento_y = celula_a - quadro.altura
        colar(destino, quadro, coluna * celula_l + deslocamento_x,
              linha * celula_a + deslocamento_y)
    return destino


def salvar(tela: Tela, caminho: str) -> None:
    tela.para_imagem().save(caminho)


def oval(tela: Tela, centro_x: int, centro_y: int, raio_x: int, raio_y: int,
         nome: str) -> None:
    """Preenche uma elipse. Forma organica grande fica melhor em primitiva do
    que em ASCII art: contar 40 colunas a mao produz curva irregular."""
    pixel = cor(nome)
    for y in range(centro_y - raio_y, centro_y + raio_y + 1):
        for x in range(centro_x - raio_x, centro_x + raio_x + 1):
            dx = (x - centro_x) / float(raio_x)
            dy = (y - centro_y) / float(raio_y)
            if dx * dx + dy * dy <= 1.0:
                tela.definir(x, y, pixel)


def contornar(tela: Tela, nome: str) -> None:
    """Desenha contorno de 1px em volta de tudo que esta opaco.

    Feito num passo so, depois das formas: garante silhueta fechada sem que cada
    forma precise carregar o proprio contorno (e sem contorno preso no meio da
    figura, onde duas formas se encontram).
    """
    pixel = cor(nome)
    vizinhos = ((1, 0), (-1, 0), (0, 1), (0, -1))
    a_pintar = []
    for y in range(tela.altura):
        for x in range(tela.largura):
            if tela.ler(x, y)[3]:
                continue
            if any(tela.ler(x + dx, y + dy)[3] for dx, dy in vizinhos):
                a_pintar.append((x, y))
    for x, y in a_pintar:
        tela.definir(x, y, pixel)


# Matriz de Bayer 4x4 para misturar dois tons vizinhos sem sair da paleta.
_BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def sombrear_abaixo(tela: Tela, linha: int, de: str, para: str,
                    mistura: int = 3) -> None:
    """Troca um tom por outro abaixo de certa linha, dentro da silhueta.

    As primeiras `mistura` linhas sao ditherizadas: sem isso a troca de tom vira
    um corte reto atravessando o corpo, que le como linha d'agua e nao como
    volume.
    """
    origem, destino = cor(de), cor(para)
    for y in range(linha, tela.altura):
        for x in range(tela.largura):
            if tela.ler(x, y) != origem:
                continue
            dentro_da_mistura = y - linha < mistura
            if dentro_da_mistura:
                limite = (y - linha + 1) * 16 // (mistura + 1)
                if _BAYER[y % 4][x % 4] >= limite:
                    continue
            tela.definir(x, y, destino)
