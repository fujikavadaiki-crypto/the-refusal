# Milestone 1: fundação jogável do protagonista

Esta entrega implementa apenas a Fase 1 da Bíblia Canônica e Técnica v3.0. A Bíblia Visual Oficial v1.0 orientou a revisão de proporções, enquadramento e espaço; regras e números canônicos continuam subordinados à Bíblia Técnica.

## Estrutura

- `scenes/test_room.tscn`: sala provisória longa, chão, limites, duas duplas de plataformas e marcas a cada viewport.
- `scenes/player/player.tscn`: corpo humano, colisão, visual temporário e câmera.
- `scripts/player/player.gd`: Input Map e direção visual.
- `scripts/player/player_locomotion.gd`: movimento horizontal, gravidade e pulo.
- `scripts/player/player_state_machine.gd`: estados `GROUNDED` e `AIRBORNE`.
- `scripts/player/player_camera.gd`: avanço suave da câmera para o lado observado.

## Controles

| Ação | Teclado | Controle |
| --- | --- | --- |
| Esquerda | A ou seta esquerda | Analógico esquerdo |
| Direita | D ou seta direita | Analógico esquerdo |
| Pular | Espaço | Botão inferior |

## Escala técnica provisória

- Base 480×270, janela inicial 960×540: ampliação exata de 2× com filtro de pixel mais próximo.
- Personagem provisório de 26 px de altura: cerca de 9,6% da tela, contra 14,4% antes.
- Sala de 2.400 px: cinco telas de largura, com trechos contínuos de chão livre de aproximadamente 600 px.
- Duas duplas de plataformas: patamares a 30 e 51 px sobre o chão, separados por 30 px horizontalmente; o patamar alto é alcançado pelo baixo.
- Câmera: 60 px de avanço gradual na direção observada, posição vertical estável e limites dentro da sala.

Estes tamanhos e `run_speed=120`, `ground_acceleration=900`, `ground_deceleration=1100`, `air_acceleration=650`, `gravity=800`, `jump_velocity=-260` continuam **valores técnicos reversíveis** de teste. Não são novos números canônicos. Os placeholders não representam arte final nem uma fase do Bosque.

## Próxima fatia

Somente após aprovação da fundação: espada do prólogo e combate básico. Esta versão não contém combate, inimigos ou sistemas futuros.
