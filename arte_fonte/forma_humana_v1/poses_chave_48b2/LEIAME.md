# Forma Humana — propostas estáticas 4.8b2

Quatro poses para avaliação: `run` f0, f2, f4 e f6. Os PNGs transparentes estão em `quadros/`. As comparações sobre cinza estão em `codex/evidencias_forma_humana_48b2/`. O ciclo aprovado permanece nas pastas anteriores; esta pasta não é um pacote de animação.

Foram desenhadas oito variantes inteiras de perna/bota, uma para cada membro em cada pose. O desenho usa linhas explícitas de pixels, com contorno e grupos de luz/sombra; não reutiliza os recortes verticais nem a geometria/corredor da 4.8b1. A perna recolhida tem seu próprio encaixe de canela e bota. As botas elevadas têm desenho inclinado e solas mais curtas, com o centro e a altura da sola preservados. Cada bota cabe na referência compacta de 9 × 6 px.

`desenhos_pixels.json` registra as linhas de pixels, índices da paleta, articulações e pequenos ajustes de cor nos encaixes. `rig.json` registra PNGs, hashes e pivôs das variantes, usando o quadril como pivô da perna inteira. `poses.json` contém a transformação inteira necessária para reproduzir cada peça pelo kit aprovado. O corpo usa as mesmas poses da 4.8b1, com os pixels visíveis copiados intactos; a roupa, a capa e a espada mantêm sua sobreposição sobre as pernas. A pose neutra recomposta continua idêntica ao mestre aprovado.

As máscaras `corpo_protegido_f*.png` mostram todos os pixels preservados das camadas de cabeça, tronco, capa, braços, capuz e espada. `pernas_botas_f*.png` registra a área dos membros antigos e novos, excluindo o corpo. `diferenca_f*.png` mostra as alterações RGBA efetivas, conferidas como subconjunto da área das pernas/botas. Não há restrição ao corredor da revisão anterior.

Na raiz desta cópia, com Python, Pillow, NumPy e SciPy disponíveis:

```text
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b2.py
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b2.py --verify
python -B arte_fonte/ferramentas/propor_pernas_forma_humana_48b2.py --reproduce
```

A ferramenta importa o gerador anterior e o kit aprovado como bibliotecas de leitura. Só escreve nesta proposta e em suas evidências. A conferência técnica valida o replay RGBA, os hashes, a paleta, alpha, centros/alturas das solas, quadris, pose do corpo, ausência de pixels/cores soltos e a preservação do contrato de movimento. A avaliação visual das pernas permanece pendente do usuário.

`REFERENCIA_MOVIMENTO.json` apenas identifica os parâmetros existentes: oito quadros, 41,67 ms por quadro, 6 px/quadro e as velocidades humanas anteriores. Não foram criados os quadros f1/f3/f5/f7, GIF, vídeo, animações adicionais ou arte instalada.
