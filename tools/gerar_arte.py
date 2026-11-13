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
    for nome, desenhar in cenario.FRANJAS.items():
        salvar(desenhar(), str(DESTINO / ("franja_%s.png" % nome)))
    return len(cenario.TILES) + len(cenario.FRANJAS)


def _gerar_fundo() -> int:
    import fundo
    from tela import salvar

    for nome, desenhar in fundo.CAMADAS.items():
        salvar(desenhar(), str(DESTINO / ("fundo_%s.png" % nome)))
    return len(fundo.CAMADAS)


def _gerar_personagens() -> int:
    import chefe
    import galinhas
    import heroi
    import itens
    from tela import folha, salvar

    folhas = {
        **{
            plumagem: [galinhas.galinha(quadro, plumagem) for quadro in range(galinhas.QUADROS)]
            for plumagem in galinhas.PLUMAGENS
        },
        "galinha_real": [chefe.galinha_real(quadro) for quadro in range(chefe.QUADROS)],
        "ovos": [itens.ovo(raridade) for raridade in range(len(itens.RAMPAS_DE_OVO))],
    }
    for classe in heroi.FIGURINOS:
        folhas["heroi_%s" % classe.lower()] = [
            heroi.heroi(classe, quadro) for quadro in range(heroi.QUADROS_DO_HEROI)
        ]
    for nome, quadros in folhas.items():
        salvar(folha(quadros, len(quadros)), str(DESTINO / ("%s.png" % nome)))
    for nome in itens.ARMAS:
        salvar(itens.arma(nome), str(DESTINO / ("arma_%s.png" % nome.lower())))
    salvar(itens.armadura_galinha(), str(DESTINO / "armadura_galinha.png"))
    return len(folhas) + len(itens.ARMAS) + 1


def _gerar_props() -> int:
    import props
    from tela import folha, salvar

    for nome, desenhar in props.PROPS.items():
        salvar(desenhar(), str(DESTINO / ("%s.png" % nome)))
    chamas = [props.tocha_chama(quadro) for quadro in range(props.QUADROS_DE_CHAMA)]
    salvar(folha(chamas, len(chamas)), str(DESTINO / "tocha_chama.png"))
    salvar(folha([props.braseiro(0), props.braseiro(1)], 2), str(DESTINO / "braseiro.png"))
    return len(props.PROPS) + 2


def _gerar_efeitos() -> int:
    import efeitos
    from tela import folha, salvar

    quadros = [efeitos.corte(quadro) for quadro in range(efeitos.QUADROS_DE_CORTE)]
    salvar(folha(quadros, len(quadros)), str(DESTINO / "corte.png"))
    return len(quadros)


def _gerar_adornos() -> int:
    import adornos
    from tela import folha, salvar

    for regiao, pecas in adornos.REGIOES.items():
        quadros = pecas()
        salvar(folha(quadros, len(quadros)), str(DESTINO / ("adornos_%s.png" % regiao)))
    return len(adornos.REGIOES)


def _gerar_icones() -> int:
    import icones
    from tela import folha, salvar

    quadros = icones.icones()
    salvar(folha(quadros, len(quadros)), str(DESTINO / "icones_hud.png"))
    return len(quadros)


def _gerar_projeteis() -> int:
    import projeteis
    from tela import folha, salvar

    quadros = projeteis.projeteis()
    salvar(folha(quadros, len(quadros)), str(DESTINO / "projeteis.png"))
    return len(quadros)


def _gerar_toque() -> int:
    import toque
    from tela import folha, salvar

    for sufixo, apertado in (("", False), ("_apertado", True)):
        quadros = toque.botoes(apertado)
        salvar(folha(quadros, len(quadros)), str(DESTINO / ("toque%s.png" % sufixo)))
    return len(toque.ORDEM)


def main() -> int:
    import fonte
    import rampas

    DESTINO.mkdir(parents=True, exist_ok=True)
    print("tiles: %d" % _gerar_tiles())
    print("camadas de fundo: %d" % _gerar_fundo())
    print("folhas de personagem: %d" % _gerar_personagens())
    print("adereços: %d" % _gerar_props())
    print("folhas de adornos: %d" % _gerar_adornos())
    print("icones do HUD: %d" % _gerar_icones())
    print("projeteis: %d" % _gerar_projeteis())
    print("botoes de toque: %d" % _gerar_toque())
    print("quadros de efeito: %d" % _gerar_efeitos())
    glifos = fonte.gerar(
        str(DESTINO / "fonte_pixel.fnt"),
        str(DESTINO / "fonte_pixel.png"),
        "fonte_pixel.png",
    )
    print("fonte_pixel: %d glifos" % glifos)
    rampas.paleta_png(str(DESTINO / "paleta.png"))
    print("paleta: %d rampas" % len(rampas.RAMPAS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
