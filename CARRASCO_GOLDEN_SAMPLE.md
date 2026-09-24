# Carrasco Base — registro do Golden Sample

Status em 24/09/2026: **não aprovado e não integrado**. O atlas funcional de 104 frames do Milestone 8.3 permanece em uso. Este registro é um diagnóstico de pré-produção, não um anúncio de Golden Sample concluído.

## Referências recebidas

- A prancha de animações aprovada mede 1491 × 1055 px. Contém exemplos de 4 poses de Idle, 6 de Run e 6 de Heavy, além de movimentos fora do escopo. É RGB opaca, com fundo, títulos, linhas divisórias e efeitos. Funciona como referência de design/pose, mas não é um conjunto de frames transparentes importáveis.
- A prancha de evolução mede 1448 × 1086 px. Somente a coluna Forma Base é pertinente neste teste.
- O benchmark de acabamento mede 1536 × 862 px e pertence a outro jogo. É referência visual externa; não é uma fonte de sprites para The Refusal.
- Uma tentativa de isolar automaticamente o primeiro Idle redesenhou a figura em alta resolução e não entregou transparência verdadeira nem pixels nativos. Foi rejeitada e não está no repositório.

## Base técnica preservada

- Projeto Godot: 480 × 270 px de viewport, filtro nearest no sprite do Carrasco.
- Atlas atual: tiles de 64 × 48 px e corpo declarado de 31 px em `assets/characters/carrasco_base_gameplay/frames.json`.
- Controle visual atual: `scripts/player/visuals/carrasco_base_visual.gd`; Idle 4 fps, Run 12 fps, Heavy selecionado pelas fases mecânicas.
- Heavy mecânico em `data/attacks/carrasco_heavy.tres`: antecipação 0,32 s, fase ativa 0,14 s e recuperação 0,43 s. Estes valores são somente referência de sincronização e não foram alterados.

## Escala: primeiro diagnóstico

Com o humano atual de cerca de 27 px, 31 px coloca o Carrasco em aproximadamente 115%. Os tamanhos de estudo 35, 38 e 40 px equivaleriam aproximadamente a 130%, 141% e 148% desse humano. Portanto, ampliar apenas o Carrasco sem repensar a escala visual do humano quebraria a proporção aprovada. Nenhum collider, câmera ou hitbox foi ajustado.

No teste visual em 40 px, a grade da máscara e a cabeça do machado conseguiram ocupar mais pixels, mas a roupa, as correntes, o volume da armadura e o movimento ainda não atingiram o padrão premium solicitado. O teste foi descartado e não integra o jogo. A geração de imagem condicionada pela concept art também não produziu uma folha de sprites utilizável: trouxe fundo quadriculado incorporado e detalhes em escala incompatível com pixels nativos de gameplay. Não foi reduzida nem filtrada para forçar o uso.

## Critérios pendentes de validação

1. Produzir um Idle de pixels nativos que preserve o design da prancha e seja legível no zoom real. Arquivos originais em camadas ou frames transparentes, se existirem, ajudariam a preservar detalhes aprovados, mas a prancha achatada não pode ser tratada como esses arquivos.
2. Só após o Idle passar na avaliação, produzir Run e Heavy na mesma qualidade, em frames próprios e com machado/anatomia consistentes.
3. Entregar três sheets, contact sheet ampliada, capturas reais de jogo, paleta e especificação de dimensões/escala. Reproduzir no Godot e conferir leitura em fundo escuro e no Bosque.
4. Submeter os três movimentos à aprovação humana. Até lá, manter o atlas de 104 frames para comparação e não produzir as demais animações.
