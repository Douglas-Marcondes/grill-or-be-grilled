"""O heroi nas tres classes, montado por pose em vez de recorte de pernas.

A versao anterior tinha um corpo so e deslocava as colunas das pernas: o heroi
andava como boneco de papel. Aqui cada quadro e uma POSE (onde estao os pes, a
mao de tras, quanto o tronco inclina) e o corpo e esculpido em cima dela, entao
correr, pular, cair e esquivar tem silhuetas diferentes de verdade.

Proporcao de arcade: cabeca grande (um terco da altura), tronco curto, bota
pesada. A mao da frente fica sempre na altura em que player.gd pendura a arma
(ALTURA_DA_MAO), por isso ela nao balanca na corrida.

Ordem dos quadros (player.gd usa os mesmos indices): 0-3 corrida, 4 pulo,
5 queda, 6 esquiva, 7 golpe, 8 dano.
"""

from dataclasses import dataclass

from rampas import BASE, BRILHO, CONTORNO, LUZ, SOMBRA
from tela import Tela
from volume import Escultura

LARGURA = 30
ALTURA = 38
CHAO = ALTURA - 2
CENTRO = LARGURA // 2


@dataclass(frozen=True)
class Pose:
    """Onde cada parte do corpo esta num quadro. Pes e mao sao relativos ao
    quadril: (avanco em x, altura acima do chao)."""

    pe_de_tras: tuple[float, float]
    pe_da_frente: tuple[float, float]
    mao_de_tras: tuple[float, float]
    agachar: float = 0.0
    inclinar: float = 0.0
    ## Quanto a mao da frente avanca alem do lugar de sempre. No golpe ela
    ## acompanha o avanco da arma (player.gd, AVANCO_DO_GOLPE).
    estocada: float = 0.0
    mao_da_frente_sobe: float = 0.0


POSES = [
    Pose((-2, 0), (2, 0), (-4, 13)),
    Pose((-5, 1), (4, 0), (2, 12), agachar=1),
    Pose((-1, 0), (1, 2), (-3, 13)),
    Pose((4, 0), (-5, 2), (-6, 14), agachar=1),
    # pulo: joelhos recolhidos, braco de tras jogado para cima
    Pose((-3, 3), (3, 5), (-6, 22), agachar=-1),
    # queda: pernas abertas, braco para o alto freando
    Pose((-5, 1), (4, 3), (-5, 25), inclinar=-1),
    # esquiva: mergulho rasteiro, pernas ficando para tras
    Pose((-9, 0), (-5, 2), (-7, 6), agachar=7, inclinar=5),
    # golpe: passo largo a frente, tronco jogado junto com a arma
    Pose((-6, 0), (5, 0), (-8, 11), agachar=1, inclinar=2, estocada=5),
    # dano: corpo arqueado para tras, bracos abertos, um pe no ar
    Pose((-1, 0), (5, 3), (-8, 20), inclinar=-3, estocada=-1, mao_da_frente_sobe=7),
]
QUADROS_DO_HEROI = len(POSES)

FIGURINOS = {
    "Guerreiro": {"tunica": "azul", "calca": "pano", "chapeu": "bandana"},
    "Arqueiro": {"tunica": "verde", "calca": "couro", "chapeu": "gorro"},
    "Mago": {"tunica": "roxo", "calca": "roxo", "chapeu": "pontudo"},
}
CORES_POR_CLASSE = FIGURINOS


def heroi(classe: str = "Guerreiro", quadro: int = 0) -> Tela:
    """Heroi de uma classe num quadro da folha.

    Exemplo: heroi("Mago", 4) e o mago no pulo.
    """
    if classe not in FIGURINOS:
        raise ValueError("classe desconhecida: %r (esperado uma de %s)"
                         % (classe, ", ".join(FIGURINOS)))
    if not 0 <= quadro < QUADROS_DO_HEROI:
        raise ValueError("quadro do heroi invalido: %d (esperado 0 a %d)"
                         % (quadro, QUADROS_DO_HEROI - 1))
    figurino, pose = FIGURINOS[classe], POSES[quadro]
    figura = Escultura(LARGURA, ALTURA)
    quadril = (CENTRO - 1.0, CHAO - 10.0 + pose.agachar)
    peito = (quadril[0] + pose.inclinar, quadril[1] - 5.0)
    cabeca = (round(peito[0] + pose.inclinar * 0.4 + 1), round(peito[1] - 6))
    _braco(figura, figurino, peito, (quadril[0] + pose.mao_de_tras[0],
                                     CHAO - pose.mao_de_tras[1]), atras=True)
    _acessorio_das_costas(figura, classe, peito)
    _pernas(figura, figurino, quadril, pose)
    _tronco(figura, figurino, quadril, peito)
    _cabeca(figura, figurino, cabeca)
    _braco(figura, figurino, peito, (CENTRO + 4.0 + pose.estocada,
                                     CHAO - 12.0 + pose.agachar * 0.6 - pose.mao_da_frente_sobe))
    return figura.render()


def _pernas(figura: Escultura, figurino: dict, quadril: tuple[float, float],
            pose: Pose) -> None:
    for lado, pe in ((-1.4, pose.pe_de_tras), (1.4, pose.pe_da_frente)):
        solo = (quadril[0] + lado + pe[0], CHAO - 1.5 - pe[1])
        figura.capsula((quadril[0] + lado, quadril[1]), solo, 2.4, figurino["calca"],
                       raio_final=2.0, clarear=-0.25 if lado < 0 else 0.0)
        figura.elipse(solo[0] + 1.0, solo[1] + 0.4, 2.7, 1.9, "couro")


def _tronco(figura: Escultura, figurino: dict, quadril: tuple[float, float],
            peito: tuple[float, float]) -> None:
    figura.capsula((quadril[0], quadril[1] - 1.0), peito, 4.2, figurino["tunica"],
                   raio_final=4.6)
    if figurino["chapeu"] == "pontudo":
        _saia_do_manto(figura, quadril)
    _cinto(figura, quadril)


def _saia_do_manto(figura: Escultura, quadril: tuple[float, float]) -> None:
    """O manto do mago desce em sino por cima das pernas."""
    x, y = quadril
    figura.poligono([(x - 4.5, y - 2), (x + 4.5, y - 2), (x + 6.5, y + 7.5),
                     (x - 6.5, y + 7.5)], "roxo", claridade=0.6, queda=0.05)
    figura.riscar([(int(x) - 2, int(y) + dy) for dy in (1, 2, 3, 4, 5, 6)])
    figura.riscar([(int(x) + 3, int(y) + dy) for dy in (2, 3, 4, 5, 6)])
    for dx in range(-6, 7):
        figura.marcar(int(x) + dx, int(y) + 7, "ouro", BASE if dx % 3 else LUZ)


def _cinto(figura: Escultura, quadril: tuple[float, float]) -> None:
    x, y = int(quadril[0]), int(quadril[1]) - 2
    for dx in range(-4, 5):
        figura.riscar([(x + dx, y)], -2)
    figura.marcar(x + 2, y, "ouro", LUZ)


def _braco(figura: Escultura, figurino: dict, peito: tuple[float, float],
           mao: tuple[float, float], atras: bool = False) -> None:
    ombro = (peito[0] + (-2.5 if atras else 2.0), peito[1] - 0.5)
    cotovelo = ((ombro[0] + mao[0]) / 2.0 - (0.0 if atras else 1.5),
                (ombro[1] + mao[1]) / 2.0 + 1.0)
    escuro = -0.25 if atras else 0.0
    figura.capsula(ombro, cotovelo, 2.1, figurino["tunica"], clarear=escuro)
    figura.capsula(cotovelo, mao, 1.7, "pele", clarear=escuro)
    figura.elipse(mao[0], mao[1], 1.9, 1.9, "pele", clarear=escuro)


def _acessorio_das_costas(figura: Escultura, classe: str,
                          peito: tuple[float, float]) -> None:
    if classe != "Arqueiro":
        return
    # Aljava atravessada, com as penas das flechas aparecendo atras do ombro.
    x, y = peito
    figura.capsula((x - 3, y + 4), (x - 6, y - 4), 1.8, "couro")
    for dx, rampa in ((-7, "crista"), (-6, "pano"), (-5, "crista")):
        figura.marcar(int(x) + dx, int(y) - 6, rampa, LUZ)
        figura.marcar(int(x) + dx, int(y) - 7, rampa, BASE)


def _cabeca(figura: Escultura, figurino: dict, centro: tuple[int, int]) -> None:
    x, y = centro
    figura.elipse(x, y, 5.4, 5.2, "pele")
    figura.elipse(x + 5.2, y + 1.4, 1.4, 1.3, "pele", borda=False)
    _rosto(figura, x, y)
    _CHAPEUS[figurino["chapeu"]](figura, x, y)


def _rosto(figura: Escultura, x: int, y: int) -> None:
    """Olho grande, sobrancelha franzida e boca decidida."""
    for dy in (-1, 0):
        figura.marcar(x + 2, y + dy, "pena", BRILHO)
        figura.marcar(x + 3, y + dy, "couro", CONTORNO)
    for dx in (1, 2, 3, 4):
        figura.marcar(x + dx, y - 2 - (1 if dx < 2 else 0), "cabelo", CONTORNO)
    figura.marcar(x + 2, y + 3, "pele", CONTORNO)
    figura.marcar(x + 3, y + 3, "pele", CONTORNO)
    figura.marcar(x - 3, y + 1, "pele", SOMBRA)


def _bandana(figura: Escultura, x: int, y: int) -> None:
    """Guerreiro: cabelo castanho e bandana vermelha de pontas voando."""
    figura.elipse(x - 0.6, y - 0.6, 5.8, 5.6, "cabelo", corte=(0, 0, x - 2.5, y + 4))
    figura.elipse(x, y - 0.4, 5.6, 5.4, "crista", corte=(0, 0, LARGURA, y - 2.4))
    figura.capsula((x - 5, y - 3), (x - 10, y - 4), 1.1, "crista")
    figura.capsula((x - 5, y - 2), (x - 9, y + 1), 1.1, "crista")
    figura.riscar([(x - 2, y - 4), (x + 1, y - 5)])


def _gorro(figura: Escultura, x: int, y: int) -> None:
    """Arqueiro: gorro verde de bico caido para tras, com pena vermelha."""
    figura.capsula((x - 3, y - 6), (x - 9, y - 9), 1.0, "crista", raio_final=0.6)
    figura.elipse(x - 0.4, y - 0.6, 5.8, 5.6, "cabelo", corte=(0, 0, x - 3, y + 3))
    figura.poligono([(x - 6.5, y - 2), (x + 6.5, y - 2), (x + 3, y - 6.5),
                     (x - 3, y - 7.5), (x - 9, y - 4)], "verde", claridade=0.8, queda=0.08)
    for dx in range(-6, 7):
        figura.marcar(x + dx, y - 3, "verde", SOMBRA)


def _pontudo(figura: Escultura, x: int, y: int) -> None:
    """Mago: chapeu de cone torto com fivela e barba branca ate o peito."""
    figura.poligono([(x - 0.5, y + 2), (x + 5, y + 2.5), (x + 4.5, y + 6), (x + 2, y + 8.5)],
                    "barba", claridade=0.8, queda=0.04)
    figura.elipse(x + 5.2, y + 1.4, 1.4, 1.3, "pele", borda=False)
    figura.poligono([(x - 5, y - 2.5), (x + 5, y - 2.5), (x + 1, y - 9),
                     (x - 6, y - 12.5), (x - 3, y - 7)], "roxo", claridade=0.8, queda=0.05)
    figura.elipse(x, y - 2.6, 8.2, 1.9, "roxo")
    for dx in range(-4, 5):
        figura.marcar(x + dx, y - 4, "ouro", LUZ if dx == 1 else BASE)


_CHAPEUS = {"bandana": _bandana, "gorro": _gorro, "pontudo": _pontudo}
