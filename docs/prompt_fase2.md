# Prompt: Fase 2 — o Chiqueiro

> Cole o bloco abaixo numa sessão nova do Claude Code, aberta na raiz deste
> repositório. Ele foi escrito em 13/11/2026, depois da fase 1 ficar completa
> (jogabilidade, história, som, visual e versão mobile).
>
> A campanha confirmada pelo Jorge: galinhas (fase 1), **porcos (fase 2)**, e o
> chefe final é um sanduíche/hambúrguer gigante (ver "A ideia do jogo" no
> README). Os nomes, regiões e inimigos abaixo são proposta; ajuste à vontade.

---

Quero criar a **fase 2** do Grill or Be Grilled: **o Chiqueiro**, a fase dos
porcos. Leia antes `README.md`, `PENDENCIAS.md` e o código da fase 1. Tudo o que
está lá (pipeline de arte, testes, iluminação, HUD, controles de toque) deve ser
reaproveitado, não refeito.

## Onde a história está

A fase 1 termina com a Galinha Real fugindo pelo túnel do porão
(`Historia.QUEDA_DO_CHEFE` e `Historia.EPILOGO`: "Isto não acabou,
cozinheiro..."). A fase 2 começa onde o túnel sai: no **chiqueiro** da fazenda
vizinha. Lá os porcos, que também têm pavor da grelha (pernil, costelinha,
leitão à pururuca), se aliaram às galinhas. A Galinha Real se esconde com eles.
Proposta de chefe: o **Barão Pernil**, um porcão de cartola que defende a
Galinha Real. O tom é cômico e caricato, como o resto do jogo: o Barão se acha
nobre demais para virar torresmo.

O fim da fase 2 deve apontar para o chefe final do jogo, um **sanduíche/hambúrguer
gigante**. Proposta: derrotado, o Barão confessa que galinhas e porcos só
obedecem a "Sua Majestade, o X-Tudo", que quer juntar todas as carnes da fazenda
num lanche só. A Galinha Real foge de novo, levando o recado. Não implemente o
hambúrguer agora: só o gancho na história.

## O que já existe e está amarrado à fase 1

Antes de criar conteúdo, transforme em dado da fase o que hoje é constante:

- `fase1.gd`: `LEVEL_END := 10000.0`, a música `musica_fase1` e o fluxo inteiro
  (início, vidas, checkpoint, chefe, vitória, loja). Ele mistura o fluxo genérico
  de uma fase com o conteúdo da fase 1.
- `jogo.tscn` é a única cena jogável. O layout é editável no editor do Godot
  (`EditorPreview/Cenario` com `Polygon2D`, marcadores `Tocha*`, `Marco*`,
  `Bots`, `Ovos`, `Braseiros`).
- `scripts/terreno.gd`: as regiões são fronteiras fixas em X (`FIM_DA_FAZENDA`,
  `FIM_DA_ENTRADA`), e `MATERIAIS` só conhece `fazenda`, `entrada` e `porao`.
  `scripts/iluminacao.gd` (`AMBIENTE`) e `scripts/adornos.gd` (folhas
  `adornos_<regiao>`) dependem dessas mesmas regiões.
- `scripts/historia.gd`: todo o texto é da fase 1.
- `scripts/bestiario.gd`: tipos de inimigo vindos de `metadata/tipo` do marcador.
- `game_data.gd`: o save não sabe qual fase foi vencida (`phase_won` é um bool).
- `chicken_boss.gd`: chefe com golpes telegrafados por cor e duas fases de vida.
  É o modelo para o chefe novo.

## Como fazer (em camadas, cada uma funcionando antes da próxima)

1. **Fase como dado.** Separe o fluxo genérico de fase (vidas, checkpoint,
   chefe, vitória) do conteúdo da fase 1. Cada fase declara: cena de layout,
   fim do nível, regiões com fronteira e material, música, textos e chefe. A fase 1
   precisa continuar idêntica: todos os testes de `tools/testar.sh` passando e as
   capturas de `ferramentas/capturar_cenas.tscn` iguais às de antes. Não deixe
   caminho de compatibilidade: o código velho que ficar obsoleto sai.
2. **Progressão.** O save passa a guardar as fases vencidas. A fase 2 é
   desbloqueada ao vencer a fase 1. O menu ganha a escolha de fase, e o
   epílogo da fase 1 leva para ela. A loja continua entre tentativas.
3. **Cenário do chiqueiro** em `tools/arte/` (rampas de `tools/arte/rampas.py`, mesmo estilo esculpido). Proposta
   de regiões: *Pocilga* (lama, cerca de ripas, cocho), *Celeiro de Milho* (sacas,
   espigas, palha) e *Defumadouro* (fumaça, ganchos, linguiças penduradas, a arena
   do chefe). Cada região tem tiles, faixa com franja, parede de fundo, adornos,
   cor ambiente e silhueta de horizonte própria.
   **Mecânica de terreno nova:** poças de lama que deixam o herói lento e com pulo
   mais baixo. Calibre os vãos com `teste_das_passagens`, que hoje assume o arco
   de pulo cheio.
4. **Inimigos porcos**, no padrão de `chicken_enemy.gd` e `bestiario.gd`:
   - *Leitão*: rápido e fraco, corre em linha e pula vãos pequenos.
   - *Porco Lamacento*: lento, com mais vida; ao ser atingido, solta lama que
     deixa o herói lento por um instante.
   - *Javali*: carga longa telegrafada (raspa a pata, depois dispara). Esquivar
     através dele é a resposta, ensinando a esquiva da fase 1.
   Galinhas da fase 1 aparecem em menor número, misturadas aos porcos.
5. **Chefe: Barão Pernil.** Três golpes telegrafados por cor, legíveis como os da
   Galinha Real:
   - *Barrigada*: investida que atravessa a arena; o herói pula por cima.
   - *Chuva de lama*: bolas em arco com sombra no chão; o herói sai do lugar.
   - *Chamar leitões*: dois Leitões entram pelas laterais.
   Abaixo de metade da vida ele se enfurece, como a Galinha Real. No fim, a
   Galinha Real foge de novo. O drop especial é a *cartola do Barão* (cosmético,
   como a armadura da galinha).
6. **História, som e polimento.** Textos novos em `historia.gd`, separados por
   fase: prólogo curto da fase 2, placas por região e falas do chefe. Música nova
   em `tools/gerar_sons.py` e efeitos de porco (ronco e guincho). Capturas novas
   de cada região.

## Regras

- Siga o `CLAUDE.md` global: funções curtas, nomes específicos, sem
  duplicação, um teste por função nova, mensagens de erro com o valor recebido.
- Toda arte nova é gerada por `tools/gerar_arte.py`, nada é desenhado à mão no
  `.tscn`. O layout da fase 2 continua editável no editor do Godot, com a mesma
  prévia vestida (`scripts/previa_do_editor.gd`).
- Cada camada termina com `tools/testar.sh` verde, capturas conferidas
  visualmente, README e PENDENCIAS atualizados, commit e push.
- A fase 2 tem que funcionar no celular: controles de toque, tela larga
  (`aspect="expand"`) e `tools/exportar.sh web`. Confira o build Web antes do
  último commit.
- Dificuldade: a fase 2 é mais difícil que a 1, mas cada inimigo novo aparece
  primeiro sozinho, em lugar seguro, antes de vir combinado com outros.

## Ao terminar

Resuma o que foi feito por camada, o que ficou de fora e por quê (com entrada em
`PENDENCIAS.md`) e os números de balanceamento que foram palpite e pedem uma
partida jogada para afinar.
