# Milestone 5 — Corvo da Praga

## Escopo e referências

Esta fatia acrescenta somente o segundo inimigo real, em `scenes/enemies/corvo.tscn`, e sua arena técnica `scenes/test/corvo_arena.tscn`. Abra a arena com **F6** no Godot 4.7.2. A sala principal e a arena do Peregrino continuam independentes. A Bíblia Canônica/Técnica v3.0 define números e classificação; a Bíblia Visual Oficial v1.0, p. 14, orienta silhueta, asas abertas, bico, olhos e proporção. Os polígonos são placeholders.

## Arquitetura

- `Corvo` é o `CharacterBody2D`; possui colisão, sinais de dano, apresentação, morte e reset.
- `CorvoBrain` usa distância, posição do jogador, linha de visão e estado real da cena para patrulhar, detectar, escolher distância e decidir o próximo ataque. Não lê input. Quando rasante e projétil são ambos viáveis, sorteio limitado, com peso pela última ação, evita uma alternância rígida.
- `CorvoFlight` interpola velocidade bidimensional e trata queda de Ruptura/morte com colisão no chão. O Corvo não recebe gravidade humanoide durante voo.
- `CorvoAttack` executa preparação, trajetória comprometida, contato, recuperação e disparo. O alvo do rasante trava na metade do preparo. O projétil lançado vira objeto independente; morte cancela apenas o ataque ainda pendente.
- `CorvoProjectile` move e expira o Cuspe. Contato passa por `Hitbox2D → Hurtbox2D → HitContext → HealthComponent → DamageResolver`; não aplica dano em código próprio.
- `CorvoTuning` e os dois recursos `AttackData` concentram os parâmetros de playtest. `HealthComponent`, `PostureComponent`, `DefenseStats` e `HitStop` são reaproveitados.
- `HitContext.parry_posture_return_override` é uma extensão genérica pequena: permite que um golpe retorne uma quantidade canônica específica de Postura no Parry sem mudar seu dano de Postura ao atingir. O Rasante usa 20 de retorno; ao acertar sem Parry continua causando 7. `PlayerDefense` aplica essa informação sem conhecer o Corvo.

Estados: `HOVER`, `PATROL_AIR`, `ALERT`, `POSITIONING`, `DIVE_WINDUP`, `DIVE_ACTIVE`, `DIVE_RECOVERY`, `PROJECTILE_WINDUP`, `PROJECTILE_ATTACK`, `PROJECTILE_RECOVERY`, `HURT`, `RUPTURE`, `TAKEOFF`, `DEATH`. Golpes comuns dão feedback breve sem aprisionar a IA em stun. Ruptura interrompe o ataque, derruba o Corvo e o deixa vulnerável no chão; a recuperação de voo é gradual. Morte também causa queda e desativa a hurtbox.

## Valores canônicos

| Item | Valor |
|---|---:|
| Corvo da Praga | 65 HP; 20 Postura |
| Rasante parryável | 11 HP; 7 Postura |
| Parry perfeito do Rasante | 20 Postura de retorno; queda de aproximadamente 2,5 s |
| Cuspe Pestilento | 8 HP + Praga; não parryável |
| Vulnerabilidade durante Ruptura | +20% de dano de HP, regra geral |
| Postura após Ruptura | aproximadamente 50%, regra geral |

A Bíblia também descreve outros golpes do Corvo, como Garras, Bicada Retorno, Mergulho Pestilento e Batida de Asas. Eles pertencem a fatias futuras; o rasante e o Cuspe bastam para este milestone. O projétil carrega a tag `plague_pending_status`. **APLICAÇÃO DE PRAGA PENDENTE DO MILESTONE DE STATUS**: nesta fatia ele causa apenas HP e Postura; o bônus de +15% Praga/Veneno da ficha também fica pendente do sistema correspondente. Não há efeito improvisado de Status.

## Valores PROVISÓRIOS DE PLAYTEST

Todos os valores a seguir são ajustáveis, não canônicos. Os detalhes estão em `data/enemies/corvo_tuning.tres` (defaults de `CorvoTuning`) e `data/attacks/corvo_*.tres`.

| Grupo | Valores de playtest |
|---|---|
| Percepção e patrulha | alcance 210 px, desligamento 310 px, meia patrulha 42 px, velocidade 25 px/s, espera 0,65 s, alerta 0,30 s; oscilação de patrulha 7 px a 1,7 rad/s |
| Voo | 66 px/s, aceleração 210 px/s², frenagem 260 px/s², faixa Y 92–186 px, altura segura 62 px acima do alvo, altura de preparo 42 px; oscilação de hover 5 px a 2,2 rad/s |
| Posicionamento | distância preferida do projétil 98 px, mínimo 62 px; rasante preferido 62 px, entre 32 e 112 px; tolerância horizontal 12 px e vertical 20 px; reposição mínima 0,40 s; cooldown 0,65 s, com pausa adicional de 0,18 s a cada três ações; sorteio de rasante em faixa compartilhada de 70% após projétil e 35% nos demais casos |
| Rasante | preparo 0,53 s, contato 0,39 s, recuperação 0,56 s, velocidade 205 px/s, subida de preparo 16 px, recuo/subida de recuperação 38/55 px, velocidade vertical mínima 40 px/s, hitbox 17×13 px, HitStop 35 ms |
| Cuspe | **5 de dano de Postura provisório**, tipo de dano `physical` provisório até o sistema de Status, preparo 0,58 s, janela de disparo 0,04 s, recuperação 0,70 s, projétil 125 px/s, expiração 2,2 s, hitbox 8×8 px, HitStop 25 ms |
| Reações | Hurt 0,10 s, gravidade na queda 650 px/s², regeneração de Postura após 2 s a 10 pontos/s, proteção 0,35 s |

As dimensões de corpo, asas, área de colisão e cor do placeholder também são provisórias. A duração geral da Ruptura foi configurada em 2,5 s para refletir a queda canônica do Rasante parryado; seu feel em golpes que quebram Postura sem Parry ainda precisa de playtest humano. `min_flight_y` e `max_flight_y` foram escolhidos para a sala técnica de 480×270 px e não devem virar constantes de mapa definitivo sem revisão.

## Interações e controles

Na arena: **A/D** ou setas movem, **Espaço** pula, **J** Light, **K** Heavy, **L** Dodge/Air Dash, **I** Parry terrestre, **R** restaura o Corvo e os alvos de treino. O texto acima do Corvo mostra `CORVO`, HP, Postura e estado; é diagnóstico temporário.

- O rasante pode ser parryado pelo sistema comum; Parry retorna 20 de Postura e rompe o Corvo de 20 Postura. Dodge e i-frames do Air Dash impedem HP e Postura.
- O Cuspe não aceita Parry; Dodge/i-frames anulam HP e Postura. Cada projétil acerta no máximo uma vez e expira por impacto, obstáculo ou tempo.
- Air Light (18/7) e Air Heavy (32/28) atingem o Corvo. Air Heavy rompe sua Postura; durante a queda ele mantém +20% de vulnerabilidade, depois restaura cerca de 50% e sobe gradualmente.
- Air Dash afasta o jogador de uma trajetória já travada. Air Dash → Light/Heavy alcança o Corvo durante recuperação, com perda imediata dos i-frames ao atacar conforme o Milestone 4.1.
- Morte no preparo cancela disparo; projétil já lançado continua até contato ou expiração. O reset remove todos os projéteis ativos, restaura vida, Postura, estado, posição, facing e cooldowns.

## Validação

`tests/verify_milestone5.gd` verifica dados, detecção, patrulha, mudança de altura, posicionamento, fases dos dois ataques, trajetória travada, alcance vertical, cadência, três minutos **simulados** de IA sem ataque do jogador, câmera, Air Light/Heavy, Ground Light/Heavy/Dash Light, Parry do rasante, Dodge do rasante e do projétil, Air Dash evasivo e ofensivo, dano/expiração do projétil, Ruptura, vulnerabilidade, recuperação, morte, persistência determinística do projétil já disparado, reset e ausência de leitura de input pela IA. O teste rápido passa no Godot 4.7.2 com `--fixed-fps 60`. A execução renderizada foi inspecionada em `PROJECTILE_WINDUP` e `DIVE_WINDUP`: o Corvo e o chão permanecem na câmera do jogador, com telegraphs locais e sem movimento vertical da câmera pelo inimigo.

As regressões dos Milestones 2, 3, 4 e 4.1 **passaram em tempo real**; o teste do Milestone 4 incluiu seus dois minutos de IA. Elas precisam ser executadas em tempo real, pois o `HitStop` mede milissegundos reais. Executá-las com `--fixed-fps` acelera a simulação além do tempo real e causa falsos negativos. A revisão visual do Milestone 1 também **passou** com o verificador atualizado da sala de 2.400×270 px.

O único aviso independente do gameplay observado na inicialização do Godot é a falha do ambiente Windows ao ler a loja de certificados raiz. O verificador encerra o áudio do Parry e aguarda sua liberação antes de sair; a execução final não apresenta vazamento de recursos. O playtest humano ainda é necessário para julgar peso do voo, legibilidade do rasante e espaço de punição. Não foi iniciado mapa real, Status completo, outro inimigo ou loot.
