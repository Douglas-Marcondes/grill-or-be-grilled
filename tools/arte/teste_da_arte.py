"""Testes do gerador de arte: motor de escultura, ladrilho, rampas e folhas.

    python3 -m unittest discover -s tools/arte -p "teste_*.py"
"""

import unittest

import adornos
import cenario
import chefe
import efeitos
import fundo
import galinhas
import heroi
import itens
import projeteis
import props
from ladrilho import Ladrilho
from paleta import cor
from rampas import BASE, BRILHO, CONTORNO, RAMPAS, SOMBRA, tom
from volume import Escultura


class Rampas(unittest.TestCase):
    def test_toda_rampa_tem_cinco_tons_validos(self) -> None:
        for nome in RAMPAS:
            self.assertEqual(len(RAMPAS[nome]), BRILHO + 1, nome)
            self.assertEqual(tom(nome, BRILHO)[3], 255)

    def test_rampa_ou_nivel_desconhecido_nomeia_o_valor(self) -> None:
        with self.assertRaisesRegex(ValueError, "inexistente"):
            tom("inexistente", BASE)
        with self.assertRaisesRegex(ValueError, "9"):
            tom("pena", 9)

    def test_ascii_art_alcanca_a_rampa_pelo_nome(self) -> None:
        self.assertEqual(cor("crista#3"), tom("crista", 3))


class Esculturas(unittest.TestCase):
    def test_esfera_e_clara_em_cima_a_esquerda_e_escura_embaixo_a_direita(self) -> None:
        figura = Escultura(24, 24)
        figura.elipse(12, 12, 9, 9, "pena")
        tela = figura.render()
        self.assertEqual(tela.ler(7, 6), tom("pena", BRILHO))
        self.assertEqual(tela.ler(17, 17), tom("pena", SOMBRA))

    def test_contorno_externo_usa_a_cor_escura_do_material(self) -> None:
        figura = Escultura(12, 12)
        figura.elipse(6, 6, 3, 3, "crista")
        self.assertEqual(figura.render().ler(2, 6), tom("crista", CONTORNO))
        self.assertEqual(figura.render(contorno=False).ler(2, 6)[3], 0)

    def test_forma_nova_risca_o_que_ja_estava_em_volta(self) -> None:
        figura = Escultura(20, 20)
        figura.poligono([(0, 0), (20, 0), (20, 20), (0, 20)], "pena", borda=False)
        figura.elipse(10, 10, 3, 3, "crista")
        self.assertEqual(figura.render().ler(6, 10), tom("pena", CONTORNO))

    def test_corte_recorta_a_elipse(self) -> None:
        figura = Escultura(12, 12)
        figura.elipse(6, 6, 4, 4, "oliva", corte=(0, 0, 12, 6))
        tela = figura.render(contorno=False)
        self.assertTrue(tela.ler(6, 4)[3])
        self.assertFalse(tela.ler(6, 8)[3])


class Ladrilhos(unittest.TestCase):
    def test_escrita_da_a_volta_na_borda(self) -> None:
        piso = Ladrilho(8, 8, "terra")
        piso.pintar(9, -1, BRILHO)
        self.assertEqual(piso.nivel(1, 7), BRILHO)

    def test_texturas_tem_o_tamanho_que_o_godot_espera(self) -> None:
        for nome, desenhar in cenario.TILES.items():
            self.assertEqual(desenhar().largura % 16, 0, nome)
        for nome, desenhar in cenario.FRANJAS.items():
            self.assertEqual(desenhar().altura, cenario.ALTURA_DA_FRANJA, nome)


class Folhas(unittest.TestCase):
    def _mesmo_tamanho(self, quadros: list) -> None:
        tamanhos = {(quadro.largura, quadro.altura) for quadro in quadros}
        self.assertEqual(len(tamanhos), 1, tamanhos)

    def test_quadros_de_cada_personagem_tem_a_mesma_celula(self) -> None:
        for plumagem in galinhas.PLUMAGENS:
            self._mesmo_tamanho([galinhas.galinha(q, plumagem) for q in range(galinhas.QUADROS)])
        for classe in heroi.FIGURINOS:
            self._mesmo_tamanho([heroi.heroi(classe, q) for q in range(heroi.QUADROS_DO_HEROI)])
        self._mesmo_tamanho([chefe.galinha_real(q) for q in range(chefe.QUADROS)])

    def test_personagem_pisa_na_ultima_linha(self) -> None:
        for tela in (galinhas.galinha(0), heroi.heroi("Mago", 0), chefe.galinha_real(0)):
            self.assertTrue(any(tela.ler(x, tela.altura - 1)[3] for x in range(tela.largura)))

    def test_quadro_ou_nome_invalido_e_recusado(self) -> None:
        for chamada in (lambda: galinhas.galinha(5), lambda: efeitos.corte(4), lambda: galinhas.galinha(0, "pato"),
                        lambda: heroi.heroi("Bardo"), lambda: heroi.heroi("Mago", 9),
                        lambda: chefe.galinha_real(2), lambda: itens.ovo(5),
                        lambda: itens.arma("Machado"), lambda: props.tocha_chama(4),
                        lambda: props.braseiro(2)):
            self.assertRaises(ValueError, chamada)

    def test_folhas_tem_a_contagem_de_quadros_dos_scripts(self) -> None:
        # adornos.gd QUADROS=5, projectile.gd TIPOS=4, tochas.gd poste 7x34.
        for regiao in adornos.REGIOES.values():
            self.assertEqual(len(regiao()), 5)
        self.assertEqual(len(projeteis.projeteis()), 4)
        self.assertEqual((props.poste().largura, props.poste().altura), (7, 34))
        self.assertEqual(props.tocha_suporte().altura, 10)

    def test_folhas_tem_os_quadros_de_golpe_bote_e_dano(self) -> None:
        # player.gd QUADROS_DO_HEROI=9, chicken_enemy.gd QUADROS=5.
        self.assertEqual(heroi.QUADROS_DO_HEROI, 9)
        self.assertEqual(galinhas.QUADROS, 5)
        self.assertNotEqual(galinhas.galinha(0)._pixels, galinhas.galinha(galinhas.QUADRO_DE_BOTE)._pixels)

    def test_corte_nasce_em_cima_e_some_embaixo(self) -> None:
        def linhas_pintadas(tela) -> list[int]:
            return [y for y in range(tela.altura)
                    if any(tela.ler(x, y)[3] for x in range(tela.largura))]
        self.assertLess(max(linhas_pintadas(efeitos.corte(0))), efeitos.ALTURA // 2)
        self.assertGreater(min(linhas_pintadas(efeitos.corte(3))), efeitos.ALTURA // 2)

    def test_camadas_de_fundo_repetem_em_640(self) -> None:
        for nome in ("ceu", "fazenda", "colinas", "cerca"):
            self.assertEqual(fundo.CAMADAS[nome]().largura, 640, nome)


if __name__ == "__main__":
    unittest.main()
