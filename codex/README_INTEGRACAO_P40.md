# Jogar a integração — Tarefa 4.3 / Cemitério

Abra **JOGAR_INTEGRACAO.cmd** na raiz desta cópia. Ele inicia o **cemitério/ruínas congelado do P40**, com Peregrino, Corvo e Raiz originais, Carrasco Pequeno A v34A equipado e vida/postura visíveis. O mesmo mapa é a cena inicial de `project.godot`. **F9 alterna entre cemitério e Bosque B**; R reinicia o encontro e renasce depois de morrer. O launcher usa Godot 4.7.2 já instalado e mantém os arquivos de execução em `.godot/` desta cópia.

| Tecla | Ação |
|---|---|
| A/D ou setas | Mover |
| Shift | Caminhar |
| Espaço | Pular |
| J | Leve; novas entradas enfileiram o combo 1/2/3 |
| K | Pesado; segure 1 s para carregar, solte para golpear |
| L | Dash no chão/no ar; J/K podem cancelar após 80 ms |
| I | Parry |
| Tab | Alternar humano/Carrasco |
| U / O | Habilidades da máscara |
| P | Tribunal |
| H | Execução de alvo elegível |
| R | Reiniciar jogador e três inimigos |
| F3 | Exibir áreas físicas e polígonos ACTIVE do golpe |
| F9 | Alternar cemitério ↔ Bosque B da integração |

Carrasco corre a **4,5 m/s**, dash **3,5 m / 0,35 s**, pulo observado **2,315 m** a 60 Hz. Corpo/hurtbox: raio **7 unidades**, altura **51,111111**, pés Y=13; humano conserva altura 64. Parada física normal; apoio/freio são somente visuais.

Pequeno A desenha em ×1 NEAREST, com pés arredondados para pixels inteiros. A corrida avança a cada 6 px percorridos; o pacote define os quadros e áreas de dano. Uma sombra fica no chão, reduzindo/clareando no ar. Ataques altos dos inimigos podem passar acima do corpo pequeno; isso foi aceito nesta fase.

Fundo 960×540 em ×1 NEAREST; câmera fixa 0,9 e escala de 32 px/m. Quatro trechos de chão e quatro plataformas iguais ao P40. Pedra, ruína e pilar são alcançáveis do chão; para a coluna, suba no pilar e pule à esquerda. Peregrino nasce no chão, Raiz perto da ruína e Corvo no alto. Seus scripts, valores e ataques foram preservados. O modo antigo segue disponível pelo atributo `small_carrasco_enabled` do apresentador; humano e arquivos de arte antigos foram mantidos.

**Origem da imagem:** o arquivo do P40 coincide byte a byte com `prova/a1_inicio/imagens/A11_quadro_A11_960x540.png`. O arquivo R4 original é diferente. Mantivemos o mapa efetivamente jogado no P40; hashes e distinção em `codex/evidencias_integracao_p40_f4/ORIGEM_MAPA.json`. O PNG não foi retocado; a cobertura local do personagem antigo embutido usa o mesmo atlas do P40.

Evidências: `codex/evidencias_integracao_p40_f4/`; relatório: `codex/RELATORIO_INTEGRACAO_P40_F4.md`; vídeo: `CLIPE_CEMITERIO_PEQUENO_A_30s.mp4` nessa pasta. Captura de 960×540, 30 fps, com entradas programadas e combate real em três encontros; jogador reposicionado entre encontros e hitstop exportado no relógio de 60 Hz. Não substitui avaliação jogada pelo usuário. Bosque e relatórios anteriores preservados. Sem push/merge.

## Reproduzir verificações nesta cópia

Com Python disponível, `python codex/verificar_fase4.py after` roda as **22 suítes** existentes (incluindo F1/F2/F3); `python codex/verificar_fase4.py new` roda a suíte da sala. As fixtures de Bosque continuam instanciando explicitamente o Bosque. O runner executa cópias temporárias das fixtures que gravam medidas, redirecionando somente o destino dos arquivos para preservar as evidências das fases anteriores. As duas falhas conhecidas dos testes da arte antiga estão documentadas no relatório.

`python codex/auditar_sala_f4.py` confere a origem do fundo e as constantes dos colisores. `python codex/capturar_fase4.py capture` exporta os 900 quadros renderizados; `python codex/capturar_fase4.py encode` monta o MP4 com o FFmpeg local. Os caminhos de ferramentas já instaladas estão nesses arquivos. A auditoria de preservação usa `preserve-before`/`preserve-after` antes/depois de novas alterações. Não sobrescrever a linha de base entregue; `before` recusa modificações de produção já presentes.
