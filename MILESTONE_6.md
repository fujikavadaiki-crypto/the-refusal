# Milestone 6 — Raiz Faminta

## Escopo e referências

Esta fatia acrescenta somente a Raiz Faminta e `scenes/test/raiz_faminta_arena.tscn`. Abra a arena com **F6** no Godot 4.7.2. `test_room`, `peregrino_arena` e `corvo_arena` permanecem independentes. A Bíblia Canônica e Técnica v3.0 governa regras e números; a Bíblia Visual Oficial v1.0, p. 14, orienta a silhueta baixa, raízes, musgo, face pálida e verdes degradados. Os polígonos atuais são placeholders. Vermelho localizado indica apenas golpes não aparáveis.

## Arquitetura e estados

- `RaizFaminta` é um `CharacterBody2D` responsável por colisão, sinais de dano, apresentação, morte e reset. Enquanto enterrada, a marca no solo permanece visível e a hurtbox continua ativa. O corpo sólido só é ligado depois da recuperação do surgimento, para não empurrar o jogador para fora da hitbox antes do contato.
- `RaizFamintaBrain` decide com distância, altura, linha de visão e posição real. Não lê input. O deslocamento subterrâneo é curto, visível pela marca e limitado a um trecho; no início do preparo, a posição do surgimento fica travada. A perseguição usa baixa velocidade, aceleração e colisão normal.
- `RaizFamintaAttack` gerencia Windup, Active e Recovery de Garra Subterrânea e Mordida, telegraphs locais, `HitContext`, `Hitbox2D` e `HitStop`. O ataque não contém fórmula de dano.
- `RaizFamintaTuning` concentra velocidades, alcance e tempos provisórios. Dois `AttackData` guardam dano canônico e janelas provisórias. `HealthComponent`, `PostureComponent`, `DefenseStats` e `DamageResolver` são compartilhados com os inimigos anteriores.
- `DefenseStats` recebeu dois campos genéricos, com defaults neutros: bônus de vulnerabilidade mágica e multiplicador de Postura recebida de Heavy terrestre. `DamageResolver` aplica ambos. Assim a ficha da Raiz não exige um caminho de dano exclusivo.

Estados: `HIDDEN`, `DETECT`, `BURROW_MOVE`, `EMERGE_WINDUP`, `EMERGE_ATTACK`, `EMERGE_RECOVERY`, `GROUND_CHASE`, `BITE_WINDUP`, `BITE_ACTIVE`, `BITE_RECOVERY`, `HURT`, `RUPTURE`, `DEATH`. `HIDDEN` cumpre também o papel de repouso/idle. Um golpe comum causa reação breve sem reiniciar stun repetidamente. Ruptura interrompe ataque e movimento, mostra o corpo colapsado e adiciona a vulnerabilidade padrão de +20%. Morte prevalece sobre Ruptura no mesmo impacto e interrompe a IA. Morte enterrada expõe o corpo e as raízes.

## Valores CANÔNICOS

| Item | Valor |
|---|---:|
| Raiz Faminta | 85 HP; 35 Postura |
| Garra Subterrânea | 14 HP; 10 Postura; não aparável |
| Mordida | 11 HP; 8 Postura |
| Vulnerabilidade mágica | +15% de dano mágico recebido |
| Heavy contra a Raiz | +25% de dano de Postura recebido; Heavy terrestre de 25 gera aproximadamente 31 |
| Ruptura | aproximadamente 3 s; +20% de dano de HP recebido pela regra geral |
| Air Light / Air Heavy do jogador | 18 HP/7 Postura; 32 HP/28 Postura |
| Heavy terrestre do jogador | 35 HP/25 Postura antes do bônus da Raiz |

**Classificação de Parry:** a Garra Subterrânea é explicitamente não aparável na ficha técnica. A ficha dá à Raiz a identidade geral de ataques não aparáveis, mas não classifica a Mordida individualmente; a Mordida foi marcada **não aparável como decisão PROVISÓRIA DE PLAYTEST**. Seu dano 11/8 é canônico. Os bônus canônicos da Raiz ligados a Raízes (+25%) e Veneno-Praga (+15%) ficam pendentes do sistema de Status. Bote, Varredura de Cipós e Agarre estão descritos na Bíblia, mas não pertencem a esta fatia. Nenhum dano ou classificação da espada foi alterado.

## Valores PROVISÓRIOS DE PLAYTEST

Todos os valores abaixo são ajustáveis. Os defaults estão em `scripts/enemies/raiz_faminta_tuning.gd` e os detalhes das hitboxes em `data/attacks/raiz_*.tres`.

| Grupo | Valores de playtest |
|---|---|
| Percepção e reposicionamento | alcance 130 px, altura 82 px, desligamento 190 px, percepção 0,35 s; enterrada 38 px/s, máximo 85 px e 2,6 s, mínimo 0,45 s, offset do alvo 10 px |
| Perseguição | 42 px/s, aceleração 170 px/s², gravidade 800 px/s², distância de Mordida 24 px, tolerância vertical 25 px, cooldown 0,62 s, reenterramento após 1,4 s fora de alcance |
| Garra Subterrânea | Windup 0,68 s, Active 0,12 s, Recovery 0,62 s, hitbox 20×24 px, HitStop 35 ms |
| Mordida | Windup 0,33 s, Active 0,11 s, Recovery 0,39 s, hitbox 18×10 px com centro 18 px à frente, HitStop 30 ms; classificação não aparável provisória |
| Reações e Postura | Hurt 0,10 s, regeneração após 2 s a 10 pontos/s, restauração de 50% após Ruptura, proteção 0,35 s |

Dimensões do corpo, da hurtbox, da marca e cores também são provisórias. O ataque subterrâneo mantém o corpo sólido desligado durante preparo, contato e recuperação; o dano continua evitável por movimento, pulo, Dodge e Air Dash. A posição final fica comprometida no início do Windup. A Mordida tem alcance físico curto, suficiente para alcançar além da colisão entre os corpos, sem hitbox longa invisível.

## Arena, controles e interação

A arena usa a sala base com chão longo e plataformas provisórias e acrescenta um desnível técnico. O jogador começa próximo da marca enterrada. **A/D** ou setas movem; **Espaço** pula; **J** Light; **K** Heavy; **L** Dodge/Air Dash; **I** Parry; **R** restaura a Raiz e os demais alvos da sala. A etiqueta `RAIZ / HP / POST / ESTADO` é apenas debug.

- O surgimento possui marca no solo, detecção, deslocamento legível e Windup vermelho localizado. Ele não acompanha o jogador depois que o ponto é escolhido.
- Garra e Mordida usam a classificação não aparável. Parry não bloqueia dano; i-frames do Dodge anulam HP e Postura pelo fluxo compartilhado.
- Air Light e Air Heavy atingem a silhueta baixa quando feitos durante a descida. Air Heavy retira 28 de 35 Postura, deixando 7; Heavy terrestre aplica cerca de 31, deixando cerca de 4. Nenhum dos dois rompe sozinho com Postura cheia.
- Durante Ruptura, a Raiz cessa ataques e recebe +20% de dano. Ao recuperar, retoma a perseguição. Reset restaura posição, HP, Postura, facing, timers, hitbox e estado enterrado.

## Validação

`tests/verify_milestone6.gd` verifica valores, estados, sinal subterrâneo, detecção, posição travada, ambos os golpes e suas fases, ausência de hit duplicado, Dodge, Parry, salto/Air Dash evasivo, combo Light, Ground Heavy, Air Light/Heavy, perseguição no chão, Hurt sem stun infinito, Postura, Ruptura, vulnerabilidade, morte comum e enterrada, prioridade da morte e reset por tecla. Inclui três minutos simulados de IA sem ataque do jogador. O verificador passou em modo rápido e em execução de tempo real no Godot 4.7.2. A cena foi executada no Godot 4.7.2 em modo renderizado para inspecionar marca, Windup, corpo emergido, câmera e telegraph.

Regressões: a revisão visual do Milestone 1 passou; os verificadores dos Milestones 2, 3, 4, 4.1 e 5 passaram em tempo real. O único erro de inicialização observado em todos os processos é a falha do ambiente Windows ao ler o armazenamento de certificados raiz. No editor headless, a gravação das preferências em `AppData/Roaming/Godot` também foi impedida pela permissão do ambiente; cenas, scripts e jogo carregaram normalmente, sem erros de script ou debugger.

O playtest humano ainda deve avaliar sensação do peso, clareza do aviso, alcance da Mordida e janela para punir. Os parâmetros não canônicos continuam provisórios. Nenhum mapa oficial, Status completo, loot ou novo arquétipo foi iniciado.
