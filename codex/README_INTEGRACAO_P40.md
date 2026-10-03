# Jogar a integração — Tarefa 4.4 / Sensação e pacotes de inimigo

Abra **JOGAR_INTEGRACAO.cmd** na raiz desta cópia. Ele inicia o **cemitério/ruínas congelado do P40**, com Peregrino, Corvo e Raiz originais, Carrasco Pequeno A v34A equipado e vida/postura visíveis. O mesmo mapa é a cena inicial de `project.godot`. **F9 alterna entre cemitério e Bosque B**; R reinicia o encontro e renasce depois de morrer. O launcher usa Godot 4.7.2 já instalado e mantém os arquivos de execução em `.godot/` desta cópia.

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

Fundo 960×540 em ×1 NEAREST; câmera 0,9 com antecipação leve e escala de 32 px/m. Quatro trechos de chão e quatro plataformas iguais ao P40. Pedra, ruína e pilar são alcançáveis do chão; para a coluna, suba no pilar e pule à esquerda. Peregrino nasce no chão, Raiz perto da ruína e Corvo no alto. Sua IA, cenas, valores e recursos de ataque foram preservados; os responsáveis por apresentação e contato receberam os adaptadores desta fase. O modo antigo segue disponível pelo atributo `small_carrasco_enabled` do apresentador; humano e arquivos de arte antigos foram mantidos.

**Origem da imagem:** o arquivo do P40 coincide byte a byte com `prova/a1_inicio/imagens/A11_quadro_A11_960x540.png`. O arquivo R4 original é diferente. Mantivemos o mapa efetivamente jogado no P40; hashes e distinção em `codex/evidencias_integracao_p40_f4/ORIGEM_MAPA.json`. O PNG não foi retocado; a cobertura local do personagem antigo embutido usa o mesmo atlas do P40.

Os quatro grupos começam **ON**. F3 habilita G/H; o HUD mostra cada grupo e o selecionado. Desligar um grupo remove seus efeitos ao vivo. A tecla H conserva a execução fora desse modo. Corrida, dash, gravidade, impulso e cápsulas aprovados continuam iguais. Pulo completo: 2,3149 m; toque curto: 1,0004 m a 60 Hz.

Todos os ajustes de sensação ficam em **data/config/sensacao.json**. CONTROLE: pulo/coyote 100 ms, ataque/dash 120 ms, pulo variável e dash que cancela recuperação leve. IMPACTO: hitstop 60/90 ms, tremor só no pesado, flash branco de dois quadros, recuo e sangue em pixels. MOVIMENTO: poeira na partida/freio/pouso e deslocamento de 2 px ao pousar, sem escala. CÂMERA: antecipação de 18 px com suavização e saída em pixels inteiros. O fundo acompanha esse deslocamento; o PNG aprovado permanece intacto.

Os inimigos continuam com sua arte provisória até receberem pacotes válidos. Os mapas ficam em **data/enemies/*_mapa.json**. O contrato e os caminhos de entrega estão em **codex/CONTRATO_PACOTE_INIMIGO.md**. O pacote **codex/fixtures/inimigo_falso_v1** serve somente aos testes, nunca é equipado na sala normal.

Evidências da fase atual: **codex/evidencias_integracao_p40_f5/**. Relatório: **codex/RELATORIO_INTEGRACAO_P40_F5.md**. Clipe: **CLIPE_SENSACAO_20s.mp4**, 960×540, 30 fps, quatro grupos ON, entradas programadas e combate real. Jogador reposicionado entre três encontros; hitstop exportado em relógio de 60 Hz. As capturas PNG mostram corrida, pulo, dash aéreo e impactos.

O backup da fase anterior e a entrega desta fase são enviados **somente a feature/integracao-p40**. Main e checkout original continuam preservados; sem merge.

## Reproduzir nesta cópia

`python codex/verificar_fase5.py after` executa as 23 suítes completas; `python codex/verificar_fase5.py new` executa a suíte nova. As suítes do Bosque continuam abrindo o Bosque. Os runners redirecionam medidas para a pasta desta fase, preservando relatórios e evidências anteriores. Duas incompatibilidades antigas de arte permanecem registradas, sem impedir a cena atual.

`python codex/capturar_fase5.py capture` exporta 600 quadros nativos; `python codex/capturar_fase5.py encode` monta o MP4 com o FFmpeg já disponível. O cache de quadros fica em `.godot/p40_runtime_f5/capture_frames` e pode ser recriado. A conferência SHA256 é feita com `preserve-before`/`preserve-after`; não sobrescrever a linha de base entregue. Ferramentas e execução ficam nesta cópia.
