# 4.8b3 — propostas estáticas f0/f4

Revisão separada, sem substituir a 4.8b2. F2/f6 permanecem propostas; ciclo completo e 4.8c em espera. Esta pasta não é um pacote instalável nem contém animação.

`quadros/run_f0.png` e `run_f4.png`: RGBA transparente, canvas 96 × 64 e âncora (40,56). `variantes/` contém quatro peças inteiras de perna/bota. As linhas de pixels, paletas e articulações estão em `desenhos_pixels.json`; pivôs e transformações em `rig.json` e `poses.json`. As 13 partes antigas são referências de leitura, sem cópias modificadas.

A coxa da perna recolhida desce ao joelho; a canela volta diagonalmente ao calcanhar alto. A bota possui cano, pé curto e sola. O joelho pode ficar abaixo da sola elevada, como numa perna dobrada; somente a bota termina na sola registrada. O corpo e a capa cobrem os mesmos pixels anteriores.

| Pose | Apoio, antes = depois | Sola elevada, antes → depois | Deslocamento |
|---|---|---|---|
| f0 | (52,55) | (29,52) → (31,51) | (+2,−1) px |
| f4 | (49,55) | (32,52) → (34,51) | (+2,−1) px |

O eixo Y aumenta para baixo. Quadris e oscilação corporal/capa preservados. `REFERENCIA_MOVIMENTO.json` apenas registra o contrato existente: oito quadros, 41,67 ms e 6 px/quadro; nenhuma mudança de movimento.

Reprodução a partir da raiz desta cópia:

```text
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b3.py
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b3.py --verify
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b3.py --reproduce
```

Usa a biblioteca aprovada de `arte_fonte/kit_rig/` somente para leitura. O kit pendente não integra este commit. Evidências e auditorias em `codex/evidencias_forma_humana_48b3/`; máscaras de corpo protegido, pernas/botas e diferenças nesta pasta.
