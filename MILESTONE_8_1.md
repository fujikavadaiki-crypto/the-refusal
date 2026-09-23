# Milestone 8.1 — fechamento do Carrasco Base

Base: Godot 4.7.2 stable; commit do Milestone 8 `9f7e54df6accb75c4bd83226e3b5c15806ea509e`. Nenhum encontro do Bosque ou script de inimigo foi alterado.

## Diagnóstico e configuração preexistente

- Antes das edições, `main` estava no commit esperado. Havia somente uma alteração preexistente em `project.godot`: o editor Godot expandira a serialização de cinco entradas de teclado do Input Map, preservando os mesmos `physical_keycode` e ações. Esta configuração válida foi preservada; a seção `test_execution` passou a chamar-se `execute`.
- Não existe classificação de elite/miniboss/boss nos três inimigos oficiais atuais. A infraestrutura do Milestone 8 já distinguia esses níveis pela metadata `execution_tier`, com `common` como padrão; essa regra foi mantida para os mocks técnicos.
- A linha de base anterior à implementação passou nos testes dos Milestones 2, 3, 4, 4.1, 5, 6, 7, 7.1 e 8.

## Charged Heavy

- `AttackData` agora pode apontar para `charged_variant`, definir `charge_threshold_seconds` e multiplicador de movimento durante a preparação. O Heavy humano existente continua imediato porque não tem variante configurada.
- O Heavy do Carrasco usa a mesma ação `attack_heavy` (`K` no binding atual). Pressionar inicia a preparação; soltar antes de 1,0 s dispara o Heavy normal `58/42`. Soltar a partir de 1,0 s dispara o Charged Heavy `78/65`. O threshold é valor provisório de playtest.
- Durante a carga, o movimento é multiplicado por `0,45` além do modificador de velocidade do Carrasco. Esse valor é provisório. O marcador técnico muda de âmbar para vermelho e o DebugLabel mostra `CHARGED READY` quando o threshold é atingido.
- Dodge cancela a carga antes de iniciar o Dash; dano recebido a interrompe; troca de Máscara bem-sucedida também a cancela. Uma carga cancelada nunca arma hitbox nem guarda golpe para depois. Air Heavy e ataques iniciados durante Dash continuam usando o fluxo anterior.
- O Charged Heavy usa o mesmo `PlayerCombat`, hitbox, dano e eventos do Heavy normal. A tag `heavy` gera uma Condenação por acerto válido, ou duas durante Tribunal. Ruptura causada pelo golpe continua acrescentando dois stacks separadamente, uma única vez.

## Execução em gameplay

- A ação semântica `execute` substitui `test_execution` no Input Map. `H` permanece **binding físico provisório**. O Player encaminha essa ação ao `MaskController` somente em gameplay; a arena não executa por conta própria.
- `ExecutionTargeting` é uma `Area2D` curta sobre o Player, lendo apenas Hurtboxes próximas. O alcance por distância entre os centros é `52 px`, provisório e coerente com o alcance curto dos golpes. Entre candidatos elegíveis e visíveis, vence o mais próximo; empate favorece a direção do Player. Uma consulta de linha de visão na camada sólida impede Execução através de parede ou de outro corpo. Não há lock-on persistente nem teleporte.
- `ExecutionResolver` valida novamente alcance, linha de visão e elegibilidade no momento do golpe. Só o Carrasco ativo pode ativá-lo. Um segundo pedido contra alvo morto é recusado. Condenação e callbacks desse alvo são limpos após morte.
- Common: HP estritamente abaixo de 15%, três stacks e oportunidade ativa; o golpe causa morte instantânea. Elite, miniboss e boss: três stacks e oportunidade ativa; recebem Execution Strike por dano comum baseado no Heavy e consomem três stacks após acerto confirmado. Não recebem morte forçada nem cap artificial de HP.

## Ruptura e oportunidade

- A oportunidade normal acompanha a Ruptura física e fecha quando ela termina. `CarrascoRuntimeState` observa os sinais de Ruptura e recuperação dos alvos que têm Condenação, com referências fracas e desconexão na limpeza.
- Se Tribunal estava ativo quando o alvo elegível entrou em Ruptura, a recuperação física inicia `1,0 s` de oportunidade adicional. Isso vale também para Execution Strike em elite/miniboss/boss. Se o próprio golpe que causou a Ruptura completou os três stacks, o estado registra a elegibilidade depois de aplicar esses stacks.
- A extensão é um contador separado: não altera duração da Ruptura, recuperação de Posture, stun ou bônus de dano sofrido durante Ruptura. O contador continua enquanto Carrasco está em reserva; outra Máscara não pode executar. Ativar Tribunal **depois** da Ruptura não concede extensão retroativa.
- As condições de HP e Condenação continuam verificadas quando a Execução é acionada. O temporizador de Condenação conserva a regra anterior: congelado na Ruptura física e retomado após sua recuperação.

## Arena e feedback provisório

- `scenes/test/carrasco_arena.tscn` mantém o dummy comum e o Peregrino e acrescenta `EliteDummy`, identificado somente na arena como `execution_tier=elite`. Indicadores temporários `EXECUTABLE` e `EXECUTABLE +1s` aparecem sobre alvos elegíveis. O painel mostra o estado da carga, alvo selecionável e controles. `R` limpa os estados de Condenação dos alvos técnicos junto com o reset.
- O marcador de carga, os textos de execução e o golpe sem animação final são instrumentos de playtest. Não representam arte ou game feel aprovados.

## Arquivos

Criados: `data/attacks/carrasco_charged_heavy.tres`, `scripts/masks/execution_targeting.gd` e seu `.uid`, `tests/verify_milestone8_1.gd` e seu `.uid`, e este documento.

Alterados: `data/attacks/carrasco_heavy.tres`, `project.godot`, `scenes/player/player.tscn`, `scenes/test/carrasco_arena.tscn`, `scripts/combat/attack_data.gd`, `scripts/masks/carrasco_runtime_state.gd`, `execution_resolver.gd`, `mask_controller.gd`, `mask_runtime_state.gd`, `scripts/player/player.gd`, `player_combat.gd`, `player_defense.gd`, `scripts/test/carrasco_arena.gd` e `tests/verify_milestone8.gd` (adequação à nova verificação de alcance).

## Validação

- `tests/verify_milestone8_1.gd`: **PASS**. Cobre os 27 cenários pedidos, valores do moveset, dano real pela hitbox, cancelamento por dano, linha de visão, seleção entre alvos, troca durante a janela, condições temporais e limpeza de alvo destruído.
- Testes dos Milestones 2, 3, 4, 4.1, 5, 6, 7, 7.1 e 8 após as mudanças: todos **PASS**, exit code 0, em física normal. O teste específico 8.1 também passou após os últimos ajustes.
- Editor, cena principal e arena reabertos no Godot 4.7.2 stable, sem erros de cena ou script; ambas as cenas encerraram com exit code 0. O ambiente emite `Failed to read the root certificate store` antes de carregar o projeto, aviso também presente na linha de base. Logs e cache ficaram em `.godot/`, ignorada pelo Git.
- Playtest humano pendente para avaliar legibilidade, tempo percebido da carga, responsividade de cancelamento, alcance de Execução e sensação do Execution Strike. Testes automatizados verificam funcionamento, não aprovam game feel.

## Fora deste milestone

Ressonância, evoluções, outras Máscaras, rotas, Relíquias, Maldições, Pactos, loot, save novo e arte final não foram implementados.
