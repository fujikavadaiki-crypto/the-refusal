# Tarefa 4.3 — sala inicial do cemitério

Entrega local em **feature/integracao-p40**, cópia `integracao-p40`. A cena inicial e `JOGAR_INTEGRACAO.cmd` abrem `scenes/biomes/cemiterio/sala_cemiterio.tscn`. **F9 alterna cemitério/Bosque B**, com a cena derivada da F3; nenhum arquivo de cenário/script do Bosque foi modificado. **R reinicia e renasce; F3 mostra chão, plataformas, corpos e polígonos ACTIVE.** Demais teclas em `README_INTEGRACAO_P40.md`. Sem push/merge.

## Fundo e geometria

Foi mantido exatamente o fundo congelado usado no P40. A conferência encontrou uma divergência no nome pedido: esse PNG coincide **byte a byte com A1.1**, não com o R4 original da pasta `entrega_r4`. A diferença foi apresentada ao usuário; preservamos o mapa efetivamente jogado nos protótipos. **Não afirmamos igualdade com o R4.**

- P40, prova A1.1 e cópia integrada: SHA256 **`56bf78665821823c8d36f881aafa4e34a35c0ef6a85f43c709aa231aafae32a8`**.
- R4 original: SHA256 `135521653ee35e890133eabc1ae975bc660a381a1634dd612aa49fb8cd314dc7`; os pixels também diferem, além dos metadados.

Fundo **960×540, ×1 NEAREST**, câmera fixa **0,9**, escala **32 px/m**. Mesmos quatro `GROUND_TOPS`, quatro plataformas (pedra, ruína, coluna, pilar), espessura 2 px e colisão unidirecional da referência. O PNG está intacto; a cobertura atlas do Carrasco antigo embutido é a mesma do P40. `ORIGEM_MAPA.json` registra a conferência completa.

A sala e a câmera recebem juntas uma translação mundial **Y=−150**. Isso conserva cada coordenada projetada e permite ao Corvo usar seus limites absolutos originais **92–186**, sem editar IA/tuning. Peregrino nasce no chão em x=340 px, Raiz perto da ruína em x=620 px, Corvo no alto em x=745 px. Nenhum nasce interpenetrando: folga nos pés de Peregrino/Raiz **0,05/0,314 unidades**; Corvo começa **67,05 unidades acima do chão**, descontado seu raio.

## Verificação

| Resultado | Antes | Depois |
|---|---:|---:|
| Suítes completas, incluindo F1/F2/F3 | 20/22 | 20/22 |
| Verificações aprovadas nessas suítes | 1.676 | 1.676 |
| Suíte nova da sala | — | **119/119** |
| Falhas novas | — | **0** |

Continuam os dois erros preexistentes da arte antiga: `verify_carrasco_gif_test` acessa `texture_filter` de sprite nulo; `verify_milestone8_2` acessa uma propriedade `sprite` ausente no apresentador antigo. Os testes específicos do Bosque continuam carregando explicitamente o Bosque. Fixtures anteriores e evidências das outras fases foram preservadas; somente o destino das medidas foi redirecionado em cópias temporárias.

Rotas com locomoção/colisão de produção a **60 Hz**, sem dash: chão→pedra **28 ticks**, chão→ruína **36**, chão→pilar **29**, pilar→coluna **38**. A coluna é acessível pelo pilar; não prometemos salto direto do chão à coluna. O pulo em piso plano continua **2,314903 m**, ápice **20 ticks**; a medição de subida na rampa da pedra varia até **0,581 px**, sem mudar gravidade/impulso. Corrida **4,5 m/s**, dash **3,5 m/350 ms**, cápsula/pivô, apresentador, sombra, rastro e dano por quadro da F3 preservados.

## Leitura e captura

Carrasco idle: **48 px de altura**; Peregrino **29,7 px**, Corvo **28,8 px**, Raiz emergida **26,1 px**. O vermelho e a silhueta do Carrasco dão boa leitura sobre o fundo. Peregrino e Raiz têm contraste menor com terra/vegetação, sobretudo enterrada a Raiz; Corvo se distingue pelas asas e movimento. Inimigos ainda usam suas silhuetas provisórias originais, menores que o Carrasco. Nenhuma correção de arte, escala, IA ou dano foi feita neles.

`capturas/` contém prints normais, pulo, dash aéreo, F3 e golpes reais contra cada inimigo. **CLIPE_CEMITERIO_PEQUENO_A_30s.mp4**: 960×540, **900 quadros/30 fps**, sem áudio, decodificação completa aprovada. Entradas programadas em três encontros; jogador reposicionado entre eles, relógio virtual de hitstop só na exportação. IA e dano reais: **7 acertos, morte dos três inimigos, 44 de dano recebido**, rastro até 3 imagens. Captura renderizada e ensaio sem janela produziram os mesmos resultados.

SHA256 antes/depois: **1.583 arquivos do P40, 1.550 de prova/, 770 do checkout original, 48 arquivos de cenas/scripts do Bosque, 32 cenas/scripts de inimigos, 3 tunings, 29 ataques e 407 arquivos do pacote integrado** preservados. Caches `.godot`, `.git` e `__pycache__` excluídos; `main`, HEAD e alterações preexistentes do original intactos. Evidências em `evidencias_integracao_p40_f4/`. **Parar para avaliação.**
