# Tarefa 4.2 — Integração, fase 3

Entregues **passos 6–8 e 10**, na cópia `integracao-p40`, branch `feature/integracao-p40`. Pequeno A v34A/P42b é padrão do Carrasco; humano e arte antiga preservados. Nenhum push/merge ou alteração do `main`, checkout original ou referência.

## Resultado

- Pacote copiado com **215 arquivos idênticos por SHA256**. Leitor do manifesto `animacoes[]`, 26 animações, hashes dos PNG brutos ou removendo exclusivamente `caBX`, dimensões, âncoras, sombras e FX com fase. 190 PNGs são referenciados; a prancha restante foi preservada.
- Arte **×1 NEAREST**, pés em pixel inteiro; somente o sprite faz `flip_h`, independente do espelhamento legado do pai. Corrida: **6 px/quadro**, oito quadros e apoios 1/5. Parada física medida: **7 ticks / 0,116667 s**, 6,700485 unidades de frenagem; apoio/freio apenas visuais.
- Uma sombra projetada no colisor do chão; personagens abaixo são excluídos da busca. No ar, tamanho/opacidade chegam a 50% em 2,20 m; sem chão, ocultada. Sombra antiga volta com o humano. Rastro P42b: 110/80 ms, máximo 3/2 cópias, intervalo 40 ms.
- Oito golpes usam polígonos/retângulos do quadro **ACTIVE**, recortados à frente, decompostos e consultados após o movimento do tick. Arte/dano compartilham quadro; um contato por alvo/ação. Hurt/interrupção e recuperação suprimem dano. Habilidades sem dados mantêm o pivô/fallback. Habilidades/execução/Tribunal sem arte própria usam idle visual, preservando runtime/sinais/efeitos.

Física mantida: Carrasco **4,5 m/s**, humano mais rápido pelo multiplicador 0,92; dash **3,5 m/0,35 s**; pulo medido **2,314903 m**, ápice **20 ticks/0,333333 s**. Decisão aprovada aplicada: raio Carrasco **7 unidades**, altura **51,111111**, pés Y=13 e pivô Y=−16,866667. Corpo/hurtbox iguais; transformação no vão de 15 unidades passa. Humano mantém altura 64.

## Testes

Godot 4.7.2, física 60 Hz; suites normais usam hitstop real, sem aceleração artificial do relógio.

| Execução | Suítes aprovadas | Checks PASS registrados |
|---|---:|---:|
| Antes | 16/21 | 874 |
| Depois | **19/21** | **881** |
| Suíte F3 nova | **1/1** | **795**, zero falhas |

Restam duas incompatibilidades **preexistentes** dos testes de arte arquivada: GIF acessa `texture_filter` em sprite nulo; M8.2 espera propriedade `sprite` inexistente no apresentador oficial antigo. Esses testes continuam examinando o modo antigo. Nenhuma falha nova nas suítes completas.

M5: alvo e IA iguais, contato na descida. Leve espera a descida; pesado antecipa entrada em dois ticks no limite do ápice, considerando preparo de 250 ms e consumo do input no tick seguinte. A suíte completa passa **50 checks**. Diagnóstico registra velocidade positiva no contato. Mantida a nota **“reavaliar após dano por quadro”** para a fixture humana/fallback. A falha intermitente inicial do M6 (`mordida entra em recuperação`) não se repetiu: depois, 51 checks passaram. Vertical slice revisa apenas a expectativa de apresentador substituído e passa os 13 checks.

## Bosque, escala e captura

[JOGAR_INTEGRACAO.cmd](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/JOGAR_INTEGRACAO.cmd>) abre uma cena derivada do Bosque aprovado com os **três inimigos originais**, sem retocar cenário/colisores/IA. [README com teclas](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/codex/README_INTEGRACAO_P40.md>). R reinicia vida/postura/estado do jogador e inimigos; F3 mostra as áreas ACTIVE.

Medições no zoom 0,9, sem FX/labels, em pixels de tela:

| Silhueta | Largura × altura |
|---|---:|
| Carrasco idle, pixels opacos | **52 × 48** |
| Peregrino provisório | 14,4 × 29,7 |
| Corvo, incluindo asas | 49,5 × 28,8 |
| Raiz, geometria quando emergida | 45,9 × 26,1 |

O Carrasco ocupa **8,9% da altura da janela 960×540**. Fica pequeno diante das árvores/ruínas do Bosque, mas **1,62–1,84 vezes mais alto que os inimigos provisórios**. Sua arte em pixels tem contraste/estilo mais marcado que o fundo pintado. Comparações lado a lado foram capturadas; essa diferença de escala não foi compensada alterando inimigos ou cenário.

[Clipe de 30 s](<C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40/codex/evidencias_integracao_p40_f3/CLIPE_BOSQUE_PEQUENO_A_30s.mp4>): viewport real, **900 quadros / 30 fps / 960×540**, sem áudio. Inputs programados, IA e danos reais; jogador reposicionado entre três encontros de 10 s. **Seis acertos, mortes dos três inimigos, 22 HP recebidos**, máximo três fantasmas. Inclui corrida, pulo/dash aéreo, pesado/aéreo/leve, hurt e trechos com áreas F3. A exportação usa hitstop em relógio virtual de 60 Hz; o jogo e testes completos mantêm o relógio real. Primeira exportação divergente foi descartada; a final isola os inputs programados da entrada ao vivo. PNGs sem compressão de vídeo, trace, inputs e metadados preservados em `evidencias_integracao_p40_f3/`.

## Limites e preservação

Ataques altos que passam acima do pequeno permanecem **aceitos por ora**. Plano registra a etapa futura **balanceamento de inimigos**, mirando no centro da hurtbox, sem mudar IA agora. Revisão de câmera/salas segue no passo 12: em salas com zoom 1, arte conserva ×1, mas área física usa a escala fixa 0,9 e projeta **11,11% maior** que a arte; no Bosque 0,9 elas coincidem. A diferença foi medida; não recalibrar física por câmera nesta fase.

Auditoria antes/depois: **1.583 arquivos da referência e 771 do checkout original intactos**, `main`, HEAD e status original preservados; os 215 arquivos do pacote copiado conferem. Fontes de IA, tuning, ataques, cenas dos inimigos e `project.godot` iguais à fase 2. Evidências completas e SHA256 da mídia: `COMPARACAO.json`, `PRESERVACAO_*.json`, `PACOTE_SHA256.json` e `MIDIA_SHA256.json`. Entrega pronta para avaliação; fases seguintes aguardam decisão.
