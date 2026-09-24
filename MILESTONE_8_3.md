# Milestone 8.3 — Carrasco Base: sprite de gameplay

## Fonte visual e escala

- Fonte visual única: a prancha oficial **Forma Base Carrasco** fornecida pelo usuário, preservada em `assets/reference/carrasco_base_official.png`. Não foram usados Carrascos com espada nem artes das evoluções.
- Os PNGs de 8.2 e tentativas de folhas geradas automaticamente foram avaliados. Na escala de gameplay, os detalhes da máscara se tornavam ruído, o fundo quadriculado apareceu em algumas saídas e a arma variava entre quadros. Essas folhas foram rejeitadas como asset final; os quatro PNGs provisórios de 8.2 foram removidos do projeto.
- O atlas entregue foi desenhado diretamente em pixels lógicos, inspirado exclusivamente na silhueta da prancha oficial: capuz, máscara de grade vertical, armadura bronze escura, ombros largos, tecidos gastos, dois elos de corrente e machado único de duas mãos. O desenho simplifica detalhes que não sobrevivem à escala de jogo.
- O placeholder humano atual ocupa **27 px** do topo da cabeça aos pés. O Carrasco Base ocupa **31 px**, ou **114,8%** da altura humana. A referência de 35–36 px pressupunha um humano de cerca de 32 px; foi priorizada a proporção aprovada de 110–115% sobre esse exemplo absoluto.
- Cada tile mede 64×48 px para acomodar capa, membros e arco da arma; o corpo não ocupa o tile todo. A origem dos pés é `(17,42)` no tile, deslocada para `(0,13)` no Player. Sprites usam escala 1:1 e filtro nearest, sem suavização. O atlas mede 640×528 px.

## Sistema de animação

- `tools/generate_carrasco_gameplay.gd` gera deterministicamente `atlas.png` e `frames.json` na resolução nativa. Desenha poses completas quadro a quadro a partir de pixels e polígonos inteiros. A mesma geometria de cabeça e cabo do machado é usada em todas as poses; o cabo mantém 33 px. Dois braços terminam nos pontos de pegada da arma.
- `CarrascoBaseVisual` carrega os tiles como `AtlasTexture` em um `Sprite2D` próprio da cena de visual da Máscara. O Player informa pose, fase e progresso; a arte escolhe o quadro. Ela não move o Player, a hitbox ou o relógio de combate.
- Windup, active e recovery escolhem faixas diferentes do atlas usando o progresso **da fase mecânica já existente**. As animações de idle, corrida, carga, dash, hurt e morte usam relógio apenas visual. A ativação do Tribunal dura visualmente 0,24 s, sem impedir ataques; durante Tribunal as animações normais continuam com aura local.
- Common Execution e Execution Strike usam sequências próprias. A segunda não usa a leitura de morte instantânea.

| Animação | Quadros |
| --- | ---: |
| Idle / Run | 4 / 6 |
| Jump / Fall | 2 / 2 |
| Ground Dash / Air Dash / Parry | 3 / 3 / 3 |
| Light 1 / Light 2 / Light 3 | 4 / 4 / 4 |
| Heavy / charge loop / charge ready / Charged Heavy | 6 / 4 / 2 / 6 |
| Post-Dodge / Air Light / Air Heavy | 4 / 4 / 5 |
| Quebra-Selos / Marca do Condenado | 5 / 4 |
| Ativação do Tribunal | 4 |
| Execution comum / Execution Strike | 8 / 6 |
| Hurt / Ruptured / Death | 3 / 3 / 5 |

**Total: 104 quadros em 25 animações.**

## Integração e efeitos

- Light 1 avança horizontalmente; Light 2 sobe; Light 3 desce como finalizador. Heavy tem antecipação mais longa no atlas; Charged Heavy separa carga, pronto e liberação. Post-Dodge é uma investida baixa. Air Light é frontal e Air Heavy prepara um corte descendente.
- Quebra-Selos tem pixels de ruptura concentrados perto da lâmina. Marca do Condenado usa um gesto elevado e símbolo local. O componente de marca no alvo continua mostrando os 0–5 segmentos reais. Tribunal usa ativação própria e aura limitada ao personagem. VFX de impacto de 8.2 continuam reutilizados.
- `AttackPivot`, hitbox, hurtbox, collider de 26 px, ângulos, alcance, timings, cancel windows, dano, Posture, cooldowns e resolução de Execution permanecem mecânicos e inalterados. A cabeça do machado chega aproximadamente a 34 px à frente da raiz visual em golpes longos; o limite ofensivo real continua o da hitbox (aproximadamente 32 px em Light 1). O contorno artístico excede esse limite em cerca de 2 px, sem colisão própria.
- O visual espelha com `VisualRoot.scale.x` já usado pelo Player; a arma, os pontos de pegada e a aura seguem a mesma direção. O slot humano vazio e o segundo slot técnico continuam funcionando.
- Na arena técnica, **F3** alterna o HUD e os avisos de debug sem remover sua lógica. As capturas foram feitas com o HUD oculto.

## Validação

- Godot 4.7.2 stable importou o atlas e executou a arena em OpenGL Compatibility. Foram capturados os 15 estados solicitados, estados extras e uma comparação humano/Carrasco na resolução real 480×270 (janela 960×540). As capturas ficam fora do repositório, em `outputs/milestone8_3/`.
- `verify_milestone8_3.gd` verifica a contagem, as animações principais distintas, a escala e o pivô, filtro nearest, fases e hitbox, ativação do Tribunal, Execution Strike, swap, F3 e os nove pares de dano/Posture.
- A bateria completa dos Milestones 2–8.3 foi executada após a integração: **12 testes, 12 aprovações**, todos com código de saída 0. O editor também foi fechado e reaberto após a importação final do atlas, sem erro de script.
- Aviso ambiental conhecido: Godot não conseguiu ler o armazenamento de certificados raiz do Windows. Não houve erro de script ou importação relacionado ao projeto.

## Limites e aprovação

- Esta é uma versão de gameplay em pixels nativos, com identidade simplificada para a escala aprovada. Correntes, placas e tecido ainda podem receber refinamento artístico após avaliação humana; a prancha oficial permanece a referência superior.
- O Bosque não foi integrado definitivamente. Áudio final, câmera cinematográfica, HUD final e formas evoluídas não foram criados.
- A aprovação estética **não é presumida**. A próxima evolução depende da avaliação visual do usuário sobre as capturas e o jogo.
