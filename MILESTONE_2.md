# The Refusal — Milestone 2: combate humano básico

Estado: implementado e validado no Godot 4.7.2. Escopo limitado à espada simples do prólogo e a um dummy de teste.

## Arquitetura

- `Player` recebe o Input Map e coordena movimento, orientação, câmera e `PlayerCombat`. O movimento e a câmera do Milestone 1 continuam em seus componentes.
- `PlayerStateMachine` mantém estados separados de locomoção (chão/ar) e ação (livre/atacando). `PlayerCombat` controla preparação, janela ativa, recuperação, fila e expiração do combo.
- Cada golpe é um `AttackData` independente em `data/attacks/`. Dano canônico, tags e tempos de teste estão nos recursos, fora do controlador.
- `Hitbox2D` detecta contatos e impede mais de um acerto no mesmo receptor por ação, inclusive quando ele tiver várias hurtboxes. `Hurtbox2D` encaminha o `HitContext` para `HealthComponent`.
- `HitContext` contém atacante, alvo, tipo, tags, IDs únicos de ação/acerto, dano-base, dano efetivo e valor futuro de Postura, além de campos para direto, crítico e proc. Esses sistemas futuros não são calculados neste milestone.
- `HitStop` é um autoload reutilizável. Apenas acertos válidos o acionam. Durante o intervalo de relógio real, a escala temporal fica em 0,08 e volta ao valor anterior automaticamente.
- Arma geométrica, indicador de hitbox, flash e números de dano são placeholders. O dummy é estático, sem IA, com 500 HP e reset.

## Golpes e tempos iniciais

Os danos de HP e os valores reservados de Postura seguem a Bíblia Canônica/Técnica v3.0. Os tempos e multiplicadores abaixo são parâmetros provisórios de jogabilidade, concentrados nos recursos de cada golpe.

| Golpe | HP | Postura futura | Preparação | Ativo | Recuperação | Movimento | Hit stop |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Light 1 | 20 | 8 | 90 ms | 100 ms | 170 ms | 70% | 30 ms |
| Light 2 | 22 | 9 | 100 ms | 100 ms | 180 ms | 65% | 30 ms |
| Light 3 | 28 | 14 | 130 ms | 120 ms | 280 ms | 40% | 35 ms |
| Heavy | 35 | 25 | 240 ms | 120 ms | 360 ms | 20% | 55 ms |

Light 1 aceita a próxima entrada a partir de 200 ms do início; Light 2, a partir de 220 ms. Após Light 1 ou 2 terminar, há mais 180 ms para a próxima entrada. Pressionar cedo demais não guarda a ação. Light 3 e Heavy encerram a sequência. Não há cancelamento nem ataque aéreo nesta etapa.

## Controles

| Ação | Teclado | Controle |
| --- | --- | --- |
| Andar | A/D ou setas | Eixo horizontal esquerdo |
| Pular | Espaço | A / botão 0 |
| Light | J | X / botão 2 |
| Heavy | K | Y / botão 3 |
| Reset do dummy | R | — |

## Arquivos

Criados: quatro recursos `data/attacks/*.tres`; `scripts/combat/attack_data.gd`, `hit_context.gd`, `health_component.gd`, `hurtbox_2d.gd`, `hitbox_2d.gd`, `hit_stop.gd`; `scripts/player/player_combat.gd`; `scripts/test/dummy.gd`; `scenes/test/dummy.tscn`; `tests/verify_milestone2.gd`; este documento. Os arquivos `.gd.uid` gerados pelo Godot para os scripts também são versionados.

Alterados: `project.godot`, `scenes/player/player.tscn`, `scenes/test_room.tscn`, `scripts/player/player.gd` e `scripts/player/player_state_machine.gd`.

## Validação

Executar da pasta do projeto:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/verify_milestone2.gd
```

O teste automatizado no motor cobre Light 1, Light 1→2, Light 1→2→3, entrada antecipada, expiração da cadeia, Heavy, dano e tags, IDs, alvo com duas hurtboxes, ataques nas duas direções, erro de alcance, hit stop válido/ausente, parede, movimento durante golpe, gravidade, pulo, câmera e reset do dummy. A cena principal também foi executada com renderização OpenGL; o placeholder e o dano no dummy foram inspecionados visualmente. O projeto foi reaberto no editor e executado novamente após a importação.

Avisos do ambiente local: o Godot registra `Failed to read the root certificate store` no Windows, inclusive na execução estável anterior. Na abertura automatizada do editor, também não conseguiu salvar suas preferências globais em `AppData/Roaming/Godot`; o projeto abriu e importou normalmente. Não houve erro de cena, script ou gameplay na validação final.

## Fora deste milestone

Dodge, Parry, Postura/Ruptura funcional, Heavy carregado, inimigos reais, Máscaras, habilidades, Ultimate, sistemas de status, Relíquias, Maldições, Pactos e arte definitiva permanecem para etapas futuras. O próximo milestone deve ser definido e validado separadamente.
