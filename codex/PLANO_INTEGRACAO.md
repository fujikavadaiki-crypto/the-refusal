# Tarefas 4.0–4.2 — Plano de integração do Pequeno A no jogo principal

**Fases 1–3 aprovadas tecnicamente. Tarefa 4.3: sala inicial do mapa congelado do P40**, com Pequeno A v34A, sombra única, corrida por distância e dano por quadro já integrados. Bosque B preservado e acessível por F9. Relatórios anteriores mantidos; entrega atual: `RELATORIO_INTEGRACAO_P40_F4.md`. Avaliação visual/jogada da sala nova permanece com o usuário.

**Destino de integração:** `C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40`, branch `feature/integracao-p40`, criada a partir de `main` no commit `ef24b5561cacb823d1f719370c29d82522cb5b58`. Esta cópia permite preservar a branch e as alterações locais do usuário em `C:/Users/daiki/Documents/Codex/The Refusal/the-refusal`.

**Referência somente leitura:** `C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40`, atualmente **P42b / Pequeno A v34A** (`pacotes/pequeno_v34A`). README ainda começa com Protótipo 41, mas seletor e `RELATORIO_P42b.md` identificam o pacote atual. A fonte inicial foi P41/v32A, seguida de P42/v33A; preservar o histórico abaixo. Não renomear nem editar a referência, não importar/executar seu projeto no Godot nem usar seus temporários como destino.

**Plano anterior, preservado:** [Tarefa 3.7 — PLANO_INTEGRACAO.md](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/codex/PLANO_INTEGRACAO.md>). Este documento o atualiza para a referência jogável atual e as decisões do usuário. As observações sobre o código principal se referem à base `main@ef24b556`; as linhas poderão mudar durante a integração.

## 1. Fontes, decisões e limites das fases 1–3

| Fonte atual, lida sem alteração | Contrato fornecido |
|---|---|
| [README.md](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/README.md>) e [RELATORIO_P42b.md](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/RELATORIO_P42b.md>) | Produção = **PEQUENO A v34A**; v33A/v32A, Grande e Pequeno B arquivados. TAB no protótipo é acesso histórico. |
| [personagens_p40.gd](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/personagens_p40.gd>) | `PEQUENO_A = res://pacotes/pequeno_v34A/`; v33A/v32A arquivadas. Leitura de animações, quadros, âncoras, polígonos, efeitos, sombras e hashes; apoios da corrida 1/5. |
| [manifesto_sprites.json](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/pacotes/pequeno_v34A/manifesto_sprites.json>) | Pacote `pacote_pequeno_v34A`, 26 animações, altura idle 48 px, cápsula de **raio 7 px e altura total 46 px**. P42b altera apenas dash/dash_ar para smear compacto; física, hurtbox e danos iguais à v33A. |
| [presenter_p40.gd](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/presenter_p40.gd>) | Apresentação ×1 NEAREST, âncora nos pés, corrida por distância real, apoio visual por dois ticks seguido de `run_stop` por 66 ms, transições, sombra, rastro configurado pelo manifesto e seleção comum de quadro para arte/dano. |
| [prototipo.gd](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/prototipo.gd>), [config_combate.json](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/config_combate.json>) e [config_sensacao.json](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/config_sensacao.json>) | Corrida M3 = 4,5 m/s; dash B2 = 3,5 m/0,35 s; pulo nominal 2,20 m; referência de escala = 32 px de tela/m, zoom 0,9. |
| [TESTES_P42.json](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/evidencias_p40/TESTES_P42.json>) | Evidência previamente salva: 445 verificações e lista de falhas vazia, Godot 4.7.2, passo 1/60 s; mesmos valores físicos do Pequeno A. Estes resultados não foram reproduzidos nesta leitura. |

SHA256 do manifesto ativo **v34A/P42b** nesta fase: `0a61e24f68a2d5ed2ebbdfc666c504d2851fa8f66316cae5d9c8f33c114d9a64`. Manifesto ainda contém status textual de teste; a escolha do usuário estabelece Pequeno A como produção. Hash v33A e evidências da fase 1 permanecem no histórico. Evidência P42b salva na fonte: 450 verificações; não atribuídas à execução desta integração.

### 1.1 Histórico da fonte congelada e evolução externa

A leitura inicial e a definição dos valores da fase 1 usaram **P41 / Pequeno A v32A**, com 25 animações e [TESTES_P41.json](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/evidencias_p40/TESTES_P41.json>) já salvo (426 verificações, nenhuma falha). O hash inicial congelado do [manifesto v32A](<C:/Users/daiki/Documents/Codex/carrasco_25d_test/jogavel/prototipo_40/pacotes/pequeno_v32A/manifesto_sprites.json>) permanece **`95f9d728e0c7d6d2aab4e2bd7793c6bb40c512f39232319aba02b64b5445838d`**, idêntico na releitura. Esse pacote está arquivado na referência, mantido para comparação antes/depois; não é mais o pacote ativo das etapas futuras.

A verificação de preservação durante o trabalho detectou uma **alteração externa** da referência: README, personagens, apresentador, protótipo e teste foram atualizados e a entrega P42/v33A e suas evidências foram acrescentadas. A integração não escreveu nem executou a referência. A auditoria do checkout original do principal registrou seus 771 hashes intactos. Preservar os registros anteriores dessa auditoria: não substituir o snapshot inicial pela fonte atual nem atribuir a mudança externa a esta integração.

| Identificação da releitura P42 | SHA256 |
|---|---|
| Manifesto v33A ativo | `396d611384a8f51a4f8a99e2b82eb3057707f042a1fd4a5cfb64a1c8d60a04f8` |
| `personagens_p40.gd` | `911eba7a8e4d73b1f4356af977ee548e8420d563d085911c5999b247aecc030e` |
| `presenter_p40.gd` | `debca2f38fb1518cd744b46a3d5761d277a5115b98cf916bad1c221571fea8ca` |
| `prototipo.gd` | `cef2938fe48c6acec0af7773a3bf84db714d5f80cdac9285d3319f12fa616dc2` |
| README | `edd24dc791bf8faf49eb82d6d205d179abf11c4734a2c6e00aaf76bc9509bfcc` |
| Relatório P42 | `db3400bb541f533307afa13cdf29684255a0318bf5e486c4246d07518ab1142b` |
| Evidência P42 | `b2b5c2cbb5b566f3f0163edf9bd07c921c5abfd8ea0cebe0b5eb7631954709fb` |

A comparação por leitura confirmou que configurações físicas, corrida/caminhada/acelerações, dash, pulo e cápsula continuam com o mesmo contrato. Na evidência salva P42, Pequeno A mantém corrida 144 px/s, dash 111,639001464844 px em 0,35 s e pulo 74,1136596679687 px; não houve nova medição desta integração. **Os valores e a implementação dos passos 1–3 permanecem inalterados por esta atualização do plano.**

As mudanças reais para etapas futuras são: corrida **6 × 8 px → 8 × 6 px**, apoios **0/3 → 1/5**, partida **2 quadros/16 px → 1 quadro/6 px**, novo freio visual `run_stop` de 66 ms, dash chão/ar **5 → 4 quadros** e rastro mais curto. O ciclo permanece 48 px/1,5 m, o dash artístico soma os mesmos 350 ms e **21 animações existentes são integralmente iguais no JSON**, incluindo os oito ataques, seus tempos, polígonos, arquivos/hashes, sombras e efeitos. Paleta e cápsula também permanecem iguais. O contrato detalhado atual está na seção 3.

### 1.2 Decisões atuais


- **Manter `move_speed_multiplier = 0.92` da máscara.** O humano continua mais rápido; Carrasco equipado deve correr a 4,5 m/s.
- **Dash absoluto e independente da corrida/máscara:** 3,5 m em 0,35 s no chão e no ar. Andar não reduz o dash.
- **Preservar futuramente o pulo como jogado, cerca de 2,316052 m (~2,32 m).** 2,20 m é o valor nominal da configuração, não uma exigência de corrigir a integração para obter exatamente essa altura.
- **Fase 1 preservou o pulo antigo; fase 2 adota g/v0 P40** e remove o override −380. Coyote 100 ms e buffer 120 ms atuais continuam iguais; não portar corte variável nesta fase.
- **Cápsula pequena só para Carrasco.** Humano conserva raio 7 unidades, altura 64, centro −19 e pivô Y=−2. Pulo global P40 vale para as duas formas. Decisão após F2: Carrasco também usa **raio 7 unidades**, altura 51,111111 e pés Y=13; não mais raio 7,777778. Toda passagem que aceita a cápsula humana aceita a transformação para a menor.
- **Corvo: IA intocada.** M5 passa a exercer o contato ACTIVE na descida do pulo novo; o pesado antecipa a entrada em dois ticks no limite do ápice para compensar seus 250 ms de preparação. Mesma posição/altura do alvo. Registrar **“reavaliar após dano por quadro”**, pois essa fixture ainda testa a forma humana com pivô/fallback.
- Ataques altos que passam acima do Carrasco pequeno são **aceitos por ora**. Etapa futura **“balanceamento de inimigos”**: avaliar mirar no centro da hurtbox do jogador, com decisão e medidas próprias. Sem ajuste preventivo de IA nesta fase.
- F3 copia o pacote atual `v34A/P42b` e adapta o apresentador da referência; humano e arte antiga continuam disponíveis. Fonte e checkout original permanecem somente leitura.
- Tarefa 4.3: início no cemitério/ruínas do P40, com fundo nativo ×1 e oito colisores idênticos. A auditoria identifica o fundo como **A1.1**, SHA256 `56bf78665821823c8d36f881aafa4e34a35c0ef6a85f43c709aa231aafae32a8`, igual à prova congelada A1.1; **não coincide com o R4 original**. Preservar o mapa jogado no P40 e registrar a divergência de nome, apresentada ao usuário. `ORIGEM_MAPA.json` contém os hashes dos dois renders.

## 2. Conversão e contratos físicos

### 2.1 Unidades fixas de projeto

O principal trabalha com unidades de mundo, unidades/s, unidades/s² e segundos; não possui uma conversão global de metros no controlador da base. Adotar a referência fixa `U = 32 / 0.9 = 35.555555556 unidades/m`. Um pixel nativo de referência corresponde a `1 / 0.9 = 1.111111111 unidades`.

Distâncias e velocidades em metros recebem o fator U. Milissegundos recebem somente o fator 0,001. A câmera não deve modificar esses valores físicos: usar 0,9 como **escala de referência**, sem recalcular U quando uma sala aplicar outro zoom.

Na sala inicial [sala_cemiterio.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/biomes/cemiterio/sala_cemiterio.gd>), a câmera é fixa em 0,9, o fundo é ×1 e a máscara Carrasco inicia equipada. [bosque_room_aprovada.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/biomes/forest/bosque_room_aprovada.gd>) continua preservado com zoom 0,9; F9 abre sua cena derivada da F3. `bosque_trecho_01_playable.gd` conserva zoom 1. Não ajustar física por sala.

### 2.2 Corrida e caminhada — fase 1

| Parâmetro | Base `main` | Perfil integrado da fase 1 |
|---|---:|---:|
| Corrida humana/base, unidades/s | 120 | `160 / 0.92 = 173.913043478` |
| Corrida Carrasco efetiva, unidades/s | 110,4 | 160 |
| Caminhada/corrida | 0,55 | 0,55 |
| Caminhada humana, unidades/s | 66 | 95,652173913 |
| Caminhada Carrasco, unidades/s | 60,72 | 88 |
| Aceleração solo, unidades/s² | 900 | 1.304,347826087 |
| Desaceleração solo, unidades/s² | 1.100 | 1.594,202898551 |
| Aceleração aérea, unidades/s² | 650 | 942,028985507 |

Em zoom 0,9, Carrasco = 144 px/s = 4,5 m/s; caminhada = 79,2 px/s = 2,475 m/s. Humano = 156,521739 px/s = 4,891304348 m/s; caminhada = 86,086957 px/s = 2,690217391 m/s. O humano ser mais rápido é consequência **aceita**, mantendo o modificador da máscara.

Escalar as acelerações por `r = 160 / 110.4 = 1.449275362`, equivalente a `(160 / 0.92) / 120`. Assim, conservam-se os tempos de aceleração/parada para cada forma. Não aplicar `173.913043478 / 110.4`, que acrescentaria o fator da máscara duas vezes.

Ponto principal: [player_locomotion.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/player/player_locomotion.gd>). Configurar a base antes de [MaskController._ready](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/masks/mask_controller.gd>) capturar `base_speed`. Manter [carrasco_base.tres](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/data/masks/carrasco_base.tres>) com o fator 0,92 e os bônus de combate atuais.

O protótipo equipa a máscara e depois sobrescreve `run_speed = 160`. Copiar essa sequência deixaria o cache da velocidade humana antigo; a troca posterior poderia restaurar 120/110,4. A integração deve preservar o cache coerente e multiplicar sempre a base, sem acumular modificadores nas trocas.

### 2.3 Dash B2 — fase 1

| Contrato | Valor |
|---|---|
| Distância nominal | `3.5 × U = 124.444444444 unidades` = 112 px de referência |
| Velocidade absoluta solo/ar | `112 / 0.35 / 0.9 = 320 / 0.9 = 355.555555556 unidades/s` = 10 m/s |
| Duração solo/ar | 0,35 s |
| I-frames | **[0,06125; 0,21875) s**; início inclusivo, fim exclusivo |
| Duração da janela invulnerável | 0,15750 s |
| Cancelamento ofensivo | Disponível a partir de **0,08 s**, inclusive, enquanto o modo ainda é dash |
| Cooldown terrestre | 0,28 s, preservado |
| Momentum ao cancelar no chão | 0,45 da velocidade anterior |
| Momentum ao cancelar no ar para leve/pesado | 0,65 / 0,40 da velocidade anterior |

I-frames preservam as proporções da referência: `0.35 × (0.07 / 0.40)` e `0.35 × (0.25 / 0.40)`. A janela de cancelamento de 80 ms não recebe essa escala.

Em [player_defense.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/player/player_defense.gd>), `_start_dash()` e o alvo contínuo de movimento precisam usar a velocidade absoluta. Hoje ambos dependem de `locomotion.run_speed` e multiplicadores 2,0. Um multiplicador fixo de 2,222222222 só seria correto para Carrasco a 160 e falharia com humano ou outro perfil. Evitar divisão por corrida, inclusive nas fixtures que usam `run_speed = 0`.

Conservar a direção escolhida na partida, o bloqueio de parry durante dash, a suspensão de gravidade apenas em AIR_DASH e uma única carga aérea por permanência no ar. Parede ou dano no ar não restauram a carga. O pouso real a restaura. Usar `move_and_slide` para respeitar terreno e paredes, sem deslocamento direto/teleporte para cumprir a distância nominal.

Preservar [player.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/player/player.gd>) quanto ao descarte de ataque pressionado antes da janela mínima. Ao cancelar, terminar a invulnerabilidade no mesmo tick, manter a carga aérea consumida e aplicar o momentum antes da atualização normal da locomoção. Para velocidade anterior de 355,555556, as frações correspondem inicialmente a 160 / 231,111111 / 142,222222 unidades/s para chão / aéreo leve / aéreo pesado.

**Nominal e medido:** a evidência salva do Pequeno A registra **111,639001465 px em 0,35 s**, não exatamente 112. A ordem atual `aceitar entrada → tick da defesa → cancelamento → locomoção` encerra o modo antes de mover o tick final, que já sofre atualização normal. Manter essa ordem nesta fase; registrar distância e tolerância por tick. A 60 Hz, um tick corresponde a 16,666667 ms e 5,333333 px de referência/5,925926 unidades durante o dash. Não somar a frenagem posterior à distância do modo dash nem exigir igualdade exata com a fórmula contínua.

### 2.4 Pulo como jogado — fase 2

Não alterar nenhum parâmetro ou assistência de pulo na fase 1. Na base, `gravity = 800`, `jump_velocity = -260`, coyote = 0,10 s e buffer = 0,12 s. A única sobrescrita de Locomotion encontrada nas salas é `jump_velocity = -380` em [forest_vertical_slice.tscn](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scenes/biomes/forest/forest_vertical_slice.tscn>). Não há sobrescrita de corrida/dash nas salas da base.

Na fase 2, reproduzir o perfil da referência: H nominal = `2.2 × U = 78.222222222 unidades`, T nominal = 0,325 s, `g = 2H / T² = 1481.130834977` e `v0 = -2H / T = -481.367521368`. A evidência Pequeno A a 60 Hz mede **74,113659668 px / 32 = 2,316051865 m**. Preservar esse comportamento observado; não corrigir para 2,20 m exatos por iniciativa da integração.

A fase 2 substitui os defaults de `PlayerLocomotion` por essas fórmulas e remove o nó sobrescrito da vertical slice; não muda a ordem de integração. Medir a 60 Hz, do piso até a maior subida, incluindo o tick inicial que aplica impulso antes da gravidade seguinte. Coyote/buffer atuais permanecem, sem adicionar pulo variável. Trajetórias e contatos antes/depois são salvos em `evidencias_integracao_p40_f2/MEDIDAS_*.json`.

### 2.5 Cápsula do Pequeno A e pivô — F2 e decisão aprovada para F3

O manifesto intacto declara **raio 7 px e altura 46 px**. A decisão posterior do usuário substitui somente o raio integrado: **7 unidades de mundo**, igual ao humano; altura e pés ficam como em F2. A altura inclui as extremidades arredondadas. Capa, braço, lâmina e rastro ficam fora da cápsula.

| Grandeza integrada atual | Conversão fixa |
|---|---:|
| Raio | **7 unidades**, equivalentes a 6,3 px de referência (F2 histórica: 7,777778 unidades) |
| Altura total | `46 / 0.9 = 51.111111111 unidades` |
| Diâmetro | **14 unidades**, equivalentes a 12,6 px de referência |
| Centro local, pés em (0,13) | `Vector2(0, 13 - 51.111111111 / 2) = Vector2(0, -12.555555556)` |
| Metros integrados | raio `7 / U = 0.196875 m`; altura `46 / 32 = 1.4375 m` |

Os 0,22 m e 1,44 m do manifesto são arredondados. Os percentuais da proposta de raio 7 px (71,9% do núcleo, 52,6% de todos os pixels) descrevem a fonte; não são uma nova medição do raio aprovado de 7 unidades. Não modificar o manifesto para refletir a decisão de integração.

Na integração, corpo/hurtbox recebem cópias independentes de **raio 7 e altura 51,111111**, fundo Y=13. Humano mantém raio 7, altura 64 e centro −19. A cápsula menor é subconjunto da humana com os mesmos pés; a troca humana → Carrasco não é mais recusada no vão de 15 unidades. A expansão de volta ao humano ainda exige altura disponível.

O Player aplica o perfil pequeno pelo identificador `carrasco_base` no sinal de troca de máscara e restaura cópias do original para humano/outras formas. Pés e origem não são deslocados. A troca normal consulta se a nova cápsula cabe: expansão bloqueada sob teto/entre paredes não consome cooldown nem termina ultimate. Consulta com inset de 0,01 unidade distingue tangência de interpenetração; equip/setup continuam APIs de montagem da cena, cuja posição deve ser válida.

O pivô elevado da referência tem Y = `13 - 0.84 × U = -16.866666667` e mantém X = 5. Geometria por quadro relativa aos pés não recebe novamente a rotação desse pivô. Golpes sem dados mantêm esse fallback.

## 3. Contrato do apresentador e pacote pequeno — implementação F3

### 3.1 Leitor e integridade

O leitor `carrasco_p42b_package.gd` e o apresentador `carrasco_pequeno_a.gd` adaptam os contratos da referência. O pacote foi copiado para `assets/characters/pequeno_v34A/`, byte a byte; não foram transplantados os inimigos/autoloads/seletor histórico do protótipo. v32A/v33A arquivadas servem à rastreabilidade. O modo novo é padrão somente para `carrasco_base`; `small_carrasco_enabled=false` conserva os caminhos antigos para teste/comparação.

O formato atual é `animacoes[]` com `id`, `loop` e `quadros[]`; cada quadro fornece `arquivo`, `ms`, `ancora`, `sha256`, dimensões e, quando aplicável, sombra e hitbox. Efeitos são camada separada, com `arquivo`, `ancora`, `fase`, hash e índice `quadro` opcional. A sombra do quadro tem precedência; a sombra da animação é fallback. A capa já está desenhada nos quadros, com atraso visual de um quadro, e não pede nova deformação física.

Validar caminhos relativos seguros, presença de PNG, dimensões/âncoras finitas, quadros e tempos, loop, referência de efeito, hash e polígonos. Carregar texturas uma vez e reutilizá-las por caminho. Paleta C5.1 travada: 44 cores disponíveis; v32A e v33A usam as mesmas 22, sem recolorir os PNG originais. Hash da paleta: `6d3acc7dc9fc7f516d29abea3d9be2b024f868bad8a24158eea230089fe1b4ce`.

**SHA256 e metadata PNG:** aceitar o hash dos bytes exatos ou o hash normalizado removendo somente o chunk PNG `caBX`, conforme o carregador da referência. O chunk pode ser acrescentado por transferência de conteúdo sem alterar os pixels. Não ignorar toda metadata, não reencodar as imagens e não aceitar divergência restante silenciosamente. Validar estrutura e limites dos chunks antes da normalização. Registrar qual forma de hash correspondeu; os arquivos de origem permanecem intactos.

Na releitura, os 191 PNG únicos referenciados pela v32A e os 190 da v33A continham `caBX`: seus hashes brutos divergiam dos manifestos e todos correspondiam após remover somente esse chunk. A arte nova não autoriza ignorar SHA nem substituir arquivos da fonte; a normalização continua necessária.

### 3.2 Estados e animações disponíveis

| Animação | Quadros | Duração do manifesto | Uso |
|---|---:|---:|---|
| idle | 8 | 2.000 ms | Idle em loop |
| run | 8 | 333,33 ms indicativos | Run/walk por distância, 6 px/quadro, apoios 1/5 |
| run_start | 1 | 50 ms indicativos | Partida por distância: primeiro intervalo de 6 px |
| run_stop | 1 | 66 ms | Freio visual após apoio por dois ticks, antes do idle |
| turn | 1 | 50 ms | Virada no chão |
| attack_exit | 1 | 66 ms | Saída de ataque terrestre para idle |
| dash / dash_ar | 4 cada | 350 ms cada | P42b: arranque → smear compacto → pose esticada → freio; 50/60/190/50 ms |
| jump_up | 2 | 140 ms | Subida, último quadro mantido |
| fall_start / fall_loop | 2 / 3 | 140 / 270 ms | Entrada na queda seguida de loop |
| land | 2 | 120 ms | Pouso |
| hurt | 3 | 180 ms | Dano, ruptura e morte no mapeamento atual |
| heavy | 9 | 890 ms | `carrasco_heavy` |
| light1 / light2 / light3 | 7 / 8 / 9 | 460 / 520 / 670 ms | Combo `carrasco_light_1/2/3` |
| post_dash | 7 | 500 ms | `carrasco_post_dodge` |
| air_light / air_heavy | 7 / 10 | 520 / 770 ms | `carrasco_air_light/heavy` |
| charge_start / charge_loop / charge_full | 2 / 4 / 4 | 120 / 360 / 280 ms | Início, loop e carga cheia |
| charged_heavy | 9 | 780 ms | `carrasco_charged_heavy` |
| parry / parry_spark | 4 / 3 | 380 / 160 ms | Guarda pelo tempo da defesa e faísca após sucesso |

São **26 animações** contando separadamente os itens agrupados na tabela, com `run_stop` acrescentada em P42. Idle/run, pós-dash, aéreos, carga e parry já têm arte própria; a regra antiga de mostrar o quadro-mestre grande nesses estados não se aplica. Estados sem arte do pacote, incluindo habilidades/execução/Tribunal, requerem fallback explícito e manutenção dos sinais e efeitos do runtime; não inventar quadros nem lhes atribuir hitboxes de outro ataque.

A corrida declara 41,67 ms por quadro e 333,33 ms no total: oito valores arredondados somam 333,36 ms. A seleção por distância é o contrato dominante; não acumular esses valores arredondados como um relógio de corrida. O smear de dash alarga somente a arte (~1,5–1,7 vezes a largura idle); não alarga corpo, hurtbox ou cápsula.

As animações temporizadas usam o tempo da ação existente, com intervalos cumulativos e fim exclusivo, sem relógio independente de combate. Carga cheia começa no limiar do `.tres` (1 s na referência). No heavy após carga curta, o apresentador pode antecipar a pose carregada no WINDUP; isso não altera o dano. O aéreo pesado mantém o quadro de mergulho enquanto aguarda pouso real e mostra o impacto no pouso, sem impulso físico extra.

### 3.3 Âncora, escala, facing e integração com o principal

A âncora é o pixel dos pés na linha imediatamente abaixo da sola; o corpo termina em `ancora.y - 1`, e a sombra usa a linha dos pés e a seguinte. Quadros de uma animação compartilham canvas/âncora. No idle, âncora (25,50), inalterada. Não presumir a mesma âncora entre animações.

| Arte modificada em P42 | Canvas/âncora v32A, px | Canvas/âncora v33A, px |
|---|---|---|
| run | 65×55 / (31,52) | 68×50 / (44,47) |
| run_start | 60×50 / (25,47) | 56×46 / (32,43) |
| run_stop | Não existia | 67×48 / (44,45) |
| dash chão | 76×50 / (47,47) | 100×48 / (71,45) |
| dash aéreo | 76×52 / (47,49) | 95×51 / (66,48) |

Essas animações recebem PNG, hashes e sombras próprios da v33A; não reutilizar seus offsets antigos. O dash chão possui quatro efeitos associados aos quadros. O dash aéreo passa dos dois efeitos antigos a nenhum efeito de pacote, sem poeira; o rastro é produzido separadamente pelo apresentador.

Exibir corpo/efeitos ×1 NEAREST no enquadramento de referência, arredondando somente a posição visual dos pés. Preservar coordenadas físicas fracionárias. Ao espelhar, preservar a âncora: offset x = `-ancora.x` à direita e `-(largura - ancora.x)` à esquerda; offset y = `-ancora.y`.

Escolher um único responsável pelo facing. [player.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/player/player.gd>) já aplica `VisualRoot.scale.x`; a referência aplica `flip_h` e offset. Adaptar para não espelhar duas vezes. Preservar `set_pose`/`bind_runtime`, ou adaptar seus chamadores em [player_visual_controller.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/player/player_visual_controller.gd>), mantendo forma humana, troca de máscara, Condenação, execução, Tribunal e eventos de áudio.

Alterar apenas `visual_scene` da máscara não seleciona o pacote novo: os flags `modular_carrasco_enabled` e `official_base_enabled` atualmente priorizam OFFICIAL_CARRASCO. Integrar um modo explícito do Pequeno A sem remover os recursos históricos/3D. Rever os ajustes de escala da sala aprovada no passo de apresentação.

O protótipo desenha pelo CanvasLayer após transformar os pés para tela. Na integração, manter oclusão por vegetação/foreground e ordenação do mundo; não desenhar o jogador sobre todas as camadas do cenário por copiar esse arranjo literalmente. Em zoom 1, definir apresentação coerente sem alterar U físico.

### 3.4 Corrida por distância e parada visual

Após o movimento resolvido pela física, acumular `distancia_px += abs(x_depois - x_antes) × 0.9` durante run/walk. Selecionar **`floor(distancia_px / 6) % 8`**. O fator 0,9 é a referência fixa, não a câmera corrente. Cada quadro representa 6 px = 6,666666667 unidades = 0,1875 m; ciclo completo = 48 px = 53,333333333 unidades = 1,5 m. Em P42, cada pé permanece em contato por três quadros, com patinação declarada de 0 px na evidência salva.

A 4,5 m/s: 41,666667 ms/quadro e ciclo de 0,333333 s; andando: 75,757576 ms/quadro e ciclo de 0,606061 s. São consequências do deslocamento; `ms` do manifesto não avança um segundo relógio para run/walk. `run_start` usa seu único quadro nos primeiros 6 px antes do ciclo; os 50 ms da metadata não governam a partida.

Não contar câmera, tremor, offsets de pouso, spawn, teleporte de recuperação, deslocamento aéreo/dash/ataque ou hitstop. Parede não deve avançar quadros quando não há deslocamento. Preservar/resetar a fase de acordo com as transições e zerar a medição anterior ao respawn/troca de forma.

**Apoios = 1 e 5, lidos do manifesto.** Ao atingir idle depois da desaceleração natural, selecionar o apoio mais próximo pela distância circular de índices e mantê-lo por **dois ticks**; em empate, a referência favorece o primeiro apoio da lista. Em seguida, mostrar **`run_stop` por 66 ms**, somente no chão, antes do idle. Ao retomar, preservar a fase a partir do apoio mostrado e interromper a transição visual conforme o estado real. Isso muda apenas a arte. Não portar a frenagem até apoio da antiga 3.6, não conduzir o corpo até a próxima passada e não acrescentar distância física. A fonte atual mede posições reais e mantém a frenagem normal.

### 3.5 Sombra, efeitos e fluidez

Sombra é um PNG separado por quadro/animação, com âncora própria, espelhamento e recorte da região usada. Projetar no primeiro terreno sólido sob os pés, excluindo o jogador e áreas/inimigos. Ausência de piso ou de dado de sombra = sombra oculta. Preservar uma única sombra; desativar a sombra antiga somente no modo novo.

Fator da referência: `1 - 0.5 × clamp(altura_m / 2.2, 0, 1)`, aplicado ao tamanho e alpha: 1 no chão, 0,75 a 1,10 m e 0,5 a partir de 2,20 m. Rasterizar tamanho/posição em pixels inteiros e manter NEAREST. Esse 2,20 é a faixa visual da sombra, não um comando para corrigir o pulo observado.

Efeitos `fase = todas` acompanham a pose; `ACTIVE`/`ATIVO` aparecem só no ativo. Corpo, efeito e sombra usam suas próprias âncoras. Rastro do dash é produzido pelo apresentador, não incorporado aos PNG: cópia do quadro/âncora na posição histórica aproximadamente a cada 40 ms, RGB (116,3,6), índice 22 da paleta, alpha 0,5 → 0 em **110 ms**, máximo **três** fantasmas, chão e ar. Pós-dash: até dois fantasmas, vida **80 ms**, geração durante os primeiros 130 ms do ataque. Ler vida/limites de `rastro_dash` do manifesto; o apresentador atual conserva constantes fallback de 150/100 ms e 4/2, mas os valores da v33A prevalecem. `intervalo_s = 0.04` também está no manifesto; a fonte usa a constante 40 ms para geração, com o mesmo valor. A faísca de parry dura 160 ms e substitui a faísca técnica no modo novo.

Virada dura 50 ms, freio `run_stop` 66 ms, saída de ataque terrestre 66 ms, pouso 120 ms e dano 180 ms. Preservar a capa desenhada com atraso de um quadro e a respiração do idle. A corrida P42 tem tronco baixo inclinado ~26°, cabeça oscilando 1 px, capa longa em onda e lâmina baixa atrás; esses deslocamentos já pertencem à arte. Essas transições não dirigem a física. Hitstop, câmera, sangue, recuo e poeira de sensação ficam para etapa própria, evitando duplicar os sistemas já existentes no principal.

### 3.6 Polígonos de dano por quadro

No pacote pequeno, os quadros ATIVOS possuem `hitbox.arco.poligono` e/ou `hitbox.lamina.poligono`, relativos à âncora dos pés; x positivo à frente/direita, y positivo para baixo. Refletir x pela direção e converter para mundo com **`pes_world + Vector2(x × facing, y) / 0.9`**. Não reaplicar rotação do pivô nem usar caixa de todos os pixels opacos, que incluiria corpo/capa/FX.

Validar finitude, contorno, área e decomposição de polígonos possivelmente côncavos em peças convexas. A referência usa `Geometry2D.decompose_polygon_in_convex`, depois convex hull e simplificação de quase colineares com tolerância 0,25 px para evitar avisos do motor. Conferir que a geometria final preserva a área visual, e não substituir por retângulos da arte grande.

| Ataque/arte | PREP / ATIVO / RECUP, ms | Quadros ATIVOS, índices desde zero |
|---|---|---|
| `carrasco_heavy` / heavy | 320 / 140 / 430 | 4 e 5 |
| `carrasco_light_1` / light1 | 130 / 110 / 220 | 2 e 3 |
| `carrasco_light_2` / light2 | 160 / 110 / 250 | 3 e 4 |
| `carrasco_light_3` / light3 | 220 / 130 / 320 | 3 e 4 |
| `carrasco_post_dodge` / post_dash | 120 / 110 / 270 | 2 e 3 |
| `carrasco_air_light` / air_light | 130 / 120 / 270 | 2 e 3 |
| `carrasco_air_heavy` / air_heavy | 250 / 130 / 390 | 3 e 4, com a regra de pouso real |
| `carrasco_charged_heavy` / charged_heavy | 160 / 140 / 480 | 2 e 3 |

A soma dos quadros de cada fase corresponde aos `.tres` da referência. No momento da integração futura, conferir também os `.tres` do principal; não alterar tempos/danos para acomodar um relógio artístico paralelo. Todos os golpes desenhados recortam o dano à frente do corpo, x ≥ 0; golpes terrestres também respeitam o chão, enquanto aéreos não usam esse corte. O heavy pequeno já corrige o dano atrás das costas.

Usar uma função comum para selecionar o quadro temporal da apresentação e da geometria, no tick de física, **antes do primeiro scan ACTIVE**. WINDUP/RECOVERY/CHARGING e quadro sem área não causam dano; quadro sem área em um ataque perfilado não reativa a hitbox legada. Se dano/ruptura/morte cobrir visualmente o ataque, esse quadro não fornece área: na referência, a área segue o quadro efetivamente desenhado.

Preservar [HitContext e Hitbox2D](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/scripts/combat/hitbox_2d.gd>), dano, Postura, parry, máscaras, sinais e `struck_targets`. Trocar de quadro/peça não inicia uma nova ação nem permite múltiplos acertos no mesmo alvo. Separar início da ação de atualização da geometria, e limpar perfil ao interromper/morrer/trocar/reiniciar.

Consulta `intersect_shape` sobre hurtboxes não verifica terreno intermediário nem cobertura contínua entre ticks. Testar parede e alvo rápido; se necessário, acrescentar oclusão/varredura em mudança delimitada. Ataques sem dados do pacote mantêm fallback declarado e testado, sem herdar polígonos de outro golpe.

## 4. Sequência de integração e critérios de saída

Cada passo registra seus testes. **Fases 1–4 e Tarefa 4.4 aprovadas. Tarefa 4.5 equipa o primeiro pacote real de inimigo (Peregrino).** Avaliação ampliada e balanceamento continuam futuros.

| Passo e fase | Alteração delimitada | Critério de saída |
|---|---|---|
| **1 — FASE 1: linha de base** | Identificar `main@ef24b556`, cópia/branch isoladas e alterações anteriores preservadas. Manter identificação/hash inicial congelado P41/v32A e registrar a evolução externa P42/v33A por leitura, sem substituir snapshots anteriores. Rodar suites pertinentes somente na cópia de integração, registrar passes/falhas anteriores e os contratos humano/máscara/U. | Evidência reproduzível distingue falhas preexistentes, novas e evolução externa da fonte; nenhuma escrita da integração na referência; pulo/cápsula/presenter atuais identificados. |
| **2 — FASE 1: corrida/caminhada** | Ajustar default humano e acelerações, manter 0,55 e máscara 0,92/cache da base. Não trocar arte, pulo, cápsula ou lógica de parada por apoio. | Humano 173,913043/95,652174 e Carrasco 160/88; aceleração/parada proporcionais; equip/troca/reset sem acumulação. |
| **3 — FASE 1: dash B2** | Velocidade absoluta solo/ar 355,555556; duração 0,35; i-frames proporcionais. Preservar direção, cooldown, carga aérea, cancelamento 80 ms, momentum e colisões. Revisar só expectativas relacionadas aos novos valores. | Chão/ar, direita/esquerda, Shift, ambas as formas, corrida zero, parede, fronteiras de i-frame/cancelamento e distância medida; pulo atual continua igual. |
| **4 — FASE 2: pulo como jogado** | Aplicar g=1481,130835/v0=−481,367521; remover override −380. Manter coyote/buffer atuais. | Altura/ápice/traço medidos a 60 Hz, coyote/buffer e pouso; altura jogada ~2,32 m, sem corrigir para 2,20 m. |
| **5 — F2 APROVADA + DECISÃO F3** | Só Carrasco: raio **7 unidades**/altura 51,111111; pés e pivô elevados preservados. Humano conserva corpo/hurtbox/pivô originais. | Regressão F2 atualizada: 85 checks, incluindo transformação no vão de 15 unidades. |
| **6 — F3 ENTREGUE: apresentador Pequeno A v34A** | Leitor próprio, 215 arquivos copiados intactos, SHA256/raw ou caBX; modo novo como padrão. | 26 animações, âncoras e pixels ×1 NEAREST, um espelhamento; sinais/combate da máscara preservados. |
| **7 — F3 ENTREGUE: sombra única** | Sombra por quadro/animação projetada no terreno; antiga desligada somente no modo novo. | Piso/ar/sem piso e retorno ao humano conferidos; ray exclui personagens para alcançar chão. |
| **8 — F3 ENTREGUE: corrida por distância** | Oito quadros, **6 px/quadro**, posições após movimento, reset/teleporte; sem frenagem física até apoio. | Fórmula por distância; parede/câmera/parada testadas. Parada medida 7 ticks/0,116667 s; apoio 1/5 é somente visual. |
| **9 — FUTURA: avaliação ampliada da fluidez** | O apresentador do passo 6 já inclui apoio 1/5 por dois ticks, run_stop 66 ms, virada/pouso/saída/carga/faísca e rastro 110/80 ms. Não há frenagem física até apoio. | Ampliar comparação de soltura em oito fases, retomadas/interrupções e bordas; não declarar esta etapa independente aprovada pela integração visual. |
| **10 — F3 ENTREGUE: dano por quadro** | Polígonos/retângulos, recorte x≥0, decomposição, seleção ACTIVE após movimento; oito golpes com dados, fallback dos demais. | Quadros ACTIVE dos oito golpes nas duas direções, deduplicação, interrupção, recuperação, colado/ponta/atrás/fora e parede sólida. |
| **11 — PENDENTE: avaliação ampliada de ataques/inimigos** | Oito perfis já integrados em F3; ampliar playtest de combos/carga/pós-dash/aéreos e arenas sem antecipar ajustes de IA. | M5 retimado; **reavaliar após dano por quadro**. Peregrino/Corvo/Raiz usam fontes/valores intactos. |
| **12 — F4 APROVADA + F5 ENTREGUE: sala/sensação** | Cemitério P40 aceito; quatro grupos em arquivo único, buffers/coyote/corte variável, hitstop/câmera unificados, flash/recuo/pixels e antecipação. | G/H no debug F3, todos ON por padrão; pulo curto ~1 m e completo ~2,315 m; sem duplicação de feedback; sala/Bosque e contratos aprovados preservados. |
| **13 — PENDENTE: regressão e avaliação final** | Atualizar somente expectativas de contratos substituídos; guardar captura normal e depuração; manter recursos antigos necessários. | Suites pertinentes sem falhas novas, medidas físicas/contatos e verificação visual/playtest; limitações restantes explicitadas. |
| **14 — FUTURA: balanceamento de inimigos** | Avaliar mirar no **centro da hurtbox do jogador**, respeitando forma/altura; depende de decisão própria. | Ataques altos que passam sobre Pequeno A aceitos por ora. Medir alcance/altura/cadência antes de alterar IA. |

## 5. Validação dirigida e riscos

### 5.1 Fase 1

| Risco | Teste e critério |
|---|---|
| Cache/máscara restauram velocidade velha ou acumulam fator | Medir corrida/caminhada em humano e Carrasco; equipar/trocar repetidamente, reiniciar e comparar `base_speed`. Carrasco = base × 0,92 = 160. Manter HP/Postura/bônus/Condenação existentes. |
| Aceleração ou inversão muda desproporcionalmente | Piso plano: medir tempo terminal, parada a partir do regime e inversão nas duas formas; comparar com a baseline pelo fator r. Conferir bordas e chão/ar. |
| Dash ainda depende de corrida/máscara/Shift | Dash chão/ar/direções em ambas as formas, Shift e `run_speed = 0`; velocidade absoluta, .35 s e distância livre medida. Não dividir por corrida. |
| Fronteiras de invulnerabilidade/cancelamento | Testar imediatamente antes/no início/no fim de [0,06125;0,21875), exatamente 0,08 s e imediatamente antes; input precoce não fica pré-cancelado. Cancelar elimina i-frame e mantém frações/cooldown/carga. |
| Colisão ou pouso restituem carga indevidamente | Parede sólida durante dash, dano no ar, segundo dash na mesma permanência no ar e pouso real. Sem atravessar parede; parede/dano não recarregam, chão real recarrega. |
| Distância medida inclui frenagem ou promete igualdade contínua | Capturar posições e estado por tick até o fim do modo; medir frenagem separadamente. Registrar delta/FPS e tolerância de no máximo um tick do dash na primeira comparação. |
| Fase 1 muda pulo/arte/cápsula por acidente | Comparar g/v0/coyote/buffer e override vertical; corpo/hurtbox continuam raio 7 un, altura 64, centro -19. Recursos/presenter/câmera/ataques da base preservados. |
| Travessia muda com velocidade/dash novos | Smoke de chão, degrau, plataforma, vãos, parede, saída e recuperação nas salas existentes. Relacionar falhas ao contrato alterado, sem compensar com novo pulo/terreno nesta fase. |

### 5.2 Expectativas existentes a revisar

| Arquivo na cópia de integração | Observação/tratamento |
|---|---|
| [verify_milestone3.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone3.gd>) | Linha 94 na base fixa dash 0,40 e janela i-frame 0,18. Atualizar para 0,35 e 0,15750, conservando parry/combate. |
| [verify_milestone4_1.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone4_1.gd>) | Linhas 103–104 fixam 400 ms e [70;250) ms. Atualizar para novos valores; manter cancelamento 80 ms, momentum, parede, carga e parry. Fixture na linha 61 força corrida 120: declarar seu perfil, sem misturar cache humano integrado com reset legado. |
| [verify_milestone4.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone4.gd>) | Linha 50 força corrida 120, e outra fixture usa zero. Preservar propósito da fixture e exercitar dash absoluto sem divisão por zero. |
| [verify_milestone8.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone8.gd>) | Linha 96 fixa 110,4; verificar 160 e base × 0,92, mantendo teste de não acumulação, bônus, HP/Postura e swap. |
| [verify_vertical_slice.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_vertical_slice.gd>) | Verifica aceleração/inversão, Shift durante dash e percurso. Não alterar override do pulo nem modo artístico para obter passe da fase 1. |
| [verify_milestone8_2.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone8_2.gd>) | Linha 42 espera cápsula height=26, embora a cena da base já use 64. Registrar como incompatibilidade preexistente se falhar; não mudar cápsula nem relaxar esse teste por causa da fase 1. |
| [verify_milestone8_3.gd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/tests/verify_milestone8_3.gd>) e testes visuais atuais | Recursos/AtlasTexture e flags antigos continuam nesta fase. Criar expectativas específicas v33A somente quando seu apresentador entrar; conservar verificação dos recursos legados necessária. |

Executar suites pertinentes em grupos: locomoção/defesa, combate/parry, máscara/execução, arenas de inimigos e travessias. Registrar quais foram executadas, delta/FPS, versões e falhas anteriores. Não atribuir os 426 checks salvos P41 nem os 445 salvos P42 à execução da integração, nem modificar a referência para gerar nova evidência. Esta atualização externa da arte não requer mudar valores, implementação ou fixtures da fase 1.

### 5.3 Etapas posteriores

Validar pulo observado, cápsulas por forma, polígonos frente/costas/chão, deduplicação, hitstop, contato rápido e oclusão por parede. Medir IAs com seus alcances atuais antes de rebalancear: Peregrino, Corvo e Raiz podem reagir às novas distâncias/velocidades, mas não recebem alterações preventivas de dano ou alcance. Execução mantém elegibilidade, 52 unidades e linha de visão até decisão própria; a nova lâmina não autoriza aumentar esse alcance.

Verificar sombra única no terreno, arte sem blur, pés estáveis ao espelhar/trocar pose, fase por distância sem avanço da câmera, teleporte/reset sem corrida artificial e foreground correto. Rever rotas predeterminadas dos testes de Bosque/trecho/vertical slice somente nas etapas que mudarem pulo/cápsula/presenter, mantendo sucesso de saída e recuperação como critérios reais.

## 6. Diferenças em relação ao plano da tarefa 3.7

1. **Fonte principal atualizada:** referências históricas 3.3–3.6 dão contexto; a produção passa a ser o jogável da pasta `prototipo_40`. A fonte inicial foi P41/Pequeno A v32A; a evolução externa P42/v33A é agora a referência futura, com v32A arquivada/hash inicial preservado. O README ainda tem título P41 e seção P42. O destino é a cópia isolada/branch a partir de `main`, preservando o checkout do usuário.
2. **Escopo temporal definido:** passos 1–3 são a fase 1 aprovada; passos 4–5 são a fase 2 atual; 6–13 permanecem pendentes. O plano anterior tratava toda a sequência como futura e ainda pedia congelar entregas 3.5/3.6 em evolução.
3. **Máscara decidida:** manter 0,92 e humano mais rápido deixou de ser proposta/questão de balanceamento. Base humana = 173,913043478; Carrasco = 160. Dash independente passa a contrato explícito.
4. **Pulo observado preservado:** o alvo futuro é ~2,316052 m como jogado. Retirada a sugestão de corrigir para 2,20 m exatos; gravidade/impulso/assistências/override atuais não mudam na fase 1.
5. **Cápsula pequena:** raio 7 px, altura total 46 px, convertidos em 7,777778/51,111111 unidades e centro -12,555556. Substitui a proposta grande de raio 0,31 m/altura 2,20 m/centro -26,111111. Metros arredondados do manifesto não prevalecem sobre seus pixels.
6. **Apresentador e arte novos:** v33A tem 26 animações, golpes leves/pós-dash/aéreos/carga/parry e transições próprios. Mantém 21 animações da v32A integralmente iguais e adiciona `run_stop`, corrida v2 e dash com smear de quatro quadros. Não usar o mestre grande como fallback desses estados nem exigir suporte ao formato antigo de corrida v1 para entrar em produção pequena.
7. **Corrida pequena:** oito quadros, **6 px/0,1875 m por quadro**, ciclo de 48 px/1,5 m, apoios 1/5; substitui a proposta 3.7 de oito quadros/12 px/0,375 m/apoios 0/4 e a entrega inicial v32A de seis quadros/8 px/apoios 0/3. Parada atual é apoio visual de dois ticks seguido de freio 66 ms, com desaceleração natural; retirada a proposta de portar frenagem física até apoio.
8. **Dano já descrito por polígonos:** o pacote pequeno contém arco/lâmina nos quadros ATIVOS de oito ataques, com heavy frente/costas corrigido. A antiga pendência de anotar o heavy grande com retângulos não é o contrato de produção. Seleção comum de quadro, convexidade, interrupção e deduplicação agora são requisitos explícitos.
9. **Integridade e efeitos atualizados:** hashes aceitam bytes exatos ou normalização específica do chunk `caBX`; sombra por quadro/animação, rastro de dash/pós-dash, faísca e capa atrasada estão presentes. P42 reduz rastro de dash/pós-dash a 110/80 ms e limites 3/2, muda canvas/âncoras/sombras das novas poses e remove poeira do dash aéreo. Esses mecanismos continuam pendentes de integração, sem serem confundidos com física ou evidência recém-executada.

Na fase 2, P42b/v34A torna-se a fonte atual; muda somente o dash artístico frente à v33A (50/60/190/50 ms, smear 64 px). Física/hurtbox/dano mantêm o contrato. Corpo/hurtbox pequenos ficam **só no Carrasco**, humano restaurado nas trocas e expansão recusada onde não cabe. Pivô elevado Y=−16,866667 corresponde a 29,866667 unidades acima dos pés (58,4348% da altura pequena), diretamente da referência; não aplicar outra redução de escala por 48/72.

**Histórico:** fase 1 = corrida/caminhada/dash; fase 2 = gravidade/impulso, retirada do override vertical e corpo/hurtbox/pivô por forma. `RELATORIO_INTEGRACAO_P40_F2.md` preserva as medidas e contatos daquela entrega, inclusive o raio anterior.

**Escopo F3 entregue para avaliação:** passos 6–8 e 10; pacote Pequeno A v34A, apresentador, sombra, distância e dano por quadro. Raio corrigido para 7 unidades pela decisão do usuário, fixture M5 retimada e IA/recursos de ataques/inimigos intactos. Oito perfis do manifesto entram pelo leitor genérico do passo 10. Habilidades, execução e Tribunal sem animação própria usam idle como fallback visual, mantendo seu runtime/sinais/efeitos. O launcher abre uma cena derivada do Bosque aprovado com os três inimigos originais; cenário, colisores e cena base não foram redesenhados. Próximas etapas permanecem dependentes de avaliação.

**Tarefa 4.3:** nova cena `scenes/biomes/cemiterio/sala_cemiterio.tscn`; fundo P40/A1.1 copiado byte a byte, cobertura atlas do personagem antigo embutido igual à referência. Conversão dos colisores: `x*0,6154`, `(y+86)*0,6156`, depois `/0,9`; fechamentos do chão em y=620, plataformas de 2 px e margem unidirecional 1/0,9. A sala inteira e a câmera recebem somente uma translação Y=−150 no mundo para acomodar a faixa absoluta original do Corvo (92–186), conservando exatamente suas coordenadas de tela. IA/tuning/ataques e arquivos do Bosque intocados. Pedra/ruína/pilar acessíveis do chão; coluna pelo pilar. Não prometer salto direto do chão à coluna: o topo está perto/acima do ápice nessa posição. F9 global alterna as duas salas e restaura o relógio de hitstop; R reinicia o encontro/renasce. Sem push/merge.


## 7. Tarefa 4.4 — sensação e preparo de pacotes de inimigo

Aprovação F4: o fundo efetivo P40/A1.1 é aceito como fundo desta sala. As diferenças para R4 ficam para revisão geral do mapa. Seu SHA256 e os colisores continuam iguais; a antecipação move a vista e o fundo juntos, com margens de pixels existentes espelhadas, sem retocar o PNG.

**Sensação:** `data/config/sensacao.json` concentra os parâmetros. Quatro grupos começam ON; F3 habilita G/H e mostra a seleção/estados no HUD. H continua sendo execução fora do debug. Desligar um grupo limpa seus pedidos/efeitos pendentes. CONTROLE usa coyote e buffer de pulo 100 ms (substitui o buffer histórico 120 ms), ataque/dash 120 ms, corte de subida até ~1 m e cancelamento de recuperação leve por dash. Não cancela windup/ACTIVE/pesado; preserva o bloqueio do ataque precoce antes de 80 ms do dash e a carga aérea. R/renascimento limpa assistências e efeitos de pouso também nas salas antigas.

O hitstop existente continua como único responsável pelo relógio: 60/90 ms, parry 80 ms e escala 0,08. A câmera existente atende câmera fixa e acompanhamento; só acerto pesado treme 3 px/110 ms. Flash branco no alvo dura dois quadros renderizados. Recuo usa 1,1/2,1 m/s, atrito 12 m/s² e limite 0,5 m. Sangue/poeira usam retângulos de 2 px, paletas do P40 e orçamento comum. Pouso desloca o sprite em 2 px por 80 ms; não altera cápsula ou escala. Antecipação 18 px, suavização 8/s e offset final inteiro; a câmera não recalcula física por zoom.

Medição nova a 60 Hz: toque curto 1,000400 m, ápice 13 ticks; segurado 2,314903 m, ápice 20 ticks, voo 41 ticks. g/v0, velocidades, dash, máscara, corpo/hurtbox e pivô das fases aprovadas não mudam.

**Inimigos:** `scripts/enemies/presentation/` lê o mesmo formato `animacoes[]/quadros[]`, PNG/SHA256, ms, âncora, sombra, FX com fase e hitboxes. Mapas separados traduzem estados/IDs de ataque. Ausente/inválido/sem animação correspondente preserva arte original; sem geometria preserva ataque nativo. Ataque perfilado com quadro vazio fica sem dano naquele quadro. Amostragem por fase usa os tempos do ataque original: adaptar cadência artística não muda IA ou `.tres`. Consultar após movimento resolvido; uma ação mantém um UID entre todos os quadros. F3 desenha também as peças ACTIVE dos inimigos.

Projéteis têm animação/âncora dedicada opcional em `projeteis`; caixas do disparo junto ao bico não são deslocadas para a bala. Sem esse dado, o projétil conserva core/área/velocidade/vida/parry originais. Pacote falso mínimo é restrito à suíte de teste. Os pacotes finais de Peregrino/Corvo ainda não foram entregues; não substituí-los por arte inventada. Contrato completo em `CONTRATO_PACOTE_INIMIGO.md`.

Backup remoto inicial: `feature/integracao-p40@68807ee8bbcada0bfd3e6dec59b6da7e99661181`. Esta tarefa autoriza commit/push somente deste branch. Nenhum push ou merge do main. Relatório e testes atuais ficam na fase F5; registros F1–F4 permanecem históricos.


## 8. Tarefa 4.5 — Peregrino Profanado

Pacote aprovado `pacote_inimigo_peregrino_v1.zip`, só leitura, 160 arquivos copiados intactos para `assets/enemies/peregrino_v1/`. Não usar o Corvo humanoide como inimigo: pertence à máscara jogável Corvo; ave e Raiz seguem provisórias.

Mapa do Peregrino liga IDLE/PATROL/ALERT/CHASE/HURT/RUPTURE/DEATH às animações próprias e os seis IDs de ataque aos cinco golpes. A lista `ataque[]` separa as duas partes do corte duplo, mantendo os tempos e UIDs originais. Efeitos respeitam camada/fase; aviso pálido nos golpes aparáveis, vermelho na penitência. A arma provisória fica oculta só com apresentação nova ativa. Ruptura toca a entrada uma vez e repete quadros 3–6; morte segura o quadro 7 sem rotação legada.

Hurtbox fixa sugerida: raio 7/altura 44 px → raio 7,777778/altura 48,888889 unidades; centro Y=−8,944444, base Y=15,5. Vale somente para Peregrinos equipados com pacote válido, em ambas as salas. Colisor de locomoção de 7/31 unidades, IA, tuning, dano e física do jogador intocados. A sugestão alternativa de 34 px na ruptura permanece desativada; morte desliga a área pelo caminho original.

F3: hurtbox em ciano, âncora dos pés, animação/quadro/fase e peças de dano ACTIVE. A etapa futura **balanceamento de inimigos** deve considerar os 31 contatos alterados em 108 ensaios (42 → 45 acertos totais): maior alcance frontal, folga de três golpes no ensaio colado de 8 px e ataques altos. Não reajustar IA nesta entrega. Também reavaliar leitura de ruptura/morte em ×1 e a regeneração preexistente da postura após a morte. Relatório/testes/prints/clipe em F6; evidências anteriores preservadas. Commit e push somente de `feature/integracao-p40`, sem merge.
