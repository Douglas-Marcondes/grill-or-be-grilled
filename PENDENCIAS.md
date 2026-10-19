# Pendências conhecidas

Lista viva do que está deliberadamente por fazer. Cada item diz **onde** está e
**por que** ficou de fora, para que retomar não exija redescobrir o contexto.

Atualizada em 19/10/2026, ao final da camada 1 de jogabilidade (controle do
herói: input map, coyote time, buffer de pulo, altura variável, aceleração) e da
prévia do editor.

## Passagens travadas na fase 1 — descoberto em 19/10/2026

Achado ao instrumentar o teste de fumaça para dirigir o herói pelas ações de
entrada. **Quatro pedras `RotaAlta` ficam parcialmente por cima da saída do
trecho anterior**, com menos altura livre do que o herói precisa para pular:

| Saída | Teto | Altura livre | Precisa subir |
| --- | --- | --- | --- |
| `Trecho7` (x=3940) | `RotaAlta7` (x 3911..4011) | 49px | 73px |
| `Trecho8` (x=4440) | `RotaAlta8` (x 4428..4546) | 21px | 45px |
| `Trecho11` (x=6130) | `RotaAlta11` (x 6113..6223) | 52px | 76px |
| `Trecho13` (x=7340) | `RotaAlta13` (x 7329..7431) | 37px | 79px |

Nesses quatro pontos o jogador aperta pulo e **bate a cabeça na pedra**. São
exatamente os quatro vãos largos (110–130px) da fase, onde a pedra é a única
rota — o vão direto não se faz nem com o arco antigo. A rota existe, mas exige
pular ~75px *antes* da borda da pedra, sem nenhuma pista visual, e quem pula
tarde não pula mais e cai. Resolver é mover as pedras para a frente da saída (ou
subir sua base), no editor; é layout, não código.

`RotaAlta15` (x 8460..8560, topo y=360) está 140px acima do `Trecho15`: nunca foi
alcançável, nem com o arco antigo (104px). O `Trecho15` → `Trecho16` tem de ser
pulado direto.

## Sem assistência de degrau

`CharacterBody2D` não sobe ressaltos sozinho, e o projeto não implementa nada
para isso. Um lábio de **3px** trava o herói por completo (observado no canto
esquerdo do `Trecho3`, x≈1225, onde o herói fica parado contra o degrau com a
direção pressionada). Candidatos: subir o `floor_snap_length`, um
`motion_mode`/`step` manual, ou arredondar os cantos no layout.

## Erro de física no drop de ovo

`egg_pickup.gd:17` adiciona o `CollisionShape2D` durante o flush de consultas de
física, porque `spawn_egg` é chamado de dentro de `_on_body_entered`
(`projectile.gd:32` → `chicken_enemy.gd` → `fase1.gd:150`). O Godot registra
`Can't change this state while flushing queries` em toda morte de galinha por
projétil. Resolver com `call_deferred` na criação do ovo.

## Jogabilidade — camadas ainda não feitas

A camada 1 (controle) foi feita. Estes números continuam como estavam e precisam
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

- **A prévia do editor não cobre o parallax do fundo.** As camadas `Parallax2D`
  aparecem no editor na posição base, sem repetição nem deslocamento, então o
  céu e as silhuetas no editor não são o que se vê em jogo. Fica de fora porque
  depende de simular o movimento da câmera.

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

## Combate — camada 2, não feita

- **A bicada da galinha não tem telegrafia nenhuma** (`chicken_enemy.gd`): o dano
  sai de uma checagem de proximidade, instantânea, sem pose nem aviso. Compare
  com o boss, que tem `attack_windup` e a faixa piscante — o inimigo comum não
  tem equivalente, então não há jogada de esquiva possível.
- **`take_damage` da galinha não dá knockback nem hitstun**: ela continua andando
  para dentro do jogador. Somado aos alcances (golpe 67px, bicada 48px), **trocar
  dano é obrigatório** para matar uma galinha — não existe jogada correta.
- **Sem hitstop e sem screen shake** no impacto.
- **Sem áudio**: não há um único `AudioStream` no projeto.

## Câmera — camada 3, não feita

`player.gd` dá à câmera só offset vertical, sem look-ahead nem zona morta. No
viewport de 480x270 o jogador vê ~240px à frente, mas `THREAT_RANGE` da galinha
é 320px (`chicken_enemy.gd`): **as galinhas começam a perseguir de fora da tela**.

A morte por queda é em `y > 850` (`player.gd`) mas `camera.limit_bottom = 700`
(`fase1.gd`): a queda termina fora do quadro.

## Protótipo paralelo

`perso1.gd`, `perso1.tscn`, `galinha.gd` e `galinha.tscn` são a implementação
anterior, independente, e **não** são usadas por `jogo.tscn`. Não foram tocadas
nesta rodada. Decidir se viram referência ou se saem do projeto.
