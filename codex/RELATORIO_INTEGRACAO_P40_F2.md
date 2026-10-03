# Tarefa 4.1 — integração, fase 2

Passos **4–5** na cópia `The Refusal/integracao-p40`, branch `feature/integracao-p40`, sobre F1 aprovada (`c8794f7`). Referência P42b/v34A só leitura. Corpo pequeno **só no Carrasco**; humano conserva corpo/hurtbox/pivô. Pulo P40 vale para ambas as formas. Passos 6–13 pendentes.

| Parâmetro | Resultado |
|---|---|
| Escala fixa | 32 px/m; 0,9 de referência; **35,555556 unidades/m**, independente da câmera |
| Gravidade / impulso | **1481,130835 unidades/s² / −481,367521 unidades/s**; fórmulas P40, H nominal 2,20 m / T nominal 325 ms |
| Pulo medido a 60 Hz, ambas as formas | **82,307673 unidades = 74,076906 px = 2,314903 m**; ápice **20 ticks / 333,333 ms**; pouso 41 ticks / 683,333 ms |
| Coyote / buffer | **100 / 120 ms**, código atual preservado; sem adicionar corte variável |
| Corpo e hurtbox Carrasco | Raio **7/0,9 = 7,777778**, altura total **46/0,9 = 51,111111** unidades; centro **(0; −12,555556)**; raio 0,21875 m / altura 1,4375 m |
| Pés / pivô Carrasco | Pés locais **(0;13)**; pivô Y **−16,866667**, X espelhado original ±5; diretamente da referência, sem segunda redução por tamanho |
| Humano | Raio **7**, altura **64**, centro **(0;−19)**, pivô Y **−2** unidades, preservados |

Override vertical **−380 removido**. Medição difere da evidência salva P42b (2,316052 m) em **1,15 mm**; mesmas fórmulas/ordem de integração, sem recalibrar para 2,20 m. Controlador/colisores reais, delta 1/60 s; trace em `MEDIDAS_depois.json`.

Trocas preservam pés e restauram cápsulas independentes. Se a nova forma não cabe, troca recusada sem cooldown/consumo de ultimate. `equip/setup` pressupõem spawn válido. Consulta com inset **0,01 unidade** distingue tangência de penetração.

**Geometria:** três spawns sem penetração. Carrasco passa sob teto **55 unidades / 1,546875 m**, humano é barrado; pulo respeita o teto. O corpo pequeno é mais baixo, mas mais largo: **15,555556** contra **14** unidades. No vão **15 / 0,421875 m**, humano cabe; trocar para Carrasco é recusado.

**Testes:** antes **17/20 suítes aprovadas**; depois **16/20**, incluindo F1 (**228/228**). Suíte nova **85/85**: pulo/coyote/buffer, trocas, spawn, teto/vão e contato. Godot 4.7.2, headless normal, 60 Hz; evidências da referência não contadas como execução.

Três falhas anteriores: GIF/Sprite nulo, milestone8_2/propriedade `sprite` ausente, vertical/alinhamento visual antigo. Expectativas atualizadas: pulo F1 e cápsula milestone8_3. Fixture M4.1 começa mais alto para observar 28 ticks no ar; antes pousava/recarregava corretamente. Roteiro vertical usa o ápice novo: **três travessias, zero quedas, saída alcançada**. Comando antigo aos 500 ms congelava a descida contra Ground3; cenário/física intactos. Logs iniciais e retestes preservados.

**Regressão para avaliação:** M5 tem **cinco checks novos falhando**, derivados de dois ataques aéreos imediatos que passam acima do Corvo. Fixture humana: alvo 30 unidades à frente, Y=175; antigo causa 18/32 HP, P40 **0/0**, sem contatos/Ruptura. Centro do leve durante ACTIVE fica **23,43–31,05 unidades acima** do Corvo (0,659–0,873 m); pesado **19,84–65,41** (0,558–1,840 m). IA/voo/armas/dano/alvo intactos. Perseguição, rasante, projétil, parry, dash e recuperação real continuam passando.

**Corpo menor:** **130 casos antes/depois**, ambas as formas, ACTIVE/Hurtbox/Health reais, projéteis em voo. Origens imóveis isolam geometria; suítes completas exercitam IA. Distâncias 10/25/40/55, elevações 0/28/44 unidades. Sete contatos deixam de ocorrer no Carrasco; nenhum acerto novo observado. Humano igual.

| Contato que passa acima após reduzir altura | Distância horizontal | Altura/elevação |
|---|---|---|
| Peregrino, Estocada | 10 / 25 / 40 unidades (0,28125 / 0,703125 / 1,125 m) | Inimigo elevado **44 unidades / 1,2375 m** frente à posição alinhada pelos pés |
| Raiz, Garra | 10 unidades (0,28125 m) | Mesma elevação 44 |
| Raiz, Mordida | 10 / 25 unidades (0,28125 / 0,703125 m) | Mesma elevação 44 |
| Corvo, projétil horizontal 8×8 | Lançado a 40 unidades (1,125 m) | Centro **58 unidades / 1,63125 m acima dos pés**; atinge humano, passa acima do Carrasco |

Contatos baixos de Peregrino/Raiz/rasante permanecem; projéteis a 4/20/40 unidades dos pés acertam ambas as formas. Diferenças ficam para decisão. **Nenhuma IA, tuning de inimigo ou recurso de ataque alterado.**

**Preservação SHA256:** 1.583 arquivos da referência P42b e 771 do checkout original intactos, mesmo HEAD/status original e mesmo `main`. Manifesto v34A: `0a61e24f68a2d5ed2ebbdfc666c504d2851fa8f66316cae5d9c8f33c114d9a64`. Auditoria exclui caches `.godot` e metadados Git; evidências F1 preservadas. Sem push/merge.

Evidências em `evidencias_integracao_p40_f2/`: comparação, suítes antes/depois/inicial, logs, medidas por tick, diagnósticos Corvo/travessia e SHA256. Executor `verificar_fase2.py`; baseline exige uma cópia separada da revisão F1 sem alterações.

Entrega parada para avaliação da fase 2, incluindo a diferença dos ataques aéreos contra o Corvo.
