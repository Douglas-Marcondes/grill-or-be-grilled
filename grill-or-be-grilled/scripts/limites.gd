extends RefCounted

## Limites verticais do mundo da fase, num lugar so.
##
## A morte por queda ficava em y > 850 enquanto a camera parava em 700: o heroi
## sumia da tela e continuava caindo 150px no escuro antes de o jogo reagir
## (PENDENCIAS.md, "Camera"). Agora a queda e fatal logo abaixo do quadro.
##
## Exemplo:
##     if global_position.y > Limites.QUEDA_FATAL:
##         morrer()

const FUNDO_DA_CAMERA := 700.0
## Folga de um corpo inteiro abaixo do quadro: o heroi termina de sair da tela
## antes da morte, em vez de morrer com metade do corpo visivel.
const QUEDA_FATAL := FUNDO_DA_CAMERA + 30.0
