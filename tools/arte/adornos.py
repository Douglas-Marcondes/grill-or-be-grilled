"""Adornos de primeiro plano: pecas pequenas espalhadas no topo das plataformas.

Sem eles cada plataforma era um bloco liso do comeco ao fim. Plataformistas em
pixel art quebram essa monotonia com adereco miudo (capim, caixote, osso) que
nao bloqueia nada e conta onde se esta: fazenda, entrada do celeiro, porao.

Uma folha por regiao, todos os quadros alinhados pelo pe (tela.folha), lida por
scripts/adornos.gd. A ordem dos quadros importa: os primeiros sao os comuns
(capim, pedrinha) e os ultimos os raros -- o peso de sorteio esta la.
"""

from tela import Tela, colar, contornar, de_ascii

CORES = {
    "o": "tinta",
    "g": "grama_sombra",
    "G": "grama",
    "L": "grama_luz",
    "p": "palha_sombra",
    "P": "palha",
    "C": "palha_luz",
    "m": "madeira_sombra",
    "M": "madeira",
    "W": "madeira_luz",
    "a": "fogo_borda",
    "A": "fogo",
    "s": "pedra_sombra",
    "S": "pedra",
    "b": "pena_sombra",
    "B": "pena",
    "y": "ouro",
    "r": "crista",
    "R": "crista_luz",
}

CAPIM_ALTO = [
    "..L...L.",
    "..G..LG.",
    ".LG.GG..",
    ".GgGG.L.",
    "..gGgGG.",
    ".ggGgg..",
]

CAPIM_BAIXO = [
    ".L..L.",
    ".GLGG.",
    "gGgGgg",
]

PEDRINHA = [
    ".SSs.",
    "SSSss",
]

FENO = [
    "..CCPCCPCC..",
    ".CPPCPPCPPC.",
    "CPPpPPpPPpPC",
    "PPpPPpPPpPPP",
    "PmmmmmmmmmmP",
    "PPpPPpPPpPPp",
    "pPPpPPpPPpPp",
    ".ppppppppp..",
]

ABOBORA = [
    "....mM...",
    "...mMG...",
    ".aAAAAAa.",
    "aAyAaAyAa",
    "aAAAaAAAa",
    "aAAAaAAAa",
    ".aaaaaaa.",
]

CAIXOTE = [
    "WWWWWWWWWW",
    "WMmmmmmmMW",
    "WmWmmmmMmW",
    "WmmWmmMmmW",
    "WmmmWMmmmW",
    "WmmmMWmmmW",
    "WmmMmmWmmW",
    "WmMmmmmWmW",
    "WMmmmmmmMW",
    "WWWWWWWWWW",
]

BARRIL = [
    ".MWWWWM.",
    "MssssssM",
    "MWMWMWMM",
    "WMWMWMWM",
    "MssssssM",
    "WMWMWMWM",
    "MWMWMWMM",
    "MssssssM",
    ".MWMWMM.",
]

SACO = [
    "...mm...",
    "..mCCm..",
    ".PCCCPP.",
    "PCCrRCPP",
    "PCCRrCPP",
    "PPCCCPPp",
    ".ppppPp.",
]

OSSO = [
    "B......B",
    "BBBBBBBB",
    "b......b",
]

CASCA = [
    "B.B..B.",
    "BbBBbBb",
    ".bBBBb.",
]

COGUMELO = [
    "..rRRr..",
    ".rRBRRr.",
    "rRRRRBRr",
    "...BB...",
    "...Bb...",
]

COGUMELO_PEQUENO = [
    ".rRr.",
    "rRBRr",
    "..b..",
]


def _peca(linhas: list[str], contorno: bool = True) -> Tela:
    """Peca com contorno escuro: separa o adorno do terreno logo atras dele.
    Capim fica sem contorno porque ele deve se fundir na faixa de palha."""
    desenho = de_ascii(linhas, CORES)
    if not contorno:
        return desenho
    # Margem de 1px: contornar so pinta dentro da tela, e a borda do desenho
    # encostada no limite ficaria sem contorno.
    tela = Tela(desenho.largura + 2, desenho.altura + 2)
    colar(tela, desenho, 1, 1)
    contornar(tela, "tinta")
    return tela


def fazenda() -> list[Tela]:
    return [_peca(CAPIM_ALTO, False), _peca(CAPIM_BAIXO, False), _peca(PEDRINHA),
            _peca(ABOBORA), _peca(FENO)]


def entrada() -> list[Tela]:
    return [_peca(SACO), _peca(CAPIM_BAIXO, False), _peca(CAIXOTE),
            _peca(BARRIL), _peca(PEDRINHA)]


def porao() -> list[Tela]:
    return [_peca(OSSO), _peca(COGUMELO_PEQUENO), _peca(CASCA),
            _peca(COGUMELO), _peca(PEDRINHA)]


REGIOES = {
    "fazenda": fazenda,
    "entrada": entrada,
    "porao": porao,
}
