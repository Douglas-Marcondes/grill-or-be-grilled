extends RefCounted

## Geometria da tela em pe e deitada, num lugar so.
##
## O jogo e desenhado para uma faixa de 480x270. Deitado, com aspect "expand",
## a tela so cresce para os lados e a faixa e a tela toda. Em pe, a tela cresce
## para baixo: a faixa do jogo fica em cima, igual a de deitado, e a sobra de
## baixo vira o painel dos controles de toque -- o layout de "Game Boy" que
## jogos horizontais usam no celular em pe, para o dedo nao tapar a acao.
##
## Exemplo:
##     var sobra := FormatoDaTela.sobra(get_viewport())   # 0 deitado
##     if FormatoDaTela.tem_painel(get_viewport()): ...

const ALTURA_DO_JOGO := 270.0
## Sobra minima para valer um painel com botoes grandes; abaixo disso (tela
## quase quadrada) os botoes ficam por cima do jogo, como deitado.
const SOBRA_MINIMA_DO_PAINEL := 160.0


static func sobra(viewport: Viewport) -> float:
	"""Altura (px do jogo) que passa da faixa de 270: o espaco do painel."""
	return maxf(0.0, viewport.get_visible_rect().size.y - ALTURA_DO_JOGO)


static func tem_painel(viewport: Viewport) -> bool:
	return sobra(viewport) >= SOBRA_MINIMA_DO_PAINEL
