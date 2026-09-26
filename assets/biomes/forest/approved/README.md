# Bosque dos Esquecidos — arte aprovada

`bosque_a.jpg`, `bosque_b.jpg` e `bosque_c.jpg` são as três imagens de cenário incorporadas na página 3 de `The_Refusal_Biblia_Visual_Oficial_v1.0.pdf`. Os JPEGs originais ficam preservados aqui, sem redesenho.

`tools/build_bosque_scene_layers.py` extrai deles os planos transparentes em `layers/`. A separação de profundidade usa a luminosidade e a posição dos próprios pixels: árvores, raízes, ruínas próximas e piso permanecem ancorados; apenas a atmosfera e os elementos distantes participam da paralaxe. As transições são graduais para não cortar troncos ou deslocar a parte superior da arquitetura em relação ao chão. `fog_puff.png` é um pequeno efeito de névoa com borda 100% transparente.

Na cena, `LayeredBosque` compõe fundo distante, ruínas intermediárias, arquitetura próxima, piso jogável e copa à frente. O piso tem sprites próprios, separados dos planos que se movem. Névoa, folhas, poeira, raios de luz e cintilação de água têm animação leve. O Carrasco aprovado permanece no mesmo atlas; somente o pivô visual foi alinhado aos pés da cápsula de colisão nesta fase.

Os pontos de colisão correspondentes aos caminhos e pontes visíveis ficam em `scripts/biomes/forest/forest_slice_01.gd`. Dois pilares de pedra pintados no cenário também têm plataformas estreitas. Os três vãos continuam abertos para salto e dash aéreo.
