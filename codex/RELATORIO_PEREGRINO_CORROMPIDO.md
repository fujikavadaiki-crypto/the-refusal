# Tarefa 4.7 — Peregrino Corrompido

Equipado no cemitério e no Bosque (F9), em `assets/enemies/peregrino_corrompido_v1/`. Mestre v2 de **52 px** limpo, rosto clareado em osso, musgo agrupado e contorno contínuo. Fontes originais preservadas. Rig com corpo, capuz/cabeça, braços/cajado, pernas e manto/musgo; pivôs e poses registrados, tronco completado sob as peças. Deslocamentos inteiros, variantes desenhadas para poses extremas, sem escala do corpo. Manto/musgo e sinos acompanham o quadro anterior.

**12 animações, 89 quadros (63 corpos distintos)**; GIFs ×4, foto ×1 ao lado do Carrasco, seis prints F3 dos cinco ataques (duplo em duas partes), avisos, ruptura/morte e clipe de 20 s. Marcha por distância: **4 px/quadro**, com pernas alternando; tempo parado não avança a marcha. O leitor mantém a cadência temporal nos pacotes sem esse campo.

## Combate e leitura

Cajado/sinos substituem a lâmina; penitência crava o cajado e avisa em vermelho, demais golpes em pálido. FX de arco em três faixas/filete, separados do corpo e da sombra. Áreas somente ACTIVE/à frente: arco, segmento do cajado e região próxima do braço. **Tempos dos seis `.tres`, parry, dano, vida, postura, IA e colisor de locomoção intactos.**

Hurtbox raio **7 / altura 48 px**, excluindo galhos/arma: 7,777778 / 53,333333 unidades, centro Y=−11,166667 e pés Y=15,5. Cresce 4 px (0,125 m) sobre a anterior de 44; sonda a 47 px agora acerta, a 49 fica fora. Colisor continua 7/31 unidades. **108 contatos estáticos: 45→60 acertos, 15 resultados alterados.** Com pés na mesma altura, todos os golpes acertam nas amostras de 8/18/30/40/50 px e ficam fora a 65 px; nenhum dano atrás. O ensaio colado de 8 px sobrepõe colisores e serve só para geometria. Medições completas em `COMPARACAO_CONTATOS.json`; sem compensação de IA.

A escala fica ~1,08× o Carrasco. Rosto claro e sinos de bronze destacam-se; o manto marrom/musgo combina com o fundo, com menor contraste que o vermelho antigo. Ruptura curva/abaixa o corpo; morte termina em silhueta horizontal, rosto claro e cajado caído, ainda discreta sobre o chão escuro. Postura regenerando após a morte permanece comportamento preexistente.

## Validação

- **Antes/depois: 23/25 suítes, 2069 PASS por rodada; zero regressões.** Mesmas falhas antigas aceitas de `verify_carrasco_gif_test` e `verify_milestone8_2`. **Suíte nova: 200 PASS.** O Profanado arquivado mantém sua suíte de 204, com fixture explícita de mapa.
- Verificador de arte: hashes, 62 cores da paleta, âncoras, 89 corpos com componente único/nenhum pixel isolado, sombra/FX separados e soma exata dos tempos de cada fase. Marcha testada por deslocamento, espelho/reset, áreas/deduplicação e ambas as salas. Ajuste numérico de 0,001 px evita erro nos limites de quadro. F3 desenha por cima da arte/FX.
- Clipe: **960×540, 30 fps, 600 quadros decodificados sem erro**; cinco ataques reais da IA, parry, dois acertos no Peregrino, 49 HP recebidos, ruptura e morte. Entradas programadas; sem dano/HP artificial no clipe. Fotos diagnósticas congelam atores e usam recursos/callbacks originais. Hitstop representado em ticks de 60 Hz só na exportação.
- **SHA256 intacto:** fontes registradas (51), Profanado v1 (160), P40 (1578), prova (1550), checkout original (770), pacotes aprovados (3), histórico e integração anterior protegida (1958). Só leitura no original/protótipos; caches gerados excluídos explicitamente. Main local/remoto permanece `ef24b5561cacb823d1f719370c29d82522cb5b58`.

Abra `JOGAR_INTEGRACAO.cmd`; R reinicia, F9 troca a sala, F3 mostra áreas, G/H alternam sensação. Índice: `codex/evidencias_peregrino_corrompido/CAPTURAS.md`. Manual, contrato e README atualizados. Commit/push somente de `feature/integracao-p40`. Entrega encerrada para avaliação.
