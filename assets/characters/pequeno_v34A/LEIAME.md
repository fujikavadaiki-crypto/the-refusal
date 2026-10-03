# pacote_pequeno_v34A — Carrasco pequeno v3.4, proporção A (cabeça ≈31 %) — CORRIDA v2 + DASH com SMEAR curto

v33A (corrida aprovada) com o DASH refeito (P42b); antes, v32A + corrida/dash refeitos (referência de fluidez: gameplay do Skul). Mesmo formato (manifesto_sprites.json, quadros PNG, sombra por animação, âncora nos pés, paleta C5.1 travada de 44 cores; usa 22), efeitos em camada separada e hitbox por quadro ATIVO recortada à frente do corpo. **Todas as animações que não são corrida/dash (golpes, hitboxes, tempos, idle, parry, carga…) são idênticas, byte a byte, às da v32A; corrida, partida e freio são idênticos aos da v33A.**

26 animações; o que mudou:
- **run (8 q, 6 px/q = 41,67 ms; 144 px/s; 48 px por ciclo — mesma velocidade de antes)**: tronco MUITO inclinado (~26°) e baixo; capa LONGA arrastando atrás em onda (a onda viaja para trás, atraso de 1 quadro, ponta balançando ±3 px por passo, barra recortada); cabeça sobe 1 px a cada passo; lâmina baixa arrastando atrás com leve balanço; pernas curtas (corpo agachado). Cada pé fica no chão 3 quadros (calcanhar → pé chato → ponta) SEM deslizar (`verificacao/pes_corrida.json`: 0 px). Quadros de apoio para parar: `apoios` = [1, 5].
- **run_start (1 q)**: inclina forte, capa ainda caída; dura os primeiros 6 px.
- **run_stop (1 q, 66 ms) — NOVO**: freio derrapando; a capa passa para a frente das pernas.
- **dash / dash_ar (4 q = 350 ms, P42b)**: ARRANQUE (corpo comprimido, poeira só no chão) 50 ms → **SMEAR (1 q, 60 ms)**: vírgula COMPACTA (capuz na frente, corpo grosso que afina numa cauda curva; ≈1,2× a largura do corpo, não uma faixa longa) → **POSE ESTICADA (190 ms)**: corpo inclinado e baixo, perna da frente esticada e a de trás arrastando, capa LONGA reta atrás, lâmina recolhida junto às costas → FREIO (derrapa, capa para a frente, poeira só no chão) 50 ms. Dash no ar: mesmos quadros, sem poeira. Só cores da paleta C5.1.
- Rastro (apresentador): fantasmas em vermelho-sangue escuro (índice 22), alfa 0,5→0 em ~110 ms, no máx. 3 (antes 150 ms/4); no ataque pós-dash, mais curto ainda (≤ 2). Parâmetros em `rastro_dash` do manifesto.
- Física, área de dano e hurtbox NÃO mudam (o dash continua 112 px em 0,35 s).
- Geradores (numpy) em `geradores/mao32/` (v6rig/v6poses/v6pack = esta versão). Prova: `prova/tira_x2.png`.
