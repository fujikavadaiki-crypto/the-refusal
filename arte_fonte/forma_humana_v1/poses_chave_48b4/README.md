# 4.8b4 — somente f0 estática

Proposta separada, sem substituir nenhuma revisão anterior. F4/f2/f6 permanecem propostas; ciclo completo e 4.8c em espera. Esta pasta não é um pacote instalável e não contém animação, GIF ou vídeo.

`quadros/run_f0.png`: RGBA transparente, canvas 96 × 64, âncora (40,56). `variantes/` contém a nova perna recolhida e uma cópia pixel a pixel da perna de apoio da 4.8b3. `desenhos_pixels.json` registra as linhas de pixels e paleta; `rig.json` e `poses.json`, pivôs, articulações, transformações e diferenças. As 13 partes neutras continuam referências de leitura ao rig aprovado.

| Ponto da perna recolhida | 4.8b3 | Proposta | Delta |
|---|---|---|---|
| Quadril | (41,43) | (41,43) | (0,0) |
| Joelho | (40,52) | (39,48) | (−1,−4) |
| Tornozelo | (34,47) | (33,44) | (−1,−3) |
| Centro da sola elevada | (31,51) | (32,49) | (+1,−2) |

Y aumenta para baixo. O joelho fica 7 px acima do chão Y=55; a sola elevada, 6 px. A coxa aparente mede 5,39 px e a canela, 7,21 px entre articulações. O apoio inteiro é idêntico à 4.8b3: quadril (44,43), joelho (49,48), tornozelo (50,50), sola (52,55).

O limite de 2 px foi revogado e não é usado como restrição. Estes pontos são uma proposta estática reposicionada; **não representam trajetória idêntica** à revisão anterior. O contrato histórico de oito quadros, 41,67 ms, 6 px/quadro e velocidades humanas permanece intacto, somente como referência; nenhum ciclo foi regenerado.

Reproduzir a partir da raiz desta cópia:

```text
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b4.py
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b4.py --verify
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b4.py --reproduce
```

Usa `arte_fonte/kit_rig/` aprovado somente como biblioteca de leitura; kit pendente fora do commit. Corpo e perna próxima compõem por cima da perna distante, com arma à frente. Máscaras registram o corpo protegido, regiões das pernas/botas e diferenças. Evidências em `codex/evidencias_forma_humana_48b4/`.
