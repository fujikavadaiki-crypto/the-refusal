# Peregrino Profanado (substitui o Peregrino) - pacote E1 v1

Formato igual ao do Carrasco pequeno A (`manifesto_sprites.json`). Lido do jogo (so leitura): peregrino.gd, peregrino_brain.gd, peregrino_attack.gd, peregrino_tuning.gd, peregrino_tuning.tres, peregrino.tscn...

- `quadros/<animacao>/` corpo (capa/asas ja incluidas), `efeitos/` camadas separadas (`_fx_` atras do corpo: arcos em meia-lua; `_brilho_` a frente: aviso de ataque e atordoamento), `sombras/`.
- Cada ataque tem `ataque` no manifesto: fases PREPARACAO / ATIVO / RECUPERACAO que somam exatamente os .tres do jogo, aviso (aparavel = palido, nao aparavel = vermelho) e, por quadro ATIVO, `hitbox` (poligonos recortados a frente do corpo).
- `hurtbox_sugerida` e `estados_ia` (estado do jogo -> animacao) no manifesto.
- Espelhar para a esquerda quando o inimigo olhar para a esquerda (inverter x dos poligonos de hitbox tambem).
- Status: TESTE para avaliacao.
