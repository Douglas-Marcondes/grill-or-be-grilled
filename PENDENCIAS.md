# Pendências conhecidas

Lista viva do que está deliberadamente por fazer. Cada item diz **onde** está e
**por que** ficou de fora, para que retomar não exija redescobrir o contexto.

Atualizada em 19/10/2026, ao final da repaginada visual (pixel art, parallax,
sprites e tochas).

## Jogabilidade — não foi tocada nesta rodada

A repaginada mexeu só no visual. Estes números continuam como estavam e precisam
de uma passada de calibragem própria.

### Alcances calibrados para a arte antiga

Quando os personagens eram desenhados por código, eram bem maiores. Os alcances
foram calibrados naquela escala e **não** foram reajustados junto com os sprites,
porque mudá-los altera dificuldade — decisão da rodada de gameplay, não da de arte.

| Onde | Valor | Problema |
| --- | --- | --- |
| `player.gd:126` | golpe de espada: 67px horizontais, 54px verticais | O herói tem 26px e a galinha 23px. 54px verticais deixam acertar inimigo a duas alturas de corpo acima ou abaixo, sem encostar nele. |
| `chicken_enemy.gd:75` | bicada: 48px em X e em Y | Mesma coisa do outro lado: a galinha acerta de longe demais para o tamanho dela. |

Os colisores **já** foram casados com os sprites nesta rodada (jogador 26px,
galinha 23px, Galinha Real 46px) — antes eram até 48% maiores que o desenho, o que
fazia levar dano de "nada". Falta só reajustar os alcances de ataque acima.

### Progressão de dificuldade

As 16 galinhas da fase são idênticas: `health := 3`, `speed := 92.0`,
`THREAT_RANGE := 320.0` (`chicken_enemy.gd:6-23`). Não há curva ao longo dos
10000px da fase — a primeira galinha e a última, já perto do ninho da Galinha Real,
dão o mesmo trabalho. É o item mais relevante para "progressão de dificuldade".

### Coleta de ovo

`egg_pickup.gd:15` usa raio 16px para um ovo de 7x8px. É generoso de propósito
(raio de coleta folgado é convenção em plataforma), mas fica registrado por ser a
única divergência sprite/colisor que sobrou de propósito.

## Arte — o que ficou de fora

- **Projéteis e efeito de corte ainda são `draw_rect`** (`projectile.gd`,
  `pixel_effect.gd`). Para efeito transitório isso se defende, mas a flecha e a
  bola de magia ganhariam virando sprite, como o resto já virou.
- **O herói não tem quadro de pulo nem de queda.** `player.gd:112` usa o quadro
  parado no chão e o ciclo de caminhada no resto; no ar o `animation_time` não
  avança, então ele congela num quadro de caminhada. Falta desenhar as poses.
- **As placas da fase (`Marco1..5` em `jogo.tscn`) ficam em `y = 300`**, acima da
  faixa visível em boa parte da fase, e aparecem cortadas pela borda da tela.
  Precisam ser reposicionadas por região.
- **A massa de terra das plataformas ainda é grande** no enquadramento de
  480x270 — as plataformas têm 240px de altura. Escurecer o tile ajudou, mas o
  que resolve de verdade é quebrar o miolo com raízes, pedras e variação de
  tile, ou revisar a altura das plataformas no editor.

## Protótipo paralelo

`perso1.gd`, `perso1.tscn`, `galinha.gd` e `galinha.tscn` são a implementação
anterior, independente, e **não** são usadas por `jogo.tscn`. Não foram tocadas
nesta rodada. Decidir se viram referência ou se saem do projeto.
