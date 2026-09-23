# Milestone 4 — Peregrino Corrompido

## Escopo e cena

O primeiro inimigo real está em `scenes/enemies/peregrino.tscn`. Para jogar este marco, abra e execute `scenes/test/peregrino_arena.tscn` com **F6** no Godot 4.7.2. Ela instancia a sala técnica dos marcos anteriores, mantém Dummy e TrainingDevice e coloca o jogador no trecho plano diante de um único Peregrino. A cena principal original continua disponível para regressão. A figura do Peregrino é um placeholder de capuz, manto gasto, musgo, rosto pálido e bastão com talismã, orientado pela Bíblia Visual Oficial; não é arte final.

## Arquitetura

- `Peregrino` é o CharacterBody2D, dono de colisão, apresentação, reset e conexão dos sinais.
- `PeregrinoBrain` decide percepção, patrulha, perseguição e escolha dos golpes. Não lê `Input`; usa posição, distância, diferença de altura, linha de visão por raycast e HP observado.
- `PeregrinoAttack` executa WINDUP, ACTIVE e RECOVERY, trava o facing na metade do preparo, movimenta o bastão e arma/desarma o `Hitbox2D` existente.
- `PeregrinoTuning` guarda parâmetros **provisórios de playtest** da IA e movimentação.
- `AttackData` guarda cada golpe. Dano, Postura e classificação de Parry são os valores canônicos; geometria e tempos são provisórios.
- `HealthComponent`, `PostureComponent`, `DefenseStats`, `Hurtbox2D`, `HitContext`, `DamageResolver` e `HitStop` são os mesmos componentes usados no combate já aprovado. Nenhuma fórmula paralela foi criada.

Estados explícitos: `IDLE`, `PATROL`, `ALERT`, `CHASE`, `ATTACK_WINDUP`, `ATTACK_ACTIVE`, `ATTACK_RECOVERY`, `HURT`, `RUPTURE`, `DEATH`. `HURT` é reação breve para deslocamento normal; um Light durante um ataque dá feedback visual e não cancela toda ação. `RUPTURE` cancela o ataque, imobiliza e expõe o inimigo. `DEATH` prevalece quando HP e Postura chegam a zero no mesmo contato, desativa ataque, hitbox recebida e colisão corporal. O reset restaura posição, HP, Postura, IA, cooldown, hitboxes e facing.

## Valores canônicos

| Golpe | HP | Postura | Parry |
|---|---:|---:|---|
| Corte | 12 | 8 | Sim |
| Estocada | 14 | 10 | Sim |
| Investida | 18 | 14 | Sim |
| Corte Duplo, primeiro golpe | 10 | 6 | Sim |
| Corte Duplo, segundo golpe | 12 | 8 | Sim |
| Golpe da Penitência | 25 | 22 | Não |

O Peregrino tem **100 HP e 40 Postura**. Abaixo de 30% de HP, a cadência e a velocidade de perseguição sobem aproximadamente 15%. A Ruptura usa a vulnerabilidade **+20%** e a restauração de aproximadamente **50%** de Postura já previstas pelo sistema.

## Valores provisórios de playtest

Os parâmetros abaixo não são cânone. Estão em `data/enemies/peregrino_tuning.tres`, nos recursos de `data/attacks/peregrino_*.tres` e na cena do inimigo.

| Golpe | WINDUP | ACTIVE | RECOVERY | Centro/área da hitbox em px |
|---|---:|---:|---:|---|
| Corte | 0,36 s | 0,11 s | 0,36 s | 19; 18 × 7 |
| Estocada | 0,43 s | 0,10 s | 0,42 s | 23; 22 × 6 |
| Investida | 0,54 s | 0,18 s | 0,52 s | 24; 24 × 8 |
| Corte Duplo 1 | 0,29 s | 0,09 s | 0,11 s | 19; 18 × 7 |
| Corte Duplo 2 | 0,22 s | 0,10 s | 0,40 s | 19; 18 × 7 |
| Penitência | 0,69 s | 0,14 s | 0,65 s | 21; 21 × 9 |

Percepção horizontal 170 px e vertical 45 px; perda por distância da origem 230 px; meia patrulha 56 px; velocidade de patrulha 29 px/s e perseguição 64 px/s; aceleração 420 px/s²; gravidade 800 px/s²; início ofensivo a 32 px com tolerância de 5 px; zona morta do facing 8 px; alerta 0,28 s; espera inicial 0,55 s; reação HURT 0,10 s; cooldown entre ataques 0,42 s; avanço da Investida 88 px/s. A sonda de borda olha 11 px à frente e 25 px para baixo. Regeneração da Postura: atraso 2 s, 10 pontos/s; Ruptura: 2 s; proteção pós-Ruptura: 0,35 s. Dimensões de colisão e visual são provisórias. HitStop por golpe: 30, 35, 45, 25, 30 e 55 ms, na ordem da tabela. O bônus de ~15% usa velocidade ×1,15 e cooldown ÷1,15 abaixo de 30% HP.

O telegraph é local ao bastão: verde pálido nos golpes parryable, vermelho no Golpe da Penitência. O facing pode acompanhar o jogador apenas na primeira metade do WINDUP; depois fica comprometido até o fim do golpe. O Corte Duplo abre duas janelas de hit distintas, cada uma com sua ação e um contato máximo por alvo. O ataque não usa fila artificial de inimigos.

## Controles e validação

Na arena: `A/D` ou setas para mover, `Espaço` para pular, `J` Light, `K` Heavy, `L` Dodge, `I` Parry e `R` para resetar o Peregrino e os dispositivos de treino da sala. `T/G` continuam acionando o TrainingDevice. O texto sobre o Peregrino é diagnóstico temporário, não HUD definitivo.

`tests/verify_milestone4.gd` testa percepção, fases da IA, ataque real, fuga durante WINDUP, Parry, Dodge, dano recebido, Light, Heavy, Corte Duplo, golpe não parryable, Ruptura, vulnerabilidade, recuperação, morte, reset e dois minutos simulados sem atacar o inimigo. Regressões dos marcos anteriores usam `tests/verify_milestone2.gd`, `tests/verify_milestone3.gd` e o verificador visual do Milestone 1 já existente no ambiente de trabalho.

Validação nesta sessão: `verify_milestone4.gd` **PASS** (inclusive os cinco golpes, duas janelas do Corte Duplo e 7.200 frames de combate autônomo); regressão da revisão visual do Milestone 1 **PASS**; Milestones 2 e 3 **PASS**. A arena foi executada em uma janela do Godot 4.7.2 e inspecionada durante `ATTACK_WINDUP`; a silhueta, a proporção com o protagonista e o telegraph localizado ficaram legíveis. O verificador antigo do Milestone 1, anterior à ampliação da sala para 2.400 × 270, ainda contém coordenadas antigas e falha em quatro comparações de geometria; o verificador atualizado passou. Não houve erro de script no jogo. A execução isolada exibiu um aviso do ambiente sobre leitura do certificado raiz do Windows, sem afetar o gameplay.

A revisão explícita dos scripts confirma que `PeregrinoBrain` e `PeregrinoAttack` não consultam `Input`; somente o nó `Peregrino` lê a ação `reset_dummy` para o comando de debug `R`.

Os parâmetros provisórios e o feel de aproximação, leitura, posicionamento e punição ainda precisam de playtest humano antes de serem aprovados. Não há loot, segundo inimigo, mapa real do Bosque ou sistemas futuros neste marco.
