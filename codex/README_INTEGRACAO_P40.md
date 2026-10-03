# Jogar a integração — Tarefa 4.5 / Peregrino Profanado

Abra **JOGAR_INTEGRACAO.cmd** na raiz desta cópia. Ele inicia o **cemitério/ruínas congelado do P40**, com Peregrino Profanado com arte aprovada, Corvo e Raiz com arte provisória, Carrasco Pequeno A v34A equipado e vida/postura visíveis. O mesmo mapa é a cena inicial de `project.godot`. **F9 alterna entre cemitério e Bosque B**; R reinicia o encontro e renasce depois de morrer. O launcher usa Godot 4.7.2 já instalado e mantém os arquivos de execução em `.godot/` desta cópia.

| Tecla | Ação |
|---|---|
| A/D ou setas | Mover |
| Shift | Caminhar |
| Espaço | Pular; segurar mantém altura completa, soltar cedo corta a subida |
| J | Leve; novas entradas enfileiram o combo 1/2/3 |
| K | Pesado; segure 1 s para carregar, solte para golpear |
| L | Dash no chão/no ar; J/K podem cancelar após 80 ms |
| I | Parry |
| Tab | Alternar humano/Carrasco |
| U / O | Habilidades da máscara |
| P | Tribunal |
| H | Execução de alvo elegível fora do debug; com F3, alterna o grupo de sensação |
| G (com F3) | Ciclar CONTROLE / IMPACTO / MOVIMENTO / CÂMERA |
| R | Reiniciar jogador e três inimigos |
| F3 | Exibir áreas físicas e polígonos ACTIVE do golpe |
| F9 | Alternar cemitério ↔ Bosque B da integração |

Carrasco corre a **4,5 m/s**, dash **3,5 m / 0,35 s**, pulo observado **2,315 m** a 60 Hz. Corpo/hurtbox: raio **7 unidades**, altura **51,111111**, pés Y=13; humano conserva altura 64. Parada física normal; apoio/freio são somente visuais.

Pequeno A desenha em ×1 NEAREST, com pés arredondados para pixels inteiros. A corrida avança a cada 6 px percorridos; o pacote define os quadros e áreas de dano. Uma sombra fica no chão, reduzindo/clareando no ar. Ataques altos dos inimigos podem passar acima do corpo pequeno; isso foi aceito nesta fase.

Fundo 960×540 em ×1 NEAREST; câmera 0,9 com antecipação leve e escala de 32 px/m. Quatro trechos de chão e quatro plataformas iguais ao P40. Pedra, ruína e pilar são alcançáveis do chão; para a coluna, suba no pilar e pule à esquerda. Peregrino nasce no chão, Raiz perto da ruína e Corvo no alto. Sua IA, colisores de locomoção, valores e recursos de ataque foram preservados; a hurtbox do Peregrino agora vem do pacote (raio 7 px, altura 44 px, pés fixos); os responsáveis por apresentação e contato receberam os adaptadores desta fase. O modo antigo segue disponível pelo atributo `small_carrasco_enabled` do apresentador; humano e arquivos de arte antigos foram mantidos.

**Origem da imagem:** o arquivo do P40 coincide byte a byte com `prova/a1_inicio/imagens/A11_quadro_A11_960x540.png`. O arquivo R4 original é diferente. Mantivemos o mapa efetivamente jogado no P40; hashes e distinção em `codex/evidencias_integracao_p40_f4/ORIGEM_MAPA.json`. O PNG não foi retocado; a cobertura local do personagem antigo embutido usa o mesmo atlas do P40.

Os quatro grupos começam **ON**. F3 habilita G/H; o HUD mostra cada grupo e o selecionado. Desligar um grupo remove seus efeitos ao vivo. A tecla H conserva a execução fora desse modo. Corrida, dash, gravidade, impulso e cápsulas aprovados continuam iguais. Pulo completo: 2,3149 m; toque curto: 1,0004 m a 60 Hz.

Todos os ajustes de sensação ficam em **data/config/sensacao.json**. CONTROLE: pulo/coyote 100 ms, ataque/dash 120 ms, pulo variável e dash que cancela recuperação leve. IMPACTO: hitstop 60/90 ms, tremor só no pesado, flash branco de dois quadros, recuo e sangue em pixels. MOVIMENTO: poeira na partida/freio/pouso e deslocamento de 2 px ao pousar, sem escala. CÂMERA: antecipação de 18 px com suavização e saída em pixels inteiros. O fundo acompanha esse deslocamento; o PNG aprovado permanece intacto.

O Peregrino Profanado usa **assets/enemies/peregrino_v1/** nas duas salas: 12 animações, avisos pálidos nos golpes aparáveis e vermelhos na penitência, sombra única e áreas por quadro ATIVO. O corte duplo tem duas partes com quadros e UIDs próprios. F3 mostra a **hurtbox em ciano**, o colisor antigo em rosa no cemitério e a área de ataque em violeta; o rótulo indica animação/quadro/fase. Hurtbox fixa de raio 7 / altura 44 px (7,777778 / 48,888889 unidades), base no mesmo pé. Morte desliga a hurtbox; R restaura o encontro.

Corvo **ave** e Raiz continuam com arte provisória. O pacote humanoide do Corvo pertence à **máscara jogável Corvo** e não foi equipado como inimigo. O pacote falso em **codex/fixtures/inimigo_falso_v1** continua restrito aos testes. Mapas e contrato em **data/enemies/** e **codex/CONTRATO_PACOTE_INIMIGO.md**.

Evidências atuais: **codex/evidencias_integracao_p40_f6/**. Relatório: **codex/RELATORIO_INTEGRACAO_P40_F6.md**. Clipe **CLIPE_PEREGRINO_20s.mp4**, 960×540/30 fps: corrida, salto, dash, parries, leve, pesado, ruptura e morte, IA/dano reais e quatro grupos ON. Entradas programadas; jogador posicionado uma vez no início; hitstop virtual de 60 Hz somente na exportação. Fotos F3 dos cinco ataques incluem ambas as partes do corte duplo; os avisos e as poses de ruptura/morte também foram capturados em ×1. As fotos isolam o ator e acionam ataques/callbacks originais; são distintas do combate livre do clipe.

O backup da fase anterior e a entrega desta fase são enviados **somente a feature/integracao-p40**. Main e checkout original continuam preservados; sem merge.

## Reproduzir nesta cópia

`python codex/verificar_fase6.py after` executa as **24 suítes** existentes; `python codex/verificar_fase6.py new` executa as **204 verificações** do pacote real. Suites do Bosque continuam abrindo o Bosque. Logs e medidas são redirecionados para F6, preservando as evidências antigas. Duas falhas preexistentes de arte legada permanecem registradas.

`python codex/capturar_fase6.py photos` recria os prints; `python codex/capturar_fase6.py capture` exporta os 600 quadros; `python codex/capturar_fase6.py encode` gera o MP4. Quadros temporários em `.godot/p40_runtime_f6/capture_frames`. O ZIP aprovado e suas 160 cópias são conferidos por SHA256; o original permanece só leitura. Não sobrescrever `PRESERVACAO_antes.json` da entrega.
