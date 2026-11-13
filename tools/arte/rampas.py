"""Rampas de cor: cada material tem cinco tons, do contorno ao brilho.

A paleta DB32 tem um tom so por material, entao todo volume era feito com duas
cores chapadas -- o que deixava o jogo com cara de prototipo. Arte de arcade
(Metal Slug e a referencia do projeto) pinta cada material com uma rampa de
quatro ou cinco tons que muda de matiz junto com o brilho: a sombra puxa para o
roxo/vinho e a luz para o amarelo. E isso que da o aspecto "pintado".

Os niveis de uma rampa: 0 contorno, 1 sombra, 2 base, 3 luz, 4 brilho.

Uso:
    from rampas import tom
    tom("pena", 3)  # -> (238, 240, 245, 255)
"""

CONTORNO, SOMBRA, BASE, LUZ, BRILHO = range(5)

RAMPAS: dict[str, tuple[str, str, str, str, str]] = {
    # Personagens
    "pena": ("3a3152", "9698be", "dadfee", "f4f6fb", "ffffff"),
    "pena_caipira": ("4a2a1a", "a2663a", "d6994f", "f2c884", "fdebbe"),
    "pena_galo": ("3a1218", "8a2a20", "c84c22", "ee8a34", "fdc86c"),
    "pena_cauda": ("14202e", "1f4a4a", "2f7a5e", "58aa6a", "a8dc8c"),
    "crista": ("48101e", "9a1c2c", "d6323a", "f4685a", "ffa890"),
    "bico": ("5a2a0c", "b8641a", "f09a24", "fdd04a", "fff3a4"),
    "pele": ("5a2a1c", "c07244", "f0a874", "fdcc9c", "ffe8cc"),
    "cabelo": ("1e1210", "45261a", "6e3e22", "98602e", "c48a48"),
    "barba": ("3c3a50", "8a8ca8", "c0c4d6", "e6e8f0", "ffffff"),
    "oliva": ("1c2618", "3c5632", "628244", "92ac60", "c6d690"),
    "azul": ("141a3a", "2a3e7c", "3e68b8", "6c9ce2", "b4d4f8"),
    "roxo": ("28103a", "582a80", "8848b4", "b67ad8", "e2b8f2"),
    "verde": ("12301c", "2a5e2c", "489030", "80bc3c", "c4e068"),
    "pano": ("3c3640", "8a8490", "c4beba", "e8e4da", "fffdf4"),
    "couro": ("2a1610", "5a3020", "8a5230", "b87a46", "e0aa72"),
    "metal": ("1c2030", "48546a", "7e8ea4", "b6c4d2", "f2f6fa"),
    "ouro": ("4a2808", "a8680e", "e4a41c", "fbd648", "fff6b0"),
    "magia": ("3a0e4a", "8a2a9a", "d456c8", "f49ae0", "ffe0f8"),
    # Cenario
    "terra": ("28181a", "583424", "86522e", "b07a44", "d6a868"),
    "grama": ("14301c", "2e5e28", "4e8a2e", "86b83a", "c4de64"),
    "palha": ("5a3810", "a87822", "d8aa3a", "f2d466", "fdf0a8"),
    "pedra": ("1c1e2c", "3e4254", "646a7c", "8e94a4", "c0c4cc"),
    "pedra_funda": ("0e0e1a", "1c1e30", "2c3044", "3e445a", "565c70"),
    "madeira": ("2a1410", "5c2e1c", "8c4a28", "b66e3a", "da9c5c"),
    "madeira_funda": ("160a0c", "301814", "4a261c", "643624", "7e4a30"),
    "celeiro": ("3a0e12", "7a1c1c", "b02e24", "d85234", "f08a58"),
    "telha": ("1e1c2a", "3c3a50", "5e5c76", "8684a0", "b4b2c8"),
    "fogo": ("7a1408", "d8340e", "f9801a", "fdc832", "fff7b8"),
    "abobora": ("5a1c08", "b84a10", "ee7e1a", "fdaa3a", "ffd880"),
    "cogumelo": ("48101e", "9a1c2c", "d6323a", "f4685a", "ffa890"),
    "osso": ("3c3440", "8c8478", "c8c0a8", "ece6d0", "fffdf0"),
    # Paisagem distante: menos contraste, puxada para a cor do ar.
    "colina": ("5a7a6a", "709a78", "8eb486", "aecc96", "cde0ac"),
    "colina_perto": ("2a4a44", "3c6a50", "55885a", "7aa868", "a4c47a"),
    "serra": ("6a5a7a", "8a7090", "a888a0", "c4a2a8", "dcbcae"),
    "nuvem": ("c8748a", "e89a8a", "f8c49c", "fde4bc", "fffaea"),
}


def tom(rampa: str, nivel: int) -> tuple[int, int, int, int]:
    """RGBA do nivel pedido de uma rampa (0 contorno ... 4 brilho)."""
    if rampa not in RAMPAS:
        raise ValueError("rampa desconhecida %r; esperado uma de %s"
                         % (rampa, ", ".join(sorted(RAMPAS))))
    if not 0 <= nivel < len(RAMPAS[rampa]):
        raise ValueError("nivel %r fora da rampa %r; esperado 0 a %d"
                         % (nivel, rampa, len(RAMPAS[rampa]) - 1))
    valor = RAMPAS[rampa][nivel]
    return (int(valor[0:2], 16), int(valor[2:4], 16), int(valor[4:6], 16), 255)


def paleta_png(caminho: str) -> None:
    """Exporta as rampas como grade (uma rampa por linha, do contorno ao
    brilho) para carregar como paleta no Aseprite."""
    from PIL import Image

    imagem = Image.new("RGBA", (BRILHO + 1, len(RAMPAS)))
    for linha, rampa in enumerate(RAMPAS):
        for nivel in range(BRILHO + 1):
            imagem.putpixel((nivel, linha), tom(rampa, nivel))
    imagem.save(caminho)
