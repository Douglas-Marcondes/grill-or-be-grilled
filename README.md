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
- `fundo.py`: céu com degradê ditherizado, silhuetas da fazenda (faixa de 640px,
  espaçamento irregular), colinas escuras até o rodapé, lua.
- `personagens.py`: galinha, Galinha Real, herói (3 classes), ovos, armas.
- `props.py`: tocha com chama de 4 quadros, halo de luz e poste.
- `adornos.py`: uma folha de adornos por região (capim, feno e abóbora na
  fazenda; saco, caixote e barril na entrada; ossos, casca e cogumelos no porão),
  do mais comum ao mais raro.

> Os PNGs em `Artes/gerado/` são **ponto de partida**, não verdade final. Rodar o
> script de novo sobrescreve a pasta inteira. Arte retocada no Aseprite deve ser
> movida para fora de `gerado/`.

### Como o cenário é montado

O desenho da fase continua sendo `Polygon2D` arrastável no editor do Godot
(`jogo.tscn` → `EditorPreview/Cenario`). `scripts/terreno.gd` lê esse desenho e
deriva dele a colisão e a textura, escolhendo o material por região de X —
fazenda (terra e palha) até 3500, entrada de madeira até 6500, porão de pedra
depois disso. Mover uma plataforma no editor não exige tocar em código.

`scripts/tochas.gd` faz o mesmo com as tochas: esconde o marcador chapado e
desenha a tocha animada por cima, mantendo o marcador no .tscn.

### O editor mostra a fase vestida

`scripts/previa_do_editor.gd` está anexado ao nó `EditorPreview` e roda **a mesma
vestimenta do jogo** (`Terreno`, `Tochas`, `Sprites`) dentro do editor do Godot.
Sem ele o editor mostrava polígonos chapados e marcadores desenhados à mão, que
são maiores que os sprites reais (o marcador do jogador tem 40px contra os 26px
do herói) — então posicionar inimigo ou plataforma era adivinhação.

A cena salva **nunca** guarda a vestimenta: a prévia se desfaz em
`NOTIFICATION_EDITOR_PRE_SAVE` e se refaz em `..._POST_SAVE`, devolvendo cada
propriedade ao valor original. Isso é essencial porque `Terreno._assar_escala`
transfere o `scale` do nó para os vértices — gravar esse estado destruiria o
layout editável. `ferramentas/teste_da_previa.tscn` é o teste que garante o
retorno exato.

Dois detalhes de uso:

- O editor pode marcar a cena como **modificada** só por ter vestido a prévia.
  Salvar é seguro: ela se desveste antes.
- A chama fica num quadro fixo no editor (33 tochas animando redesenhariam o
  viewport sem parar). No jogo ela anima normalmente.
- Criou uma plataforma nova, ou arrastou algo entre regiões da fase? Marque
  **`revestir`** no inspetor do `EditorPreview` para vestir de novo.

### Ferramentas de desenvolvimento

- `ferramentas/capturar_cenas.tscn`: abre o jogo e grava um PNG de cada região da
  fase em `ferramentas/capturas/` (útil para comparar o visual antes/depois).
- `ferramentas/teste_da_previa.tscn`: veste e desveste uma cena de layout e
  confere que cada propriedade voltou idêntica. Imprime `PREVIA_OK`.
- `ferramentas/teste_do_salto.tscn`: mede o arco do pulo e as folgas (coyote
  time, buffer, altura variável) num piso isolado. Imprime `SALTO_OK`.
- `ferramentas/teste_de_fumaca.tscn`: roda a fase com o herói dirigido pelas
  **ações do input map** (não por `velocity` direta, senão não cobre aceleração
  nem as folgas do pulo), depois luta 8s na arena da Galinha Real. Falha se o
  herói morrer, cair da arena ou se algum script quebrar. Imprime `SMOKE_OK`.
- `ferramentas/teste_das_passagens.tscn`: pula cada vão da fase na borda e
  confere que todos passam; cobre também a quina do `Trecho3`.
- `teste_do_combate`, `teste_do_chefe`, `teste_dos_inimigos`,
  `teste_dos_braseiros`, `teste_da_historia`, `teste_dos_sons`,
  `teste_da_iluminacao`, `teste_dos_adornos`, `teste_do_hud`: um por camada.

Todos de uma vez (sai com erro se algum falhar ou se o Godot registrar `ERROR`):

```
tools/testar.sh
```

Testes e ferramentas gravam em `user://ferramentas.cfg`, nunca no save do jogo.

### Som

```
python3 tools/gerar_sons.py
```

Sintetiza os efeitos e a música em `Artes/sons/` (chiptune: onda quadrada,
triangular e ruído com envelope; só biblioteca padrão). O autoload `Som`
(`scripts/som.gd`) toca com `Som.tocar("pulo")`.

### O arco do pulo é restrito pela fase

Alcance horizontal de um pulo = tempo de ar × velocidade de corrida. Os vãos
largos da fase 1 (110–130px) foram calibrados no arco de 105px de altura e 0.78s
de ar, então `salto.gd` tira o "peso" só da assimetria subida/queda. As pedras
`RotaAlta7/8/11/13/15` ficam **dentro** do vão como degrau, e não por cima da
saída do trecho. Mudou o pulo ou o layout? Rode `teste_das_passagens`.

## Estrutura de código

O projeto Godot fica em `grill-or-be-grilled/`.

- `fase1.gd`: fluxo da fase (início, vidas, checkpoint, chefe, vitória).
- `player.gd`: política de entrada e controle do herói jogável.
- `chicken_enemy.gd`: galinha comum e base das variantes `galo.gd` e
  `galinha_atiradeira.gd`; o tipo de cada marcador vem de `metadata/tipo`
  (`scripts/bestiario.gd`).
- `chicken_boss.gd`: Galinha Real, três golpes telegrafados e duas fases.
- `braseiro.gd`: checkpoint (marcadores em `EditorPreview/Personagens/Braseiros`).
- `scripts/historia.gd`: todo o texto narrativo. `scripts/menus.gd`: telas de menu.
- `scripts/impacto.gd` (hitstop, tremor e som do golpe), `scripts/esquiva.gd`,
  `scripts/camera_do_heroi.gd`, `scripts/limites.gd`.
- `scripts/salto.gd`: pulo de plataforma com coyote time, buffer, altura variável e gravidade assimétrica.
- `scripts/previa_do_editor.gd`: `@tool` que veste a fase dentro do editor com o mesmo código do jogo.
- `perso1.gd`: política de entrada e controle do jogador (protótipo paralelo).
- `galinha.gd`: comportamento de patrulha e animação da galinha inimiga.
- `scripts/character_movement.gd`: primitivas compartilhadas de movimento para `CharacterBody2D`.
- `scripts/sprites.gd`: monta os `Sprite2D` dos personagens ancorados pelo pé.
- `scripts/terreno.gd`: layout editável → colisão + textura, por região da fase.
- `scripts/tochas.gd`: tochas animadas com halo e luz de verdade (`PointLight2D`).
- `scripts/iluminacao.gd`: escuridão ambiente (`CanvasModulate`) que fecha a cada região; tochas, braseiros acesos e o herói abrem poças de luz.
- `scripts/hud.gd`: HUD em ícones (barra de vida, vidas como chamas acesas/apagadas, ovos, galinhas; moedas fora da partida). Ícones em `tools/arte/icones.py`. A barra da Galinha Real fica embaixo, com nome.
- `scripts/adornos.gd`: espalha adornos no topo das plataformas, com semente no nome da plataforma (sempre os mesmos lugares, no editor e no jogo).
- `scripts/superficie.gd`: altura do chão num X, lida dos vértices dos `Polygon2D` (funciona no editor, onde não há raycast). Na fazenda as tochas descem até esse chão e ganham poste; sobre um vão elas somem.
- `scripts/acabamento_do_terreno.gd`: sombra de profundidade (`vertex_colors`) e contorno escuro em cada bloco de terreno.
- `tema_pixel.tres`: fonte, cores e bordas da interface, num lugar só.
- Arquivos `.tscn`: composição dos personagens e das fases; mantenha caminhos de recursos alinhados com os scripts anexados.

### Primitivas compartilhadas

`CharacterMovement` concentra gravidade, aceleração/atrito horizontal, desaceleração e orientação do sprite. Controladores decidem *quando* chamar cada operação (entrada do jogador ou IA do inimigo); regras físicas comuns são alteradas uma vez no módulo compartilhado. Para novas entidades, reutilize essas funções e mantenha no controlador apenas as decisões específicas da entidade.

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
A Chama do Ninho, que mantinha a Fazenda Brasa Viva acesa, foi roubada pelas
galinhas, cansadas da grelha. Ao iniciar (com prólogo na primeira vez), escolha
Guerreiro (espada), Arqueiro (arco) ou Mago (varinha), desça até o ninho e vença a
Galinha Real. No caminho há galinhas comuns, Galos de Briga (bote pelo chão) e
Galinhas Atiradeiras (ovos em arco). Cada braseiro aceso cura e vira ponto de
volta, e há 3 vidas por tentativa. A Galinha Real avisa cada golpe com uma cor:
amarelo é investida (esquive), laranja é salto com onda de choque (pule) e
vermelho é leque de penas. Os ovos têm cinco raridades e são vendidos automaticamente
na vitória. A armadura cômica da Galinha Real
(bico, crista e barbela) tem 90% de chance de drop. A loja entre tentativas vende
armas e melhorias permanentes, salvas localmente. Perder as 3 vidas reinicia o nível e
perde os ovos da tentativa.

Controles (definidos no input map, em `project.godot` → `[input]`, lidos por
posição física de tecla, então ABNT2 não precisa de remapeamento):

| Ação | Teclado | Controle |
| --- | --- | --- |
| `andar_esquerda` / `andar_direita` | A/D ou ←/→ | analógico esquerdo, direcional |
| `pular` | Espaço, W ou ↑ | A |
| `atacar` | J, K ou clique esquerdo | X |
| `esquivar` | Shift ou L | B |
