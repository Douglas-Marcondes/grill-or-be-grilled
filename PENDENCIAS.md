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
- **Flechas e penas atravessam o terreno**; só o ovo da atiradeira quebra no
  chão. Mudar isso altera o alcance das classes de tiro, então é decisão de
  balanceamento.

## Arte

Redesenho completo em 13/11/2026, com o Metal Slug X de referência: rampas de
cinco tons no lugar da DB32, sprites esculpidos (`tools/arte/volume.py`),
ladrilhos de 64px, fundo de fim de tarde pintado em cor e silhueta própria para
galo e atiradeira. O que ficou de fora dessa rodada:

- **Interface ainda é a antiga**: fonte, painéis do HUD/menus e botões de toque
  seguem na DB32 e no fundo roxo-escuro, pensados para a fase noturna.
- **Sem quadros de ataque nem de dano**: o herói tem corrida, pulo, queda e
  esquiva; golpe e dano ainda são só o avanço da arma e o clarão branco.
- **A armadura de galinha não acompanha a cabeça** no pulo e na esquiva (é um
  sprite fixo sobre a pose parada).
- **Entrada e porão usam o fundo da fazenda** atrás das paredes; cada região
  pediria um parallax próprio.

Camadas anteriores (ainda valem):

Camadas visuais feitas em 13/11/2026: luz e escuridão por região, sombra de
profundidade e contorno no terreno, colinas no fundo, horizonte menos repetido,
tochas da fazenda em poste, adornos no topo das plataformas e laje no porão.
Próximas camadas, da que mais muda a cara do jogo para a que menos:

- **Quinas das plataformas são retas.** A borda de baixo da faixa ganhou
  franja; as quinas laterais ainda são cantos vivos.
- **Adornos não sabem onde há inimigo ou ovo**: um feno pode cair atrás de um
  ovo. Por ora são pequenos e ficam atrás dos personagens.

- **A prévia do editor não cobre o parallax do fundo** (depende de simular a
  câmera).
- **Efeitos ainda são desenhados em código** (`pixel_effect.gd`: corte,
  explosão, onda de choque). Os projéteis já são sprites.
- **A massa de terra das plataformas ainda é grande** no enquadramento de 480x270.

## Celular

- **APK de Android ainda não foi gerado**: falta instalar o Android SDK e os
  templates de Android do Godot nesta máquina (passos no README). O build Web
  roda no celular e foi conferido num Chrome emulando Android com toque.
- **Testar num celular de verdade**: tamanho dos botões (30px de arte, área de
  toque de 18px de raio) e posição foram calibrados por emulação.
- **Sem botão de pausa**: o jogo não tem pausa em nenhuma plataforma; no celular
  isso pesa mais, porque não há tecla Esc.

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
