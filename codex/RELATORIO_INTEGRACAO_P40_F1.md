# Tarefa 4.0 — integração, fase 1

Executados somente os passos 1–3: linha de base, corrida/caminhada e dash. Branch local `feature/integracao-p40`, criada de `main@ef24b5561cacb823d1f719370c29d82522cb5b58`, na cópia `C:/Users/daiki/Documents/Codex/The Refusal/integracao-p40`. O checkout original estava em outro branch, com alterações locais, e foi preservado. Sem push ou merge.

Referência inicial: `carrasco_25d_test/jogavel/prototipo_40`, então P41/ex-40, **Pequeno A v32A**. Durante a tarefa, essa pasta recebeu externamente P42/v33A. Os valores físicos e a cápsula do pequeno continuaram iguais; o plano identifica também o pacote atual e suas mudanças de apresentação. Arte, cápsula, pivô, corrida por distância, sensação e combate novos permanecem nas etapas posteriores.

## Valores aplicados

Escala fixa de referência: 32 px/m com zoom 0,9; 35,555556 unidades de mundo/m. A física não varia com o zoom da sala.

| Item | Resultado |
|---|---|
| Corrida Carrasco / caminhada | 160 / 88 unidades/s = **4,5 / 2,475 m/s** |
| Corrida humana / caminhada | 173,913043 / 95,652174 unidades/s = **4,891304 / 2,690217 m/s** |
| Máscara | Multiplicador **0,92** preservado; base capturada antes de equipar/trocar |
| Aceleração solo / freio / ar | 1304,347826 / 1594,202899 / 942,028986 unidades/s²; proporção preserva os tempos anteriores |
| Dash chão e ar | **3,5 m / 0,35 s**, velocidade absoluta 355,555556 unidades/s |
| Invulnerabilidade | **[61,25; 218,75) ms**, início inclusivo/fim exclusivo |
| Cancelamento / cooldown | 80 / 280 ms, preservados; momentum chão 45%, ar leve 65%, ar pesado 40% |

O dash recebe um alvo horizontal absoluto na locomoção, sem divisão pela corrida. Mantém velocidade com ambas as formas, Shift e até corrida zerada na fixture. Conserva direção, colisões, carga aérea, cancelamento e ordem de atualização.

Pulo atual do principal **intacto**: gravidade 800, impulso −260, coyote 100 ms, buffer 120 ms e override vertical −380. O pulo escolhido da referência, medido em **2,316052 m (~2,32 m)**, está registrado para o passo 4; não foi integrado junto aos passos 1–3.

## Testes

Godot 4.7.2, execução headless normal, física a 60 Hz. Sem aceleração por `--fixed-fps`: o hitstop usa tempo real. O executor permite 600 s aos testes que contêm vários minutos de simulação; erro fatal de script encerra a suíte após registrar a causa.

Baseline: **16/19 suítes passaram**. Falhas preexistentes, mantidas:

- `verify_carrasco_gif_test.gd`: procura `Sprite` e acessa `texture_filter` em uma instância nula; contrato visual antigo.
- `verify_milestone8_2.gd`: procura propriedade `sprite` inexistente no apresentador atual. A expectativa antiga de cápsula com 26 px também diverge dos 64 atuais, mas nem chega a ser executada.
- `verify_vertical_slice.gd`: falha “Carrasco aprovado nasce sobre o piso pintado”; alinhamento visual anterior à integração.

Resultado final: **16/19 suítes passaram, mesmas três falhas preexistentes, nenhuma nova falha**. As 16 incluem combate/parry, máscaras/execução, Peregrino/Corvo/Raiz, encontros combinados e travessias do Bosque. A suíte adicional passou em **228/228 verificações**: movimento medido, trocas sem acumulação, dash solo/ar nas duas direções/formas, Shift, corrida zero/80/500, colisões, carga aérea e fronteiras de i-frame/cancelamento.

Medições: corrida humana 173,913078 e Carrasco 159,999695 unidades/s; caminhada 95,651007 e 88,000507. Nos 16 casos de dash, duração 0,35 s e distância 124,081863–124,182777 unidades (**3,489802–3,492641 m**), contra 124,444444/3,5 m nominais. A diferença de 0,26–0,36 unidade vem do tick final já sujeito à locomoção normal, conforme a ordem preservada do principal; está abaixo de um passo de física.

Expectativas modificadas somente para os valores escolhidos: duração/i-frames do dash e velocidade Carrasco. As fixtures de contato imóvel em milestone4/4.1 agora zeram explicitamente `dash_speed` e o restauram no reset; corrida zero deixou de congelar dash. As verificações de dano, postura, parry, cancelamento, carga aérea e colisão continuam exigidas.

Duas verificações falharam na primeira rodada posterior por timing antigo dos testes e foram corrigidas no cenário de teste, sem alterar o jogo: a Mordida atingia após o novo fim do i-frame; sua fixture agora aciona a esquiva com 80 ms restantes de preparação. Na segunda travessia vertical, o roteiro acionava dash com os pés 14,834 unidades abaixo da plataforma e congelava a subida; o espaçamento salto→dash agora acompanha a velocidade, preservando a demora anterior. Retestes completos confirmaram Mordida e três travessias/zero quedas; o erro de alinhamento inicial continua registrado. Logs iniciais, retestes e trace do diagnóstico foram mantidos.

Logs e resumos: [comparação final](evidencias_integracao_p40_f1/COMPARACAO_TESTES.json), [medições dirigidas](evidencias_integracao_p40_f1/INTEGRACAO_P40_F1.json) e [diagnóstico de travessia](evidencias_integracao_p40_f1/DIAGNOSTICO_TRAVESSIA_RESUMO.json). Suíte adicional: [verify_integracao_p40_f1.gd](testes/verify_integracao_p40_f1.gd). Executor: [verificar_fase1.py](verificar_fase1.py); ações `import`, `before`, `after`, `preserve-before` e `preserve-after`. O `before` exige fontes de produção ainda sem alterações. Os checks salvos na referência não são contados como testes desta integração.

## Preservação

SHA256 antes/depois, excluindo caches `.godot` e metadados Git: **771 arquivos do checkout original intactos**, mesmo HEAD, mesmas alterações locais e mesmo `main`. O pacote inicial v32A ficou intacto. A referência completa divergiu por atualização externa P42: seis arquivos modificados, 235 adicionados, nenhum removido; essa divergência está explicitada em [PRESERVACAO_resultado.json](evidencias_integracao_p40_f1/PRESERVACAO_resultado.json). Nenhum comando desta integração escreveu na referência. Cinco recursos LFS foram materializados somente na cópia a partir do cache local, com SHA256 idêntico aos objetos de `main`; nenhuma transferência de rede.

Entrega limitada à fase 1, para avaliação antes de qualquer etapa seguinte.
