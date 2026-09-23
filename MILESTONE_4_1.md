# Milestone 4.1 — Air Dash e ataques durante Dash

## Escopo e arquitetura

Este marco amplia exclusivamente a mobilidade ofensiva do protagonista. `PlayerDefense` controla Ground Dodge, Air Dash, carga aérea, i-frames e cancelamento ofensivo; `PlayerCombat` escolhe o golpe a partir do contexto de chão/ar e continua usando `AttackData → Hitbox2D → HitContext → Hurtbox2D → DamageResolver → HitStop`; `PlayerLocomotion` move o corpo e suspende a gravidade durante o Air Dash; `PlayerStateMachine` distingue `DODGING`, `AIR_DASH` e `AIR_ATTACK`. `player.gd` apenas encaminha input e coordena esses componentes. Nenhuma lógica de IA ou golpe do Peregrino foi alterada.

Um Air Dash fica disponível ao sair do chão, tanto por pulo quanto por queda de plataforma. O uso consome a carga. Só `is_on_floor()` após `move_and_slide()` a restaura; paredes, laterais de plataformas, colisão com inimigo, ataque, acerto, Parry e dano recebido não o fazem. O Dash é horizontal, usa direção pressionada ou facing atual, respeita geometria e não concede dano de queda ou voo. Durante o Air Dash, a velocidade vertical fica em zero; gravidade normal retorna quando ele acaba ou é cancelado.

Ground Dodge e Air Dash não admitem Parry simultâneo. Depois de Ground Dodge, o Parry volta a seguir suas regras anteriores. O Parry aéreo continua indisponível, como antes deste marco. Ataques já comprometidos ainda não podem ser cancelados universalmente para Dodge.

Após a janela inicial de 80 ms, Light ou Heavy podem cancelar o restante de ambos os Dashes. O ataque começa e o estado defensivo termina no mesmo frame: os i-frames cessam imediatamente. Inputs ofensivos antes da janela são ignorados. Ground Dodge + Light usa o novo pós-esquiva; Ground Dodge + Heavy usa o Heavy normal. Air Dash + Light/Heavy usa Air Light/Air Heavy. Ambos os golpes aéreos também podem começar sem Air Dash.

## Valores canônicos

| Ataque | HP | Postura | Origem |
|---|---:|---:|---|
| Pós-esquiva / Dash Light | 22 | 10 | Ground Dodge + Light |
| Heavy normal | 35 | 25 | Ground Dodge + Heavy |
| Air Light | 18 | 7 | No ar, com ou sem Air Dash |
| Air Heavy | 32 | 28 | No ar, com ou sem Air Dash |

O sistema mantém Dodge total de aproximadamente 400 ms e i-frames de 70 a 250 ms, janela efetiva de aproximadamente 180 ms. HitStop continua centralizado. As tags de Dash Light são `physical`, `melee`, `dash_attack`, `light`, `direct`; Air Light/Heavy têm tags de ar compatíveis com `HitContext`.

## Valores provisórios de playtest

| Parâmetro | Valor |
|---|---:|
| Velocidade horizontal de Ground Dodge e Air Dash | 2,0 × velocidade de corrida, atualmente 240 px/s |
| Duração do Air Dash | 0,40 s |
| Início do cancelamento ofensivo | 0,08 s |
| Momentum no início do ataque após Ground Dodge | 45% da velocidade do Dash |
| Momentum no início do Air Light após Air Dash | 65% da velocidade do Dash |
| Momentum no início do Air Heavy após Air Dash | 40% da velocidade do Dash |

Os percentuais acima são aplicados no momento do cancelamento; a desaceleração normal de `PlayerLocomotion` age a partir desse mesmo frame. Air Heavy perde velocidade mais rapidamente, sem virar projétil horizontal. O Ground Dodge conserva seus valores anteriores; Air Dash usa a mesma janela de i-frames. Não há novo Input Map.

| Novo ataque | WINDUP | ACTIVE | RECOVERY | Hitbox (centro x; tamanho) | HitStop |
|---|---:|---:|---:|---|---:|
| Dash Light | 0,10 s | 0,10 s | 0,22 s | 20 px; 14×6 px | 30 ms |
| Air Light | 0,10 s | 0,12 s | 0,22 s | 20 px; 14×6 px | 30 ms |
| Air Heavy | 0,25 s | 0,14 s | 0,40 s | 22 px; 16×8 px | 55 ms |

Timings, momentum, velocidade e geometria dos novos golpes são provisórios. Dano de HP e Postura da tabela canônica não são parâmetros de playtest. A lâmina/indicador muda de cor apenas para distinguir os golpes enquanto a arte final não existe; o texto sobre o jogador é debug, não HUD definitivo.

## Arquivos

- Alterados: `scripts/player/player.gd`, `scripts/player/player_defense.gd`, `scripts/player/player_combat.gd`, `scripts/player/player_locomotion.gd`, `scripts/player/player_state_machine.gd`, `scenes/player/player.tscn` e uma expectativa de teste obsoleta em `tests/verify_milestone3.gd`.
- Criados: `data/attacks/dash_light.tres`, `data/attacks/air_light.tres`, `data/attacks/air_heavy.tres`, `tests/verify_milestone4_1.gd`, seu `.uid` e este documento. O editor também gerou o `.uid` do verificador do Milestone 4, ausente no commit anterior; ele é versionado agora para evitar uma alteração solta sempre que o projeto abre.
- Nenhum arquivo de IA, golpe, cena ou dados do Peregrino foi alterado. Os ajustes de posição anteriores da sala foram descartados após confirmação do usuário, antes da implementação.

## Controles e validação

Os controles permanecem: `A/D` ou setas para mover, `Espaço` para pular, `J` Light, `K` Heavy, `L` Dodge/Dash e `I` Parry. No ar, `L` inicia Air Dash se há carga; `J/K` iniciam Air Light/Heavy. `R` continua resetando o Peregrino na arena técnica.

`tests/verify_milestone4_1.gd` valida carga única, queda de plataforma, parede, colisão com Peregrino, direção/facing, i-frames, Parry bloqueado, cancelamento cedo/tarde, término imediato dos i-frames, momentum, ataques aéreos com/sem Dash e dano/Postura reais dos quatro caminhos ofensivos contra o Peregrino. O teste de Milestone 3 foi atualizado somente na expectativa que negava Dodge aéreo. Os verificadores dos Milestones 1 revisado, 2, 3 e 4 continuam como regressão.

Validação desta sessão: Milestone 4.1 **PASS** no Godot 4.7.2; Milestones 1 revisado, 2, 3 e 4 **PASS**. A cena foi executada em janela e inspecionada durante Air Dash e Air Heavy; a câmera e o telegraph placeholder permaneceram legíveis. A observação prolongada do Peregrino do Milestone 4 foi repetida. O ambiente apresenta aviso de leitura do certificado raiz do Windows. Uma abertura do editor em modo headless não pôde salvar preferências em AppData por restrição do ambiente, sem erro de script no jogo.

Antes de fixar parâmetros provisórios, ainda convém playtest humano de alcance dos golpes em diferentes alturas, resposta do cancelamento aos 80 ms, distância final do Air Dash e sensação do momentum Light/Heavy. Não avançar para o Corvo da Praga neste marco.
