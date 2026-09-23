# Milestone 8 — infraestrutura de Máscaras e Carrasco Base

Projeto: Godot 4.7.2 stable. Esta etapa parte do commit `9ecb2335676ab173803d94254aa932a810654989` do Milestone 7.1 e mantém a fatia do Bosque intacta.

## Arquitetura

- `MaskData` é um Resource com modificadores, moveset, Skills e Ultimate. Não substitui o Player.
- `MaskController` pertence ao Player atual e contém exatamente dois slots. Cada `equip` cria um `MaskRuntimeState` independente. Slots podem ser nulos. O slot ativo determina moveset e modificadores; o outro é reserva.
- Os dois estados recebem `tick(delta)` mesmo quando inativos. Cooldowns e Condenação não reiniciam na troca. O cooldown de troca é global. Ao sair da Máscara, a Ultimate ativa termina; seu cooldown prossegue.
- A troca limpa apenas a fila da combinação de ataques do PlayerCombat, impedindo que o Light 2 de uma Máscara apareça como primeiro golpe da outra.
- Modificadores são recalculados a partir dos valores base capturados no Player. Max HP e Max Posture preservam a porcentagem atual. Nenhuma troca concede cura, recuperação de Posture, i-frame ou recarga de Air Dash.
- O `PlayerCombat` continua com uma hitbox e um sistema de ataques. `Hitbox2D.before_hit` aplica modificadores por alvo ao `HitContext`; `DamageResolver`, `HealthComponent` e `PostureComponent` existentes fazem a resolução. Um contato sem dano da Marca usa `Outcome.CONTACT`.
- `CarrascoRuntimeState` guarda Condenação por alvo com `WeakRef`, tempo e bônus temporário da Marca. Alvos mortos ou liberados são removidos. O tempo da Condenação congela durante a Ruptura do respectivo alvo e segue normalmente com Carrasco em reserva.
- `ExecutionResolver` expõe elegibilidade e execução para gatilho técnico; ainda não define controle canônico ou janela final.

## Canônico implementado

- Dois slots e cooldown global inicial de 10 s. A troca de Máscara requer Player livre de ataque/defesa em curso, para não alterar atributos no meio de um golpe.
- Carrasco Base: +20% de ataque físico, +25% de dano de Posture, −8% de velocidade; sem Defesa, Max HP ou Max Posture extras. Parry universal mantém janela de 160 ms e devolve +20% de Posture. Ground Dash e Air Dash universais permanecem sem Phase Dash.
- Moveset em AttackData: Light 1 `30/16`, Light 2 `34/18`, Light 3 `44/28`, Heavy `58/42`, Post-Dodge `32/18`, Air Light `34/22`, Air Heavy `52/45` (HP/Posture base). Os modificadores da Máscara são aplicados na resolução; por exemplo, um Light 1 sem defesa produz 36 HP e 20 Posture com Carrasco ativo.
- Condenação: limite de 5 stacks por alvo; Heavy válido +1; Parry perfeito +1 no atacante específico; Ruptura causada pelo Carrasco +2 no alvo rompido; Marca +2 somente após contato. Heavy durante Tribunal adiciona +2 no total. Cada stack acrescenta 3 pontos percentuais de dano de Posture do Carrasco naquele alvo. Outra Máscara não herda o bônus.
- Quebra-Selos: base `50/70`, cooldown de 8 s e +50% de dano de Posture apenas quando `DefenseStats` declara explicitamente shield, armor ou posture protection. Nenhum inimigo existente recebeu proteção artificial.
- Marca do Condenado: contato frontal sem dano inventado, +2 stacks; quando havia 3 ou mais antes do contato, +20% de ataque físico do Carrasco apenas contra aquele alvo por cerca de 5 s.
- Tribunal: 8 s, +30% de ataque físico e +40% de dano de Posture enquanto ativo. Termina ao trocar de slot; cooldown não reinicia.
- Execução comum: exige HP estritamente abaixo de 15%, alvo em Ruptura e ao menos 3 stacks; gatilho técnico causa morte instantânea pelo `HealthComponent` existente. Elite/miniboss/boss usam Execution Strike (golpe baseado no Heavy atual), sem morte forçada e com consumo de 3 stacks após acerto confirmado. A classe do alvo é declarada por metadata `execution_tier`; ausente significa comum. Nenhum inimigo oficial foi alterado.

## Valores provisórios de playtest

- Condenação: 10 s por aplicação, renovados em nova aplicação.
- Bônus da Marca: 5 s. Cooldown da Skill 2: 10 s conforme indicação aproximada da Bíblia Canônica v3.0.
- Cooldown de Tribunal: 30 s, configurável no Resource; sua duração de 8 s é canônica.
- Tempos, formas de hitbox e hit stop dos novos ataques são ajuste técnico inicial. Não representam game feel aprovado.
- `U`: Skill 1; `O`: Skill 2; `P`: Tribunal; `Tab`: troca. `H`: execução técnica apenas na arena, contra o alvo elegível mais próximo e a até 58 px. Essas teclas são bindings de desenvolvimento no InputMap, não layout final.
- Para alvos elite/miniboss/boss, o protótipo exige Ruptura e 3 stacks, sem limite de HP; o golpe regular pode derrotar o alvo por dano normal. A semântica definitiva da janela de Execução ainda será integrada.

## Cena, testes e regressões

- `scenes/test/carrasco_arena.tscn` instancia a sala de treino existente, equipa Carrasco no slot A, deixa B vazio e acrescenta o Peregrino existente. A leitura técnica mostra Máscara, cooldowns, stacks do alvo mais próximo e `EXECUTABLE`. O Bosque e seus cinco encontros não foram editados.
- `tests/verify_milestone8.gd` cobre os 37 requisitos listados, além de porcentagem de atributos, independência dos slots, proteção explícita, InputMap, acerto real pela hitbox, contato real da Marca, Heavy real que causa Ruptura uma vez, integração do Parry, bloqueio físico do Dash, movimento, pulo e câmera. Resultado: **PASS** em Godot 4.7.2 stable.
- Testes existentes dos Milestones 2, 3, 4, 4.1, 5, 6, 7 e 7.1: todos **PASS**, exit code 0, em execução normal de física. A suíte longa do Bosque alcançou a saída. Não foi executado modo fixed-fps, que já apresentava limitações de timeout em testes antigos.
- O editor reabriu o projeto com importação das novas classes sem erro de script; execução de arena e cena principal confirmada em nova inicialização. O ambiente emitiu somente `Failed to read the root certificate store`, sem relação com scripts ou cenas do projeto. As preferências do editor foram redirecionadas para cache local durante a validação para evitar escrita fora do workspace.

## Arquivos

Criados: `scripts/masks/mask_data.gd`, `mask_runtime_state.gd`, `carrasco_runtime_state.gd`, `mask_controller.gd`, `execution_resolver.gd`; `data/masks/carrasco_base.tres`; nove `data/attacks/carrasco_*.tres`; `scenes/test/carrasco_arena.tscn`; `scripts/test/carrasco_arena.gd`; `tests/verify_milestone8.gd`; este documento. Os `.gd.uid` gerados pelo Godot acompanham os novos scripts, de acordo com o padrão do projeto.

Alterados: `project.godot`, `scenes/player/player.tscn`, `scripts/player/player.gd`, `player_combat.gd`, `player_defense.gd`, `scripts/combat/hit_context.gd`, `hitbox_2d.gd`, `health_component.gd`, `posture_component.gd`, `damage_resolver.gd`, `defense_stats.gd`.

## Pendente para outro milestone

- Charged Heavy `78/65` com carga aproximada de 1 s: ainda não existe carregamento universal de ataques. O valor está registrado, sem criar um sistema amplo nesta etapa.
- Regra aprovada existente: “execution window +1 s durante Tribunal”. Ativação exata pendente de integração final do Execution input/window.
- Controle e animação definitivos de Execução, evolução do Carrasco, Ressonância, Corvo, arte final, loot, save e demais sistemas excluídos do escopo.
- Playtest humano para avaliar ritmo dos três Lights, Heavy, Post-Dodge, ataques aéreos, distâncias, legibilidade e game feel. Os testes técnicos não aprovam sensação de jogo.
