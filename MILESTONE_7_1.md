# Milestone 7.1 — revisão da primeira fatia jogável do Bosque

## Ponto de partida

Revisão iniciada em `main`, a partir de `c325fad9da0b5446df87137e1710eabff05109c2`. O único arquivo já modificado era `project.godot`, regravado pelo editor: eventos do Input Map em forma expandida, comentário padrão, remoção das linhas explícitas `window/stretch/aspect="keep"` e `textures/default_filters/use_nearest_mipmap_filter=false`. O Godot 4.7.2 continuou resolvendo esses dois valores como `keep` e `false`; a forma compacta anterior também carrega eventos de teclado com dispositivo interno `16`. A alteração preexistente foi preservada. Ela não motivou mudança nas ações ou na resolução de 480×270.

Antes de editar o gameplay, a cena abriu no editor e em janela, `verify_milestone7.gd` passou em tempo fixo, e as regressões 2–6 passaram em tempo real. Os testes antigos 2–4.1 falham se forçado `--fixed-fps 60` por suas próprias expectativas temporais; também falhavam assim antes desta revisão. O Milestone 7 usa seu próprio modo fixo e em tempo real.

## Diagnóstico dos cinco encontros

As distâncias abaixo são horizontais desde o início do Player em x=120. Cada `ForestEncounter` ativa quando o Player chega a ±345 px de seu centro. Áreas úteis são trechos aproximados de chão aberto, sem paredes de arena.

| Encontro | Inimigos e posições finais | Distância desde o início | Área útil e plataformas | Fuga, IA e riscos observados |
|---|---|---:|---|---|
| 1 | Peregrino x=1200, y=212 | 1080 px | Chão x≈850–1600; primeira plataforma em x=1680 | Livre para recuar; a leste o corpo do Peregrino bloqueia corrida pura. Pulo cronometrado evita a luta. Persegue e ataca, sem borda próxima para cair. Legível como primeiro duelo. |
| 2 | Raiz x=2750, y=219 | 2630 px | Chão x≈2300–3300; patamar só em x=3300; sem plataforma próxima | Corrida contínua passa antes da emboscada atingir o Player. Marca e ataque funcionam quando ele permanece na área. Não ficou presa nem caiu no solo plano. |
| 3 | Corvo x=4220, y=145 | 4100 px | Chão x≈3800–4700; plataforma seguinte em x=4800; altura livre | Corrida no chão pode passar sem receber ataque. Em combate usa espaço vertical, rasante e projétil; patrulha dentro dos limites. Um Corvo morto bloqueava a passagem ao cair: defeito corrigido nesta integração. |
| 4 | Corvo x=5355, y=145; Peregrino x=5545, y=212 | 5235/5425 px | Chão x≈5100–5900; plataforma anterior em x=4800 | Corvo agora percebe primeiro; Peregrino entra depois. Antes, Peregrino à frente podia barrar o Player e ocultá-lo da linha de visão do Corvo. É possível saltar o Peregrino e fugir. Nenhum ficou preso ou caiu. Ataques independentes podem coexistir; captura em janela mostrou leitura separada, mas justiça exige playtest. |
| 5 | Raiz x=6975, y=219; Peregrino x=7145, y=212 | 6855/7025 px | Chão x≈6600–7500; sem plataformas próximas | Raiz agora marca a aproximação antes de o Peregrino entrar. Antes, o Peregrino à frente podia segurar o Player fora do alcance da Raiz. Pulo evita o Peregrino. Ambos ficam no chão correto; avisos vistos separadamente em janela, sem prova automática de justiça. |

Os centros dos encontros continuam separados por 1550, 1470, 1230 e 1600 px. O primeiro é simples, depois Raiz e Corvo sozinhos, por fim dois pares. Não há trio simultâneo nem parede invisível. Nenhum inimigo foi acelerado, teve alcance alterado ou recebeu leitura de entrada do jogador.

## Problemas confirmados e ajustes

1. **Recuperação de queda:** `recover_from_fall()` devolvia `air_dash_available` imediatamente, antes de o corpo confirmar novo contato com o chão. Agora zera essa disponibilidade na recuperação; `PlayerDefense.sync_grounding()` a devolve após uma aterrissagem real. HP e encontros permanecem intactos.
2. **Entrada dos pares:** trocadas somente as posições provisórias dos inimigos dentro dos encontros 4 e 5. Corvo e Raiz sinalizam primeiro, seguidos pelo Peregrino. As cenas e os recursos de dados dos três inimigos não mudaram.
3. **Cadáver bloqueando percurso:** uma travessia com ataques reais parou em x≈4270 diante do Corvo morto, cujo corpo ainda colidia com o Player. `ForestEncounter` agora cria uma exceção de colisão entre Player e inimigo morto e a remove no reset. A colisão com o chão permanece, de modo que o Corvo continua caindo visualmente. O teste atravessa a posição do cadáver e verifica a restauração no reinício.

**Não precisou de alteração:** extensão da fase, plataformas, largura do vão, altura do patamar, câmera global, velocidade e alcance de ativação, física do Player, duração ou i-frames do Air Dash, kits e números canônicos dos inimigos, arte placeholder e sistemas de combate existentes. `project.godot` não teve seu conteúdo preexistente revertido.

## Travessias medidas

| Roteiro automatizado | Resultado | Tempo de jogo | Observação |
|---|---|---:|---|
| Rápido, sem combates na geometria | Fim alcançado | 66,2 s | Teste de terreno com encontros isolados; serve como limite inferior de deslocamento. |
| Combatendo com entradas de movimento, Light, pulo e Dodge | Cinco encontros derrotados; fim alcançado; 6 HP; zero reinício | 81,3 s | Controlador automatizado agressivo, com conhecimento técnico dos alvos. **Não representa ritmo humano normal.** Antes da correção do cadáver, parava após o terceiro encontro. |
| Evitando todos os combates | Fim alcançado; 100 HP; cinco encontros ativados, nenhum concluído; sete pulos e um Air Dash | 65,7 s | A evasão integral continua fácil para um roteiro que conhece as posições. |

A meta de **2–4 minutos em uma travessia humana normal com combate** ainda não foi validada. Não se acrescentou corredor vazio nem atraso artificial para forçar o cronômetro. O resultado de evasão é uma pendência real de ritmo e incentivo: hoje a corrida automatizada é mais rápida e segura do que combater. Decidir se os encontros precisam de nova geometria, recompensas futuras ou outro incentivo exige jogar a fatia; a revisão atual corrigiu falhas objetivas sem fechar artificialmente as arenas.

## Validação técnica

- Godot 4.7.2: importação no editor, abertura da cena em janela, renderização dos encontros e saída, sem erro de script.
- `tests/verify_milestone7_1.gd`: ordem de percepção dos pares, cadáver atravessável e restaurado por `R`, queda sem HP, Air Dash devolvido após aterrissagem, câmera e limites nas duas extremidades.
- `tests/verify_milestone7.gd`: cinco encontros, IA, pulo, vão, Air Dash, recuperação, câmera, reset, morte técnica, projéteis, simulações longas e travessia.
- Regressões dos Milestones 1–6; cena base do Milestone 1 e verificadores 2–6 em tempo real. Verificadores 7 e 7.1 também em tempo fixo.
- Execução longa de Peregrino+Corvo e Peregrino+Raiz não mostrou fuga dos limites, queda indevida ou acúmulo de projéteis.

O ambiente de execução emitiu avisos externos recorrentes sobre certificados raiz, gravação de logs/preferências do editor e cache de shaders. Eles não impediram abertura ou gameplay. Não foi observado erro de script da fase.

## Ainda precisa de avaliação jogando

- Se a evasão integral com sete pulos é fácil para uma pessoa sem conhecer antecipadamente os inimigos.
- Tempo, dificuldade e diversão de um percurso humano com combate, exploração curta e recuperação de queda; especialmente a meta de 2–4 minutos.
- Leitura dos dois pares sob ataques realmente simultâneos, precisão de Parry/Dodge e clareza das marcas da Raiz.
- Conforto da câmera, percepção das plataformas e do vão, e utilidade do Air Dash em combate.

## Arquivos desta revisão

- `scenes/biomes/forest/forest_slice_01.tscn`: posições provisórias dos pares.
- `scripts/biomes/forest/forest_slice_01.gd`: recarga de Air Dash após aterrissagem.
- `scripts/biomes/forest/forest_encounter.gd`: exceção de colisão com cadáver e reset.
- `tests/verify_milestone7_1.gd` e UID gerado pelo Godot: regressão específica da integração.
- `MILESTONE_7_1.md`: este registro.
- `project.godot`: alteração do editor existente antes da revisão, preservada e verificada quanto à configuração efetiva.
