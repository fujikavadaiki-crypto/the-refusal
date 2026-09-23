# Milestone 7 — primeira fatia jogável do Bosque dos Esquecidos

## Escopo e fontes

Abra `scenes/biomes/forest/forest_slice_01.tscn` com **F6** no Godot 4.7.2. É uma cena artesanal independente. A sala de teste e as arenas técnicas dos três inimigos permanecem disponíveis. Esta fatia não representa a Etapa 1 completa nem uma das 24 variantes definitivas.

A Bíblia Canônica e Técnica v3.0 prevalece para regras; a Bíblia Visual Oficial v1.0, página 3, e a Bíblia Canônica do Bosque v2.0, página 4, orientam aqui somente a identidade da **Entrada do Bosque**: natureza reconhecível, ruínas discretas, corrupção sutil, espaço lateral longo e progressão visual mais leve que as etapas posteriores. A menção antiga a dano de queda na Bíblia do Bosque não se aplica: a regra atual é **sem dano de queda**, conforme o pedido deste milestone e as decisões textuais mais recentes. Todos os cenários são placeholders de escala e composição, sem arte definitiva.

## Layout e ritmo

O percurso tem **8.200 px** de extensão, ou cerca de 17 telas de 480 px. O jogador começa em x=120, em solo seguro; a saída debug fica em x=8.050. O chão mantém base visual em y=228, com um vão de 60 px em x=1.900–1.960 e um patamar de 14 px de altura em x=3.300–3.800. Plataformas atravessáveis por baixo oferecem rotas de salto e Air Dash no trecho de exploração e antes do Corvo. Não existem paredes de arena nos encontros.

| Trecho aproximado | Função |
|---|---|
| x=120–850 | entrada, orientação e travessia tranquila |
| x≈1.200 | Peregrino sozinho em chão plano |
| x≈1.600–2.150 | plataformas simples, vão curto e recuperação de queda |
| x≈2.750 | Raiz sozinha em terreno plano e legível |
| x≈3.300–3.800 | respiro e patamar baixo |
| x≈4.220 | Corvo sozinho com altura livre e chão visível |
| x≈5.450 | Peregrino + Corvo, sem sincronização artificial |
| x≈7.050 | Peregrino + Raiz, com aviso do solo desobstruído |
| x≈8.050 | saída provisória com mensagem de fim da fatia |

Uma travessia contínua **sem combate** levou **66,2 s simulados**, usando pulo no vão e no patamar. Uma corrida em janela, com os cinco encontros ativos e entradas automatizadas, também alcançou a saída em **66,2 s**: sete saltos evitaram todos os golpes e o Player terminou com 100 HP. Isso confirma que lutar não é obrigatório; também sinaliza que a rota de evasão pode estar fácil demais. A meta de 2–4 minutos com leitura, combate e exploração ainda precisa de medição em playtest humano; não foi transformada em cronômetro obrigatório nem alongada com corredores vazios.

## Arquitetura

- `ForestSlice01` cuida somente da navegação da fatia: posição inicial, limite da câmera, posição segura recente, recuperação de queda, reset técnico, morte provisória e marcador final.
- Cada `ForestEncounter` conhece seus inimigos e os acorda quando o jogador entra em uma faixa de 345 px do centro. Após a ativação, cada IA existente decide seus próprios movimentos e ataques; o componente só registra a conclusão quando todos morrem e oferece reset. Não existe fila de ataques, buff, escala de dificuldade ou diretor procedural.
- Peregrino, Corvo e Raiz são instâncias das mesmas cenas testadas nos Milestones 4–6. Nenhum dado canônico de dano, IA, alcance ou tempo desses inimigos foi alterado.
- `ForestBackdrop` e `ForestVegetation` desenham árvores, musgo, ruínas e profundidade com poucos elementos de cor discreta. São placeholders sem colisão; permanecem atrás de personagens, projéteis e telegraphs. A paleta usa verde, oliva, terra, carvão e pedra, sem vermelho como corrupção dominante.

## Câmera e navegação

A câmera existente mantém o protagonista como foco, com look ahead de 60 px e limites x=0–8.200/y=0–270. O Corvo opera dentro da altura já aprovada para a arena técnica e não controla a câmera. O patamar de 14 px e as plataformas não exigiram alteração de movimento ou Air Dash.

A posição segura é atualizada somente quando o Player está no chão, longe das bordas, com chão estável sob os dois lados e sem inimigo vivo próximo. Se cair abaixo de y=355 ou sair dos limites, volta a esse ponto, sem perder HP e sem reiniciar a fase. Esse registro é transitório e não é checkpoint persistente. Na morte, aparece uma mensagem de **reset técnico provisório** antes de reiniciar a fatia; o sistema canônico de A Recusa e autosave ficam para marcos futuros.

## Controles e depuração

Controles existentes: **A/D** ou setas para mover, **Espaço** para pular, **J/K** para Light/Heavy, **L** para Dodge ou Air Dash, **I** para Parry. **R** reinicia tecnicamente a fatia: Player, HP/Postura, Air Dash, todos os inimigos, IAs, emboscadas, Ruptura e projéteis. **F3** alterna as etiquetas debug dos inimigos, ocultas por padrão para preservar a leitura. O texto de HP/Postura do Player também continua provisório. Entrar na passagem final mostra “FIM DA FATIA — MILESTONE 7”, sem carregar outro bioma.

## Validação

`tests/verify_milestone7.gd` cobre carregamento, entrada segura, composição dos cinco encontros, alvo correto de cada IA, ativação local, solo e plataformas, pulo e Air Dash sobre o vão, câmera, safe position, queda sem dano, saída, conclusão e reset dos encontros, limpeza de projéteis, morte técnica e ausência de loot/sistemas futuros. Simula três minutos de Peregrino + Corvo e um minuto de Peregrino + Raiz, checando limites, ataques e projéteis. A cena foi aberta em janela renderizada para verificar escala, composição e legibilidade dos cinco pontos do percurso.

O verificador do Milestone 7 passou em execução acelerada e em tempo real no Godot 4.7.2. As regressões dos Milestones 1, 2, 3, 4, 4.1, 5 e 6 passaram, incluindo as simulações longas anteriores. A cena inicia com cerca de **255 Nodes**. O limite de projéteis foi verificado durante três minutos de encontro combinado e o reset removeu os projéteis ativos. Não houve erro de script ou colisão detectado nesses percursos. O ambiente Windows apresentou o aviso recorrente de falha ao ler certificados raiz; o modo renderizado também avisou que não pôde gravar o cache de shader neste ambiente, sem impedir a execução.

Os percursos em janela foram conduzidos por entradas automatizadas, com inspeção visual em início, plataformas, Raiz, Corvo, encontros combinados e saída. Ainda falta **playtest humano** completo dos seis estilos pedidos (normal, Parry, Dodge/Air Dash, evasão, exploração e queda), especialmente para avaliar dificuldade real, sobreposição dos golpes, legibilidade e tempo total com combate.

**CANÔNICO:** sem dano de queda; ordem e identidade dos sistemas e inimigos já aprovados. **PROVISÓRIO DE PLAYTEST:** extensão de 8.200 px, distâncias entre encontros, janela de ativação de 345 px, posições, alturas e largura do vão, limiar y=355 de recuperação e temporização de 0,9 s do reset por morte. **PLACEHOLDER:** árvores, ruínas, vegetação, plataformas, passagem e mensagens debug. Arte final, geração procedural, Status, loot, save da run, outros inimigos e bioma completo não foram iniciados.
