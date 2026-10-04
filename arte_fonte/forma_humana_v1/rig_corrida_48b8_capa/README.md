# 4.8b8 — revisão da capa de run

Proposta de arte-fonte, sem instalação no jogo. Base: `../rig_corrida_48b7/`, commit `c9adc51`. Passada, f3 corrigida, peças, poses e solas dessa base são preservadas. F0 é idêntica à 4.8b6, SHA256 `28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852`.

Oito variantes `partes/capa_onda_f0.png` … `capa_onda_f7.png`: o ombro acompanha a oscilação atual; a deformação aumenta em direção à barra e percorre o pano com fase atrasada um quadro. As colunas de tecido preservam largura, luz e dobras, com contorno limpo em pixels inteiros. A raiz não gira nem se desloca localmente. `CAPA_MATERIAL.json` registra offsets, fase, pivô e referências estudadas.

`rig.json` registra peças/camadas/pivôs; `poses.json` registra as oito composições; `SOLAS_ARTICULACOES.json` é cópia byte a byte da base. `contrato_ciclos.json` mantém run de 8 quadros, 41,67 ms/quadro, seleção por distância de 6 px/quadro, canvas 96×64, âncora (40,56) e chão Y=55. Caminhada usa run. Não contém idle nem novas ações.

Reprodução pela biblioteca `arte_fonte/kit_rig`, somente para leitura. Use `render_pose` da ferramenta `arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py`: primeiro ela recompõe a base e preserva os pixels visíveis das outras peças, depois retira o tecido antigo e compõe a variante atrás dessas peças. O compositor é explícito porque a separação antiga incluía pixels marrons do corpo no recorte da capa e um pequeno fragmento cinza da barra no recorte da perna distante. A classificação desses fragmentos fica registrada; os 25 arquivos de peças da base continuam byte a byte idênticos. Não usar uma composição genérica do rig que ignore essa separação semântica.

Com Python com Pillow/NumPy/SciPy e o kit disponíveis, a partir da raiz da cópia de integração:

```text
python -B arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py
python -B arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py --verify
python -B arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py --reproduce
python -B arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py --preview
```

A geração escreve apenas nesta revisão e em `codex/evidencias_forma_humana_48b8/`. A prévia depende do FFmpeg já disponível na ferramenta anterior e do fundo congelado, ambos só leitura. É uma simulação externa marcada PRÉVIA, com 10 s de caminhada e 10 s de corrida, marcas fixas e detalhe ×4. A movimentação discreta entre eventos de 6 px continua visível.

GIFs sobre cinza, folhas ×1/×4, f0/recomposição, fechamento f6→f7→f0→f1, máscaras e dados de preservação estão na pasta de evidências. O GIF arredonda os tempos para unidades de 10 ms; o contrato permanece em 41,67 ms. Os PNGs são transparentes, paleta oficial, alpha 0/255, sem sombra embutida.

Estudo: Walk de `preview 6.webp`, Walk/dobras nos golpes de `148019.png`, Walk/Dash de `148045.png`. Aplicados ligação ao corpo, onda no meio e curvatura/retorno da ponta, sem copiar sprites, tempos ou o porte dos personagens de referência. 4.8c continua em espera, aguardando avaliação desta capa.
