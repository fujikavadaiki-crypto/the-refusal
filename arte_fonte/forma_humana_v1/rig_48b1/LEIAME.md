# Forma Humana — revisão 4.8b1

Revisão separada da 4.8b: somente o desenho de coxa, joelho e canela dos oito quadros de `run`. A 4.8b continua intacta em `../rig_48b/`. Esta arte não está instalada no jogo.

As 32 variantes de calça são orientadas pela sequência quadril → joelho → tornozelo. Coxa e canela compartilham a seção do joelho; a largura da articulação é limitada para evitar um nó. A perna próxima conserva a luz mais clara e a distante usa os tons mais escuros da paleta oficial. Os pixels da roupa/capa, arma e botas originais têm prioridade sobre a revisão.

`rig.json` registra as variantes, seus pivôs inteiros, hashes e referências às partes originais. `poses.json` contém os joelhos revisados e a escolha da variante de cada segmento. `poses_movimento_original.json` é uma cópia exata das poses da 4.8b. A pose neutra continua reproduzindo o mestre pixel a pixel; `idle` usa os mesmos arquivos da 4.8b por referência.

`mascaras_edicao/run_f*.png` delimita a região permitida das pernas, excluindo todos os pixels protegidos. `diferenca_f*.png` mostra apenas os pixels RGBA efetivamente alterados. A composição começa no quadro original, troca os segmentos dentro desse corredor e limpa os encaixes localmente. As botas e os pixels fora da máscara permanecem idênticos. Nos limites da bota, vizinhos originais de sua luz/sombra são mantidos quando necessários para evitar uma cor isolada.

Oito quadros de 96 × 64, âncora (40,56), 41,67 ms por quadro e 6 px/quadro por distância. Percurso das solas, apoio/passagem, quadris, tornozelos, oscilação do corpo e atraso da capa são os da 4.8b. A oscilação discreta de 6 px não foi corrigida.

Na raiz desta cópia, com Python, Pillow, NumPy e SciPy disponíveis:

```text
python -B arte_fonte/ferramentas/corrigir_pernas_forma_humana_48b1.py
python -B arte_fonte/ferramentas/corrigir_pernas_forma_humana_48b1.py --verify
python -B arte_fonte/ferramentas/corrigir_pernas_forma_humana_48b1.py --reproduce
python -B arte_fonte/ferramentas/corrigir_pernas_forma_humana_48b1.py --preview
```

A ferramenta importa o gerador da 4.8b e o kit de rig aprovado como bibliotecas de leitura. Não usa os mestres rejeitados do Corvo/Raiz. As saídas ficam nesta revisão e em `codex/evidencias_forma_humana_48b1/`. A prévia é uma simulação externa marcada PRÉVIA, com chão do cemitério, escala da arte ×1, zoom de referência 0,9 e detalhe ×4 NEAREST; não é uma captura de arte instalada.

As evidências incluem GIFs antes/depois, folhas ×1/×4, comparação com o mestre, máscara de edição, comparação das botas/solas, registros dos 600 quadros da prévia, testes e auditoria SHA256.
