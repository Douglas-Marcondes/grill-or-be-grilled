#!/usr/bin/env python3
"""Gera a arte do Grill or Be Grilled a partir dos modulos de tools/arte.

Os PNGs gerados sao o PONTO DE PARTIDA, nao a verdade final: depois de gerados,
podem ser repintados no Aseprite. Rodar este script de novo sobrescreve tudo em
Artes/gerado/, entao arte retocada a mao deve ser movida para fora dessa pasta.

    python3 tools/gerar_arte.py
"""

import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent / "arte"))

DESTINO = RAIZ / "grill-or-be-grilled" / "Artes" / "gerado"


def _gerar_tiles() -> int:
    import cenario
    from tela import salvar

    for nome, desenhar in cenario.TILES.items():
        salvar(desenhar(), str(DESTINO / ("tile_%s.png" % nome)))
    return len(cenario.TILES)


def _gerar_fundo() -> int:
    import fundo
    from tela import salvar

    for nome, desenhar in fundo.CAMADAS.items():
        salvar(desenhar(), str(DESTINO / ("fundo_%s.png" % nome)))
    return len(fundo.CAMADAS)


def _gerar_personagens() -> int:
    import personagens
    from tela import folha, salvar

    folhas = {
        **{
            plumagem: [personagens.galinha(quadro, plumagem) for quadro in range(4)]
            for plumagem in personagens.PLUMAGENS
        },
        "galinha_real": [personagens.galinha_real(quadro) for quadro in range(2)],
        "ovos": [personagens.ovo(raridade) for raridade in range(5)],
    }
    for classe in personagens.CORES_POR_CLASSE:
        folhas["heroi_%s" % classe.lower()] = [
            personagens.heroi(classe, quadro) for quadro in range(4)
        ]
    for nome, quadros in folhas.items():
        salvar(folha(quadros, len(quadros)), str(DESTINO / ("%s.png" % nome)))
    for nome in personagens.ARMAS:
        salvar(personagens.arma(nome), str(DESTINO / ("arma_%s.png" % nome.lower())))
    salvar(personagens.armadura_galinha(), str(DESTINO / "armadura_galinha.png"))
    return len(folhas) + len(personagens.ARMAS) + 1


def _gerar_props() -> int:
    import props
    from tela import folha, salvar

    for nome, desenhar in props.PROPS.items():
        salvar(desenhar(), str(DESTINO / ("%s.png" % nome)))
    chamas = [props.tocha_chama(quadro) for quadro in range(len(props.CHAMAS))]
    salvar(folha(chamas, len(chamas)), str(DESTINO / "tocha_chama.png"))
    return len(props.PROPS) + 1


def _gerar_adornos() -> int:
    import adornos
    from tela import folha, salvar

    for regiao, pecas in adornos.REGIOES.items():
        quadros = pecas()
        salvar(folha(quadros, len(quadros)), str(DESTINO / ("adornos_%s.png" % regiao)))
    return len(adornos.REGIOES)


def main() -> int:
    import fonte
    import paleta

    DESTINO.mkdir(parents=True, exist_ok=True)
    print("tiles: %d" % _gerar_tiles())
    print("camadas de fundo: %d" % _gerar_fundo())
    print("folhas de personagem: %d" % _gerar_personagens())
    print("adereços: %d" % _gerar_props())
    print("folhas de adornos: %d" % _gerar_adornos())
    glifos = fonte.gerar(
        str(DESTINO / "fonte_pixel.fnt"),
        str(DESTINO / "fonte_pixel.png"),
        "fonte_pixel.png",
    )
    print("fonte_pixel: %d glifos" % glifos)
    paleta.paleta_db32_png(str(DESTINO / "paleta_db32.png"))
    print("paleta_db32: %d cores" % len(paleta.DB32))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
