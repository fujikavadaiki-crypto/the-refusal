# Forma Humana — revisão 4.8b7

Somente arte-fonte de **run**, para avaliação. Não instalada no jogo; caminhada usa este mesmo ciclo. Mestre neutro e idle anteriores permanecem intactos. 4.8c continua em espera.

Base obrigatória: `../pose_corrida_48b6/run_f0_x1.png`, SHA256 `28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852`. Tanto `f0_recomposta_x1.png` quanto `quadros/run/run_f0.png` têm esse mesmo hash, inclusive os bytes PNG.

- `partes/` e `rig.json`: nove peças-base com pivôs/camadas e dezesseis variantes de pernas. Biblioteca `arte_fonte/kit_rig`, somente leitura; nenhum mestre de Corvo/Raiz foi usado.
- `poses.json`: oito poses, variantes, deslocamentos inteiros e acabamento das junções expostas. Ordem: membro distante → corpo/pano → membro próximo → arma. Cabeça, mão e espada são peças rígidas sem escala/rotação. Capa atrasa um quadro.
- `contrato_ciclos.json`: somente run, oito quadros de **41,67 ms**, nomes do Carrasco v34A, **6 px/quadro** por distância. Soma real 333,36 ms; valor nominal da referência 333,33 ms preservado como informação.
- `SOLAS_ARTICULACOES.json`: pontos inteiros novos, no canvas **96×64**, âncora **(40,56)**, chão **Y=55**. Apoio recua 6 px por quadro; passagem tem bota elevada.

O ajuste pedido durante a tarefa separa a calça escura do cano marrom. Após a crítica ao afinamento abrupto, as novas variantes de apoio foram redesenhadas como uma peça contínua: coxa/canela de 6 px e pé abrindo gradualmente até a sola de 9 px. A calça é escura e o cano marrom tem luz/sombra próprias. A f0 permanece exatamente aprovada. Comparações específicas de f3 e f5 ficam nas evidências; as duas versões anteriores ao ajuste foram preservadas em subpastas próprias. Articulações da f3 foram reposicionadas e registradas, mantendo a sola apoiada (22,55).

Na raiz do checkout, com Python, numpy, Pillow e scipy disponíveis:

```text
python -B arte_fonte/ferramentas/animar_corrida_forma_humana_48b7.py
python -B arte_fonte/ferramentas/animar_corrida_forma_humana_48b7.py --verify
python -B arte_fonte/ferramentas/animar_corrida_forma_humana_48b7.py --preview
python -B arte_fonte/ferramentas/animar_corrida_forma_humana_48b7.py --verify-preview
python -B arte_fonte/ferramentas/animar_corrida_forma_humana_48b7.py --reproduce
```

A ferramenta usa a biblioteca aprovada já presente e as dependências locais da 4.8b6; não altera nem registra o kit pendente. O vídeo depende do FFmpeg anterior, lido no protótipo 3.6. Nenhum código do jogo é executado para montar a prévia.

Evidências: `codex/evidencias_forma_humana_48b7/`. GIF ×4 sobre cinza, folhas ×1/×4, comparações, partes/pivôs, articulações auxiliares e **PRÉVIA externa de 20 s** no cemitério. 0–10 s caminhada a 2,690217 m/s; 10–20 s corrida a 4,891304 m/s, valores lidos da física humana atual. Arte ×1, ampliação auxiliar ×4 NEAREST. Marcas fixas e dados CSV/JSON mostram deslocamento e apoios. O PNG fixo avança entre eventos de 6 px: a oscilação discreta permanece visível, sem correção de física ou cadência.
