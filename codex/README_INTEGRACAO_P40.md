# Jogar a integração — Fase 3 / Pequeno A

Abra **JOGAR_INTEGRACAO.cmd** na raiz desta cópia. Ele inicia o Bosque com Peregrino, Corvo e Raiz, Carrasco Pequeno A v34A equipado e vida/postura visíveis. R reinicia o encontro, inclusive depois de morrer. O launcher usa o Godot 4.7.2 já instalado e mantém os arquivos de execução em `.godot/` desta cópia.

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

Carrasco corre a **4,5 m/s**, dash **3,5 m / 0,35 s**, pulo observado **2,315 m** a 60 Hz. Corpo/hurtbox: raio **7 unidades**, altura **51,111111**, pés Y=13; humano conserva altura 64. Parada física normal; apoio/freio são somente visuais.

Pequeno A desenha em ×1 NEAREST, com pés arredondados para pixels inteiros. A corrida avança a cada 6 px percorridos; o pacote define os quadros e áreas de dano. Uma sombra fica no chão, reduzindo/clareando no ar. Ataques altos dos inimigos podem passar acima do corpo pequeno; isso foi aceito nesta fase.

O jogo base continua abrindo seu Bosque original com o apresentador novo. O launcher adiciona os três inimigos em uma **cena derivada**, sem trocar o cenário ou retocar a IA. O modo antigo segue disponível pelo atributo `small_carrasco_enabled` do apresentador; humano e arquivos de arte antigos foram mantidos.

Evidências: `codex/evidencias_integracao_p40_f3/`; relatório: `codex/RELATORIO_INTEGRACAO_P40_F3.md`. A captura usa comandos programados e combate real; não substitui avaliação jogada pelo usuário. Sem push/merge.

## Reproduzir verificações nesta cópia

Com Python disponível, `python codex/verificar_fase3.py after` roda as 21 suítes completas; `python codex/verificar_fase3.py new` roda a suíte F3. `python codex/capturar_fase3.py capture` exporta os 900 quadros renderizados; `python codex/capturar_fase3.py encode` monta o MP4 com o FFmpeg local. Os caminhos de ferramentas já instaladas estão nesses arquivos. Não executar o modo `before` após alterar o código: a linha de base original foi preservada.
