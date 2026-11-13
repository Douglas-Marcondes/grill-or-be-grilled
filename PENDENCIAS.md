# Pendências conhecidas

Lista viva do que está deliberadamente por fazer. Cada item diz **onde** está e
**por que** ficou de fora, para que retomar não exija redescobrir o contexto.

Atualizada em 13/11/2026, depois da rodada de jogabilidade, desafio, história e som.

## Resolvido nesta rodada (13/11/2026)

- Passagens travadas pelas pedras `RotaAlta7/8/11/13/15`: viraram degraus dentro
  do vão (`teste_das_passagens`).
- Quina de 3px no `Trecho3`: subida de degrau de até 8px (`Movimento.climb_step`).
- Erro de flush de física no drop de ovo: criação adiada com `call_deferred`.
- Alcances de golpe e bicada casados com os sprites; bicada com aviso; knockback,
  hitstun, hitstop e screen shake.
- 16 galinhas idênticas: agora há curva por posição na fase e duas variantes.
- Câmera: olhar à frente, galinhas perseguem só dentro do quadro, morte por queda
  logo abaixo da tela.
- Sem áudio: efeitos e música gerados por `tools/gerar_sons.py`.
- Placas fora do quadro: baixadas para cada região, com texto da história.
- Fresta no fim do mundo: a Galinha Real caía para fora da arena (x>9981).

## Jogabilidade

- **Testar com controle de verdade.** Tudo foi verificado por testes headless e
  capturas de tela; os números de esquiva (`scripts/esquiva.gd`), hitstop
  (`scripts/impacto.gd`) e ritmo do chefe (`RITMO` em `chicken_boss.gd`) são
  primeiros palpites e pedem uma partida jogada para afinar.
- **O braseiro apagado é discreto**: é o castiçal da tocha (7x10px) fincado no
  chão. Aceso, o halo aparece bem. Uma arte própria de fogueira ajudaria a ver o
  checkpoint de longe.
- **Variantes são troca de plumagem.** Galo e atiradeira usam a silhueta da
  galinha com outra cor (`PLUMAGENS` em `tools/arte/personagens.py`). Uma
  silhueta própria (cauda de galo, pose de arremesso) leria melhor.
- **Flechas e penas atravessam o terreno**; só o ovo da atiradeira quebra no
  chão. Mudar isso altera o alcance das classes de tiro, então é decisão de
  balanceamento.

## Arte

Primeira camada visual feita em 13/11/2026: luz e escuridão por região, sombra
de profundidade e contorno no terreno, colinas no fundo e horizonte menos
repetido. Próximas camadas, da que mais muda a cara do jogo para a que menos:

- **Tochas da fazenda flutuam no céu.** Ao ar livre não há parede para prender a
  tocha; precisam de poste, ou virar lampião pendurado na cerca.
- **Sem decoração de primeiro plano**: tufos de capim, fardos de feno, barris,
  correntes e ossos quebrariam os blocos lisos. Pede um `scripts/adornos.gd` que
  espalhe adereços nos topos das plataformas por região.
- **Bordas das plataformas são retas.** Uma borda irregular (franja de palha
  caindo, pedra lascada) no topo e nas quinas tira o ar de retângulo.
- **HUD é texto puro.** Corações e ícone de ovo em vez de "♥ 50/50  Ovos: 0".
- **Musgo verde no topo do porão** lê como grama ao ar livre; um piso de laje
  combinaria mais com masmorra.

- **A prévia do editor não cobre o parallax do fundo** (depende de simular a
  câmera).
- **Projéteis e efeitos ainda são `draw_rect`** (`projectile.gd`,
  `pixel_effect.gd`).
- **O herói não tem quadro de pulo, queda nem esquiva.** No ar ele congela num
  quadro de caminhada; a esquiva é mostrada só pelo rastro.
- **A massa de terra das plataformas ainda é grande** no enquadramento de 480x270.

## Coleta de ovo

`egg_pickup.gd` usa raio 16px para um ovo de 7x8px. É generoso de propósito
(raio de coleta folgado é convenção em plataforma).

## Ferramentas

- **Fechar o jogo com som tocando** faz o Godot acusar `resources still in use
  at exit` no console. É inofensivo; `capturar_cenas` espera o mixer antes de
  sair, e o `Som` fica mudo em headless pelo mesmo motivo.

## Protótipo paralelo

`perso1.gd`, `perso1.tscn`, `galinha.gd` e `galinha.tscn` são a implementação
anterior, independente, e **não** são usadas por `jogo.tscn`. Decidir se viram
referência ou se saem do projeto.
