"""Monta a fonte pixel do jogo em formato BMFont (.fnt + .png).

BMFont e lido nativamente pelo Godot 4 como FontFile, sem plugin e sem TTF, e
guarda largura por caractere -- entao a fonte sai proporcional de verdade ("i"
estreito, "M" largo) em vez do bloco monoespacado tipico de fonte de jogo caseira.

O atlas usa celula fixa para manter o gerador simples; o espacamento real vem do
xadvance por caractere, nao da celula.
"""

from glifos import ACENTUADOS, DIACRITICOS, glifos_base
from tela import Tela, pintar, salvar

ALTURA_CORPO = 7
ALTURA_ACENTO = 3
ALTURA_DESCIDA = 2
ALTURA_CELULA = ALTURA_ACENTO + ALTURA_CORPO + ALTURA_DESCIDA
LINHA_DE_BASE = ALTURA_ACENTO + ALTURA_CORPO
LARGURA_CELULA = 6
COLUNAS = 16
VAO_ENTRE_LETRAS = 1


def _largura_do_glifo(linhas: list[str]) -> int:
    """Largura util: a coluna mais a direita que tem tinta, +1.

    O desenho pode ter colunas vazias a direita (".....") e cobra-las como
    largura deixaria a fonte frouxa.
    """
    largura = 0
    for linha in linhas:
        for x, caractere in enumerate(linha):
            if caractere == "#":
                largura = max(largura, x + 1)
    return largura or 2  # espaco em branco nao tem tinta; vale 2 colunas


def _linhas_vazias_no_topo(linhas: list[str]) -> int:
    for indice, linha in enumerate(linhas):
        if "#" in linha:
            return indice
    return 0


def _compor_acentuado(base: list[str], diacritico: list[str]) -> list[str]:
    """Encaixa o diacritico logo acima da tinta da letra.

    Minuscula comeca duas linhas abaixo da maiuscula, entao o acento desce junto
    -- sem isso, o til de "a" flutua solto no meio do vao entre linhas.
    """
    folga = _linhas_vazias_no_topo(base)
    return [" " * 5] * folga + diacritico + base[folga:]


def _em_celula(linhas: list[str]) -> list[str]:
    """Alinha o desenho na celula: corpo comeca abaixo da faixa de acento."""
    return [" " * 5] * ALTURA_ACENTO + linhas


def catalogo_de_glifos() -> dict[str, list[str]]:
    """Todos os glifos finais: desenhados a mao + acentuados compostos."""
    base = glifos_base()
    catalogo = {
        caractere: _em_celula(linhas) for caractere, linhas in base.items()
    }
    for acentuado, (letra, acento) in ACENTUADOS.items():
        catalogo[acentuado] = _compor_acentuado(base[letra], DIACRITICOS[acento])
    return catalogo


def _desenhar_atlas(catalogo: dict[str, list[str]]) -> tuple[Tela, list[dict]]:
    """Pinta o atlas e devolve a tabela de caracteres do .fnt."""
    caracteres = sorted(catalogo, key=ord)
    linhas_grade = (len(caracteres) + COLUNAS - 1) // COLUNAS
    atlas = Tela(LARGURA_CELULA * COLUNAS, ALTURA_CELULA * linhas_grade)
    tabela: list[dict] = []
    for indice, caractere in enumerate(caracteres):
        desenho = catalogo[caractere]
        x = (indice % COLUNAS) * LARGURA_CELULA
        y = (indice // COLUNAS) * ALTURA_CELULA
        pintar(atlas, x, y, desenho, {"#": "branco"})
        largura = _largura_do_glifo(desenho)
        tabela.append({
            "id": ord(caractere),
            "x": x,
            "y": y,
            "width": largura,
            "height": ALTURA_CELULA,
            "xadvance": largura + VAO_ENTRE_LETRAS,
        })
    return atlas, tabela


def _texto_fnt(atlas: Tela, tabela: list[dict], nome_png: str) -> str:
    cabecalho = [
        'info face="GrillPixel" size=%d bold=0 italic=0 charset="" unicode=1'
        " stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0"
        % ALTURA_CELULA,
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0"
        % (ALTURA_CELULA + 1, LINHA_DE_BASE, atlas.largura, atlas.altura),
        'page id=0 file="%s"' % nome_png,
        "chars count=%d" % len(tabela),
    ]
    for entrada in tabela:
        cabecalho.append(
            "char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0"
            " xadvance=%d page=0 chnl=15"
            % (entrada["id"], entrada["x"], entrada["y"], entrada["width"],
               entrada["height"], entrada["xadvance"])
        )
    return "\n".join(cabecalho) + "\n"


def gerar(caminho_fnt: str, caminho_png: str, nome_png: str) -> int:
    """Escreve .fnt e .png da fonte; devolve quantos glifos foram gravados."""
    catalogo = catalogo_de_glifos()
    atlas, tabela = _desenhar_atlas(catalogo)
    salvar(atlas, caminho_png)
    with open(caminho_fnt, "w", encoding="utf-8") as arquivo:
        arquivo.write(_texto_fnt(atlas, tabela, nome_png))
    return len(tabela)
