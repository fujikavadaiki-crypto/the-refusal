# The Refusal — padrão visual de personagens

Status: **direção de arte para avaliação**. A Bíblia Canônica e Técnica v3.0 continua superior para regras, números, mecânicas e lore. Este documento registra os critérios visuais fornecidos para o estudo do Carrasco Base; não aprova nenhum sprite.

## Fontes

- Prancha oficial do Carrasco Base: [`assets/reference/carrasco_base_official.png`](assets/reference/carrasco_base_official.png). Define o design da forma Base.
- Prancha de poses aprovada: [`docs/art_reference/carrasco_approved_animation_board.png`](docs/art_reference/carrasco_approved_animation_board.png). Define a aparência e a linguagem de pose de Idle, Run e Heavy; os demais quadros não entram neste Golden Sample.
- Prancha de evolução aprovada: [`docs/art_reference/carrasco_official_evolution_board.png`](docs/art_reference/carrasco_official_evolution_board.png). Usar apenas a coluna **Forma Base** nesta etapa. As evoluções permanecem fora de escopo.
- Referência de qualidade de pixel art enviada em 24/09/2026: captura de outro jogo em `C:/Users/daiki/Downloads/Imagem do Codex 24 de set. de 2026, 11_43_12.jpg`. Serve só para aferir acabamento, leitura e integração personagem/cenário; nenhum design ou asset deve ser copiado. Não é incorporada ao repositório.

## Critério visual

O sprite de gameplay deve ser reconhecível como o personagem da prancha sem nome, HUD ou explicação. São essenciais a máscara frontal gradeada, o capuz, os ombros largos, a armadura pesada, os tecidos rasgados, as correntes principais, as botas e o machado longo de cabeça larga. A silhueta transmite peso sem transformar o Carrasco em gigante.

Prioridade de leitura: **máscara → cabeça do machado → corpo e ombros → capa e tecidos → correntes grandes → armadura → detalhes menores**. Detalhes que não sobrevivem ao tamanho real de jogo não devem virar ruído.

## Pixel art e animação

- Cada pose importante deve ser desenhada em pixels nativos, com clusters intencionais, contorno seletivo e massas legíveis. Não reduzir a concept art, aplicar filtro de pixelização, blur, antialiasing suave ou girar/esticar peças rasterizadas para simular movimento.
- Paleta e direção de luz devem permanecer coerentes entre frames. Metal, tecido, couro, máscara, machado e detalhes quentes precisam ser distinguíveis.
- A máscara mantém uma grade visível. O machado mantém cabeça, cabo, tamanho e empunhadura coerentes entre frames.
- Silhueta, anatomia, mãos, arma e contato dos pés com o chão devem ser conferidos frame a frame. Evitar tremor por subpixel e deslizamento excessivo dos pés.
- VFX de arco, impacto, faíscas, sangue, Condenação e Tribunal devem ficar separados da arte corporal; o Heavy precisa funcionar visualmente mesmo sem VFX.

## Golden Sample e aprovação

Somente **Idle, Run e Heavy** compõem a primeira prova de qualidade. Idle deve demonstrar identidade em repouso, com respiração e reação sutis de pano, corrente e arma. Run deve preservar essa identidade, mostrar impulso e peso. Heavy deve mostrar antecipação, aceleração, impacto, continuação e recuperação com transferência de peso pelo corpo inteiro. Os tempos mecânicos existentes permanecem intactos.

Avaliar as três animações ampliadas e também em tamanho real de gameplay. Comparar leitura em fundo escuro simples e, se houver seção adequada, no Bosque existente. A aprovação humana das três é necessária antes de substituir o atlas completo ou produzir as outras animações e evoluções.

## Escala

Relação visual aprovada: humano = 100%; Carrasco Base ≈ 110–115%. A implementação anterior usa aproximadamente 27 px para humano e 31 px para Carrasco. Testar primeiro o novo desenho em 31 px. Se a identidade não couber, comparar 31, 35, 38 e 40 px (ou valores próximos) e escolher **a menor escala que preserve a identidade**, mantendo a relação entre os dois personagens. Altura visual e resolução da arte não mudam automaticamente collider, física, alcance ou hitboxes.
