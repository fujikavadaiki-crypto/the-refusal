# The Refusal — Milestone 3: Dodge, Parry, Postura e Ruptura

Estado: implementado sobre o commit `928061e` e validado no Godot 4.7.2. Esta fatia permanece na sala de teste, com placeholders e sem inimigos reais.

## Arquitetura

- `Player` continua apenas coordenando Input Map, movimento, combate, defesa, estados e câmera. `PlayerDefense` controla Dodge, i-frames, Parry, recuperação e stagger. `PlayerCombat` mantém os golpes do Milestone 2 e pode ser interrompido por Ruptura.
- `PostureComponent` é separado de `HealthComponent`. Ele controla atraso de regeneração, recuperação, Ruptura e proteção curta após quebra. Cada ator configura seus tempos e vulnerabilidade sem alterar o componente.
- `DefenseStats` contém Defesa, Resistências Física/Mágica e Resistência de Postura. `DamageResolver` calcula HP e Postura separadamente. `HealthComponent` resolve cada contato na ordem: alvo válido → i-frame → Parry compatível → HP e Postura mitigados → aplicação conjunta → Morte antes de Ruptura.
- `HitContext` conserva IDs únicos, origem, alvo, tipo, tags e dano do Milestone 2; agora inclui resultado do contato, categoria de Parry, dano efetivo de Postura, multiplicador de dano de Postura e flags de bypass. `Hitbox2D` mantém um acerto resolvido por alvo e ação. Uma segunda hurtbox do mesmo receptor não duplica o golpe.
- `HitStop` aceita prioridade. Parry (80 ms, prioridade 2) domina o hit stop normal (prioridade 1); durações não são somadas.
- O dummy ganhou Postura e Ruptura. `TrainingDevice` é um dispositivo manual sem IA, com um golpe parryable e um Heavy não-parryable. Telegraph e áudio ficam no objeto ofensivo. A cor de Ruptura, o brilho da arma, o spark, os números e sons são provisórios.

## Valores usados

| Sistema | Protagonista | Dummy / dispositivo de treino |
| --- | --- | --- |
| Vida máxima | 100 | 500 / 200 (teste) |
| Postura máxima | 100 | 40 / 40 (teste) |
| Atraso após dano de Postura | 1,5 s | 2 s (teste) |
| Recuperação de Postura | 25/s | 10/s (teste) |
| Ruptura | 0,8 s de stagger | 2 s |
| Postura após Ruptura | 50% | 50% |
| Proteção contra nova quebra | 0,35 s | 0 s |
| Vulnerabilidade durante Ruptura | nenhuma | +20% dano recebido |

Dodge: 400 ms no total; i-frames de 70 a 250 ms (180 ms); velocidade horizontal inicial de 2× o movimento normal; intervalo de 280 ms após o fim do Dodge para repetir. Só começa no chão e não cancela golpes. Parry: 160 ms ativos, 380 ms totais, uma única defesa válida por ação, sem invulnerabilidade restante; retorno de Postura igual à pressão de Postura do impacto, multiplicada pelo atributo de Parry e depois pela Resistência de Postura do atacante. Hit stop de sucesso: 80 ms.

Os quatro danos de HP/Postura da espada permanecem **20/8, 22/9, 28/14 e 35/25**. O dispositivo usa valores exclusivamente de treino: golpe parryable **18 HP / 12 Postura** com preparação de 450 ms; Heavy não-parryable **30 HP / 25 Postura** com preparação de 700 ms. São parâmetros de teste, não estatísticas de inimigos canônicos. Os demais tempos ficam nos respectivos recursos `AttackData`.

Defesa normal: soma bônus dentro do atributo, com teto de 70%. Defesa temporária explícita pode chegar a 85%. Resistência Física ou Mágica é uma camada multiplicativa após a Defesa; a redução efetiva normal fica limitada a 85%. Postura ignora Defesa e resistências de HP, usando apenas Resistência de Postura. Exemplo validado: 100 Mágico × 0,70 Defesa × 0,80 Resistência Mágica = **56 HP**; 25 Postura × 0,80 Resistência de Postura = **20 Postura**. Bypass seletivo de Defesa preserva resistência compatível; Perda Direta de Vida tem rota própria e não é usada por golpes deste milestone. Barreira e DoTs não foram implementados.

## Controles da sala

| Ação | Teclado | Controle |
| --- | --- | --- |
| Movimento | A/D ou setas | Eixo esquerdo |
| Pulo | Espaço | A / botão 0 |
| Light | J | X / botão 2 |
| Heavy | K | Y / botão 3 |
| Dodge | L | B / botão 1 |
| Parry | I | LB / botão 9 |
| Dispositivo: golpe parryable | T | — |
| Dispositivo: Heavy não-parryable | G | — |
| Reset do dummy e dispositivo | R | — |

## Arquivos

Criados: `MILESTONE_3.md`; `assets/audio/heavy_cue_placeholder.wav` e `parry_confirm_placeholder.wav` com metadados de importação; `data/attacks/training_heavy.tres` e `training_parryable.tres`; `scenes/test/training_device.tscn`; `scripts/combat/damage_resolver.gd`, `defense_stats.gd`, `posture_component.gd`; `scripts/player/player_defense.gd`; `scripts/test/training_device.gd`; `tests/verify_milestone3.gd`. Os `.gd.uid` gerados pelo Godot para novos scripts são versionados.

Alterados: `project.godot`; `scenes/player/player.tscn`, `scenes/test/dummy.tscn`, `scenes/test_room.tscn`; `scripts/combat/attack_data.gd`, `health_component.gd`, `hit_context.gd`, `hit_stop.gd`, `hitbox_2d.gd`; `scripts/player/player.gd`, `player_combat.gd`, `player_state_machine.gd`; `scripts/test/dummy.gd`.

## Validação no Godot

Com o Godot 4.7.2, executar da raiz do projeto:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/verify_milestone3.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/verify_milestone2.gd
```

O teste do Milestone 3 cobre fórmulas, caps, bypass, i-frame e sua borda, direção e repetição do Dodge, câmera, ausência de Air Dodge, Parry cedo/tarde/válido, recuperação, um hit por Parry, Heavy não-parryable, retorno de Postura com resistência, prioridade do hit stop, regeneração e reinício do atraso, Ruptura e proteção do jogador, vulnerabilidade e recuperação do dummy, Morte > Ruptura e contatos reais com hitbox/hurtbox. A regressão do Milestone 2 cobre todos os golpes, combo, colisão e movimento. O teste anterior do Milestone 1 cobre gravidade, pulo, plataformas, limites e câmera. A cena também foi executada em janela OpenGL para inspeção dos telegraphs e feedbacks.

Avisos locais do Godot: falha de leitura do repositório de certificados do Windows e, na execução automatizada do editor, falha ao salvar preferências globais em `AppData/Roaming/Godot`. Não foram observados erros de cena, script ou gameplay na validação final.

## Avaliação humana posterior

Os tempos de Dodge/Parry seguem a referência técnica, mas **distância do Dodge, brilho local, som, sensação do stagger e duração da Ruptura de alvos** ainda pedem playtest humano. Ajustes nesses parâmetros devem preservar as regras canônicas.

Peregrino, Corvo, Raiz Faminta, Bosses, Máscaras, Carrasco, sistemas de status, Relíquias e demais sistemas posteriores permanecem fora deste milestone.
