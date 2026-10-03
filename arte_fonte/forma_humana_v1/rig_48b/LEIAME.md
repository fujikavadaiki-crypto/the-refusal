# Forma Humana — rig 4.8b para avaliação

Somente `idle` e `run`. A caminhada usa `run`. Esta pasta não é um pacote final e não é usada pelo jogo.

O mestre aprovado permanece em `../forma_humana_mestre_x1.png`, SHA256 `204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988`.

- `partes/`: 13 recortes nativos, RGBA, cada um no canvas original 50×52. As duas botas e a mão/espada conservam seus pixels nativos.
- `rig.json`: pivôs, origem, camadas, juntas e preenchimentos das regiões do tronco que estavam cobertas. A composição neutra reproduz todos os pixels RGBA do mestre.
- `pose_neutra_recomposta_x1.png`: composição transparente no canvas original, âncora `(24,50)`.
- `poses.json`: oito poses de cada ciclo. As pernas registram quadril, joelho, tornozelo, deslocamentos das peças, apoio/passagem; a capa usa o quadro anterior.
- `quadros/`: 16 PNGs, canvas 96×64, âncora dos pés `(40,56)`. A margem maior permite mover as peças, sem mudar sua escala.
- `contrato_ciclos.json`: arquivos, hashes, âncoras e tempos copiados do Carrasco v34A. Não contém golpes, hurtbox, FX, sombras ou outras animações.

O membro distante fica atrás; tronco/capa cobrem a raiz da perna próxima; a mão/espada fica na frente. A corrida articula a perna acima da bota. A bota não gira, não escala e não estica. O apoio recua 6 px por quadro enquanto o personagem avança 6 px. A passagem eleva o pé em 2–5 px. O corpo oscila 2 px; a capa gira apenas 8–12° em NEAREST, com atraso de um quadro. No idle o tronco respira 1 px e os pés, rosto e cabelo não mudam de posição.

Para reproduzir, a partir da raiz de `integracao-p40`, com Python, Pillow, NumPy, SciPy e a biblioteca local aprovada `arte_fonte/kit_rig/` disponíveis:

```text
python -B arte_fonte/ferramentas/animar_forma_humana_48b.py
python -B arte_fonte/ferramentas/animar_forma_humana_48b.py --verify
python -B arte_fonte/ferramentas/animar_forma_humana_48b.py --preview
python -B arte_fonte/ferramentas/animar_forma_humana_48b.py --verify-preview
```

O primeiro comando recria as partes, poses e PNGs exclusivamente desta etapa. A verificação recarrega os PNGs do rig e `poses.json` e reproduz os 16 quadros, comparando os pixels. `--preview` usa o FFmpeg já presente no protótipo 3.6, apenas como ferramenta de codificação, e grava a montagem de 20 s na pasta de evidências nova.

Evidências: `codex/evidencias_forma_humana_48b/`. GIFs sobre cinza e folhas ×1/×4; comparação mestre/recomposto; vídeo marcado **PRÉVIA — RIG NÃO INSTALADO NO JOGO**, com visão ×1, detalhe ×4 e marcas fixas no chão. JSON/CSV registram o deslocamento e os apoios.

Os PNGs conservam os tempos exatos do contrato. GIFs têm resolução de 10 ms: idle soma 2.000 ms e pode juntar imagens idênticas; run soma 330 ms, contra 333,36 ms dos oito tempos de 41,67 ms. Na prévia, `run` é escolhido por distância, a cada 6 px, nas velocidades humanas atuais. Ela mantém visível a oscilação discreta da sola entre trocas, até 6 px; não usa travamento artificial dos pés.

O kit foi usado como biblioteca, sem registro neste commit. Nenhum mestre rejeitado do Corvo/Raiz foi usado. Arte, colisão e física instaladas continuam preservadas. As demais animações aguardam avaliação dos passos.
