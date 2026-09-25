# Grill or Be Grilled

Projetinho de criação de jogo com Douglas e Jorge (Doujor/ Dojór)

## Estrutura de código

O projeto Godot fica em `grill-or-be-grilled/`.

- `perso1.gd`: política de entrada e controle do jogador.
- `galinha.gd`: comportamento de patrulha e animação da galinha inimiga.
- `scripts/character_movement.gd`: primitivas compartilhadas de movimento para `CharacterBody2D`.
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
