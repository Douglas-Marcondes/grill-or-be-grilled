# Grill or Be Grilled

Projetinho de criação de jogo com Douglas e Jorge (Doujor/ Dojór)

Pendências conhecidas e próximos passos: [PENDENCIAS.md](PENDENCIAS.md).

## Arte e pipeline visual

A arte do jogo é pixel art na paleta **DawnBringer 32** — a mesma paleta padrão do
Aseprite, que a arte original da galinha (`Artes/GalinhaAndando*.png`) já usava.
Manter DB32 deixa sprite gerado por código e sprite pintado à mão convivendo sem
destoar.

O jogo roda num viewport de **480x270** ampliado em escala inteira
(`window/stretch/mode="viewport"` + `scale_mode="integer"`), então cada pixel de
arte vira um bloco quadrado na tela em vez de ser reamostrado. 480x270 cabe exato
em 1920x1080 (4x).

### Gerando a arte

```
python3 tools/gerar_arte.py
```

Escreve tudo em `grill-or-be-grilled/Artes/gerado/`: fonte bitmap, tiles de
terreno, camadas de fundo, folhas de personagem e adereços. Os módulos ficam em
`tools/arte/`:

- `paleta.py`: DB32 e os papéis semânticos (`palha`, `pena`, `pedra_luz`...).
- `tela.py`: grade de pixels, ASCII art → PNG, spritesheets, contorno e dither.
- `glifos.py` / `fonte.py`: fonte 5x7 proporcional com acentuação portuguesa,
  exportada em BMFont (lido nativamente pelo Godot, sem TTF nem plugin).
- `cenario.py`: tiles de terreno 16x16, desenhados para repetir sem costura.
- `fundo.py`: céu com degradê ditherizado, silhuetas da fazenda, lua.
- `personagens.py`: galinha, Galinha Real, herói (3 classes), ovos, armas.
- `props.py`: tocha com chama de 4 quadros e halo de luz.

> Os PNGs em `Artes/gerado/` são **ponto de partida**, não verdade final. Rodar o
> script de novo sobrescreve a pasta inteira. Arte retocada no Aseprite deve ser
> movida para fora de `gerado/`.

### Como o cenário é montado

O desenho da fase continua sendo `Polygon2D` arrastável no editor do Godot
(`jogo.tscn` → `EditorPreview/Cenario`). `scripts/terreno.gd` lê esse desenho e
deriva dele a colisão e a textura, escolhendo o material por região de X —
fazenda (terra e palha) até 3500, entrada de madeira até 6500, porão de pedra
depois disso. Mover uma plataforma no editor não exige tocar em código.

`scripts/tochas.gd` faz o mesmo com as tochas: esconde o marcador chapado em
tempo de execução e desenha a tocha animada por cima, mantendo o marcador
visível no editor.

### Ferramentas de desenvolvimento

- `ferramentas/capturar_cenas.tscn`: abre o jogo e grava um PNG de cada região da
  fase em `ferramentas/capturas/` (útil para comparar o visual antes/depois).
- `ferramentas/teste_de_fumaca.tscn`: roda a fase por alguns segundos com o
  jogador vivo e imprime `SMOKE_OK`; falha visível se algum script quebrar.

```
./Godot_v4.7.2-stable_linux.x86_64 --path grill-or-be-grilled res://ferramentas/teste_de_fumaca.tscn
```

## Estrutura de código

O projeto Godot fica em `grill-or-be-grilled/`.

- `perso1.gd`: política de entrada e controle do jogador.
- `galinha.gd`: comportamento de patrulha e animação da galinha inimiga.
- `scripts/character_movement.gd`: primitivas compartilhadas de movimento para `CharacterBody2D`.
- `scripts/sprites.gd`: monta os `Sprite2D` dos personagens ancorados pelo pé.
- `scripts/terreno.gd`: layout editável → colisão + textura, por região da fase.
- `scripts/tochas.gd`: tochas animadas com halo de luz.
- `tema_pixel.tres`: fonte, cores e bordas da interface, num lugar só.
- Arquivos `.tscn`: composição dos personagens e das fases; mantenha caminhos de recursos alinhados com os scripts anexados.

### Primitivas compartilhadas

`CharacterMovement` concentra gravidade, velocidade horizontal, desaceleração e orientação do sprite. Controladores decidem *quando* chamar cada operação (entrada do jogador ou IA do inimigo); regras físicas comuns são alteradas uma vez no módulo compartilhado. Para novas entidades, reutilize essas funções e mantenha no controlador apenas as decisões específicas da entidade.

1.
   Primeira fase: Criação de ideia:
        -> Conceito do jogo:
          - Doungeon: Mapa 2D com foco no personagem, com caminho com parkour, npc's (inimigos), e um boss final depois de "3 ou 5?" niveis.
          - Cada boss teria uma chance de drop, com itens especiais, para ajudar os jogadores na gameplay.
          - Os npc's dropariam itens também, para o jogador acumular e vender posteriormente para dar upgrade no jogo.
          - Personagem principal teria uma arma (Acredito que espada) inicial, para poder matar os npc's.
2. 
   Segunda fase: Mão na massa:
         -> Criação do primeiro nivel.
           - Criação de mapa na GODOT, sem imagens inicialmente, deixar a primeira fase funcional.
           - Depois adicionar o player, npc's e o boss, animações, mapa, entre todos os outros designs.
           - Testagem de fase.

3. 
    Terceira fase: Continuação:
         -> Musicas, efeitos sonoros, e os outros niveis:
           -
           -
           -

## Primeira fase jogável

O projeto principal é `grill-or-be-grilled/`; a cena inicial jogável é `jogo.tscn`.
Ao iniciar, escolha Guerreiro (espada), Arqueiro (arco) ou Mago (varinha). Atravesse
a dungeon, derrote as cinco galinhas que perseguem o jogador, recolha seus ovos e
vença a Galinha Real. Os ovos têm cinco raridades e são vendidos automaticamente
na vitória. O boss tem investida, bicada e disparo de penas; sua armadura cômica
(bico, crista e barbela) tem 90% de chance de drop. A loja entre tentativas vende
armas e melhorias permanentes, salvas localmente. Morrer reinicia o nível e perde
os ovos da tentativa.

Controles: A/D ou setas para andar, Espaço ou seta para cima para pular, J ou clique
esquerdo para atacar.
