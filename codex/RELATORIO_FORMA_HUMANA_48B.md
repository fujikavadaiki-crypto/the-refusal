# Tarefa 4.8b — Forma Humana: rig, idle e run

Entregues 13 partes com pivôs/camadas, pose neutra, poses reproduzíveis e somente os ciclos `idle`/`run`, com oito PNGs cada. Caminhada usa `run`; cadência de 6 px/quadro. Arte ainda não instalada.

A pose neutra recomposta é **RGBA idêntica ao mestre aprovado: zero pixels diferentes**. O mestre conserva SHA256 `204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988`. Só foram completadas regiões do tronco escondidas por outras partes, dentro da silhueta original; 54 pixels com cor completada permanecem cobertos na pose neutra. Conceito, PROMPT, mestre e evidências 4.8a ficaram intactos.

| Conferência | Resultado |
|---|---|
| Canvas/âncora da reconstrução | 50×52 / `(24,50)`, corpo aprovado de 48 px |
| Canvas/âncora dos ciclos | 96×64 / `(40,56)`, margem adicional; arte ×1 |
| Cores/transparência | 25 cores, todas da paleta_bosque_v1; alpha somente 0/255 |
| Limpeza | Um componente por quadro; zero pixels de cor isolada nos 16 PNGs |
| Idle | Respiração de 1 px; rosto/cabelo RGBA idênticos e pés fixos em todos os quadros |
| Run | Apoio alternado entre pernas; passagem elevada 2–5 px; quadril/joelho/tornozelo articulados |
| Botas | Peças nativas de 43/44 pixels; sem giro, escala ou alongamento; solas de apoio RGBA preservadas |
| Corpo/capa | Oscilação de 2 px; capa atrasa um quadro; giros pequenos 8–12°, NEAREST |
| Arma | Mão/espada nativas preservadas nos 16 quadros; lâmina inteira fora do rosto |
| Reprodução | Os 16 PNGs são reproduzidos pixel a pixel recarregando rig e poses salvos |
| Sombra/combate | Sem sombra embutida, golpes, pacote final ou alterações no jogo |

Tempos copiados do manifesto instalado do Pequeno A v34A: idle `[280,250,250,280,250,250,220,220]` ms, total 2.000 ms; run oito vezes 41,67 ms, soma 333,36 ms. A referência declara duração nominal 333,33 ms; seu arredondamento foi registrado, sem mudar nenhum tempo. GIFs quantizam para 10 ms: idle 2.000 ms, run 330 ms; quadros idênticos do idle são fundidos pelo formato, conservando a duração. Os 16 PNGs continuam separados no contrato.

A montagem **PRÉVIA** tem 20 s, 600 quadros a 30 fps, simulados a 60 Hz: 10 s de caminhada e 10 s de corrida nas velocidades humanas atuais, **2,6902 e 4,8913 m/s**, com aceleração atual. Fundo do cemitério em ×1, referência de zoom 0,9, detalhe dos pés ×4 e marcas fixas no chão. O remendo previsto pelo kit para remover o personagem congelado é aplicado apenas em memória. Não é captura de arte instalada, não simula colisão/IA e não altera velocidade ou mapa.

O avanço de 6 px é compensado por recuo de 6 px da sola nas trocas entre apoios: zero deslocamento da sola nesses eventos exatos. Entre eventos, o PNG fixo acompanha a posição contínua do personagem: há oscilação discreta de **até 6 px** no apoio, sem deriva acumulada além de um quadro. Ela aparece na prévia e no JSON/CSV de deslocamento, para avaliação honesta dos passos.

Testes antes/depois: mesmas 25 suítes, **23 aprovadas, 2.069 verificações positivas**, mais **200 verificações aprovadas** do pacote real do Peregrino. Nenhuma nova falha. Permanecem apenas `verify_carrasco_gif_test` (acesso a `texture_filter` em instância nula) e `verify_milestone8_2` (acesso legado a `sprite`), já aceitas. Conferências do rig/ciclos e da prévia também aprovadas.

Auditoria SHA256: **6.699 arquivos protegidos idênticos** — integração fora da etapa, prova, P40, checkout original, pacotes, referências e histórico. `main`, HEAD/status do checkout original, conceito/PROMPT e mestre preservados. Todas as diferenças são listadas em `PRESERVACAO_resultado.json`; nenhuma diferença externa do Diretor foi observada. `kit_rig/` e `codex/diretor/` já estavam não rastreados e ficam fora do commit. Nenhum mestre rejeitado foi usado.

Evidências em `codex/evidencias_forma_humana_48b/`: `MESTRE_RECOMPOSTO_x4.png`, `PARTES_PIVOS.png`, `idle_x4.gif`, `run_x4.gif`, folhas dos ciclos ×1/×4, `PREVIA_caminhada_corrida_20s.mp4`, fotos marcadas PRÉVIA, verificações, testes, auditoria e hashes desta entrega. Fonte reproduzível em `arte_fonte/forma_humana_v1/rig_48b/` e `arte_fonte/ferramentas/animar_forma_humana_48b.py`.

Commit/push restritos à arte, ferramenta e evidências da 4.8b no branch `feature/integracao-p40`. Encerrado para avaliação dos passos, antes das demais animações.
