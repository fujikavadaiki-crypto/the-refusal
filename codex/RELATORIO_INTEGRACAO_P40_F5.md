# Tarefa 4.4 — sensação e preparo para inimigos novos

Entrega na mesma cópia `integracao-p40`, branch `feature/integracao-p40`. O backup inicial foi enviado somente desse branch e confirmado no remoto em **68807ee8bbcada0bfd3e6dec59b6da7e99661181**. Main permanece **ef24b5561cacb823d1f719370c29d82522cb5b58**. Commit/push final também restritos ao branch da integração, sem merge.

## O que mudou

Quatro grupos começam ON; **F3 habilita G/H** para escolher/alternar, com estado no HUD. H continua execução fora do debug. Valores de sensação centralizados em `data/config/sensacao.json`.

| Grupo | Valores e comportamento |
|---|---|
| Controle | Pulo/coyote 100 ms; ataque/dash 120 ms; soltar corta subida; dash cancela recuperação leve, preservando compromisso do pesado e janela ofensiva do dash. Reset/renascimento descartam pedidos pendentes. |
| Impacto | Hitstop existente unificado em 60/90 ms; parry conserva 80 ms. Tremor somente no pesado: 3 px/110 ms. Flash branco de dois quadros. Recuo 1,1/2,1 m/s, atrito 12 m/s², limite 0,5 m; 12 pixels de sangue por impacto, 280 ms, paleta P40. |
| Movimento | Oito partículas de poeira por partida/freio/pouso, 220 ms. Pouso desloca sprite em 2 px/80 ms, sem escala. |
| Câmera | Antecipação 18 px, suavização 8/s, saída em pixels inteiros. Fundo/colisores acompanham a mesma vista; margens espelhadas cobrem o deslocamento sem editar o PNG. |

Sangue/poeira são retângulos de 2 px, com limite comum de 192 partículas; acompanham o mundo e recebem arredondamento ao desenhar. Flash, recuo e sangue pertencem ao alvo; hitstop/câmera mantêm um único responsável. Efeitos antigos redundantes de golpe foram retirados do caminho novo; sinais de postura/execução permanecem.

**Física preservada:** Carrasco 4,5 m/s, humano mais rápido pelo fator da máscara, dash 3,5 m/0,35 s, g/v0 e cápsulas/pivô aprovados. A 60 Hz: pulo segurado **2,314903 m**, ápice 20 ticks, voo 41; toque curto **1,000400 m**, ápice 13 ticks, voo 26. O buffer de pulo histórico de 120 ms é substituído pelos 100 ms solicitados nesta fase.

## Leitor de inimigo

Leitor genérico aceita `animacoes[]/quadros[]`, ms, PNG/hash, âncora, sombra, FX por fase e retângulos/polígonos ACTIVE. Reutiliza as regras de validação/recorte do Carrasco. Mapas separados traduzem IA/IDs de ataque; os tempos originais da IA e `.tres` prevalecem. Dano por quadro é consultado após movimento resolvido, conserva o UID e limpa ao interromper. F3 mostra suas peças. Sem pacote/área válidos, mantém apresentação/contato nativos, inclusive Raiz enterrada.

Corvo admite animação dedicada do projétil, com âncora e área próprias; não transfere caixas do bico para a bala. Sem esse dado, conserva o projétil original. O **pacote FALSO mínimo** é usado somente pela suíte, nunca equipado na sala normal. Pacotes finais de Peregrino/Corvo ainda pendentes; contrato em `CONTRATO_PACOTE_INIMIGO.md`.

## Validação e preservação

- **Antes/depois: 21/23 suítes aprovadas**, 1795 mensagens PASS em cada execução. Mesmas duas falhas preexistentes: `verify_carrasco_gif_test` acessa sprite nulo; `verify_milestone8_2` espera a propriedade legada `sprite`. Não foram corrigidas nesta fase.
- **Suíte nova: 70 PASS, zero falhas.** Pulo/coyote/buffers e expiração, cancelamento leve/pesado, liga/desliga, hitstop/flash/recuo/paletas, câmera/pouso, pacote falso, espelho/sombra/FX/áreas, deduplicação e projétil; rejeição de manifesto inválido.
- Fixtures passaram a segurar o pulo quando pedem altura máxima, esperar a janela real do combo após hitstop e conferir o offset atual da câmera. Resets descartam a entrada artificial antiga. Terreno/IA/dano não foram ajustados para obter passes. Primeira execução e logs de revisão preservados.
- SHA256: P40 **1583 arquivos**, prova **1550**, checkout original **770**, Bosque **48**, cenas de inimigos **4**, IA/tuning de scripts **12**, recursos de ataques **29** e Pequeno A **407** intactos. Os três JSON de mapeamento são adições autorizadas; os três `.tres` de tuning continuam iguais. Main e estado local do checkout original preservados.

**Clipe final:** `evidencias_integracao_p40_f5/CLIPE_SENSACAO_20s.mp4`, 960×540/30 fps, 600 quadros decodificados integralmente. Grupos ON; seis acertos reais, dois em cada inimigo, três mortes, 22 HP recebidos; 22 emissões de poeira e oito de sangue. Corrida/pulo/dash aéreo/pesado/impacto em PNG. Entradas programadas, jogador reposicionado entre três encontros; hitstop virtual de 60 Hz somente na exportação. Leitura mantém o pequeno no fundo aprovado, flash/pixels breves e corpo dos inimigos com arte provisória. Revisão geral R4 e balanceamento de inimigos continuam futuros.

README e launcher existentes apontam para esta sala. Evidências desta fase em `evidencias_integracao_p40_f5/`. Entrega encerrada para avaliação.
