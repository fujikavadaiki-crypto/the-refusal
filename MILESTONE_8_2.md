# Milestone 8.2 — Carrasco Base: primeira passagem visual jogável

## Referência e limite de aprovação

- A Bíblia Visual Oficial v1.0 disponível em `C:\Users\daiki\Downloads\The_Refusal_Biblia_Visual_Oficial_v1.0.pdf` foi inspecionada por completo (20 páginas). Ela contém a forma humana, o Bosque, inimigos e ambientes, mas não inclui a prancha do Carrasco Base.
- Após a busca inicial, o usuário forneceu a prancha oficial **"Forma Base Carrasco"**. Uma cópia exata está em `assets/reference/carrasco_base_official.png`. Ela define a máscara de grade vertical, o capuz profundo, a armadura escura em placas, o tecido gasto e o machado de duas mãos. A forma Base foi a única usada aqui.
- A prancha é um concept, não uma folha de animação pronta. Foram gerados quatro quadros provisórios com auxílio de IA a partir dela: `idle`, `run`, `light_1` e `heavy`. Variantes que incorporaram fundo quadriculado foram descartadas. Os quadros finais desenhados e a aprovação da versão jogável continuam pendentes de avaliação humana.
- A Bíblia Canônica e Técnica v3.0 continua superior para regras e números. Nenhuma regra ou valor canônico foi alterado.

## Arquitetura

- `MaskData.visual_scene` permite associar uma cena visual à Máscara sem ramificar toda a arte no script do Player. O slot humano vazio mantém os elementos anteriores.
- `PlayerVisualController`, em `VisualRoot`, lê o estado do Combat, Defense, Health e MaskController; escolhe a pose e instancia a cena da Máscara. Ele **não controla** movimento, dano, hitbox, timing ou resolução de golpes.
- `CarrascoBaseVisual` é um `Node2D` com `Sprite2D` e filtro nearest. Seus quatro quadros são selecionados e transformados por estado/fase no script da cena visual, que pode ser substituída por outra Máscara. Pequenos efeitos em pixels continuam em `CanvasItem._draw`. `CondemnationMark` e `CarrascoImpact` são componentes independentes.
- `MaskController.execution_resolved` informa o resultado já resolvido ao visual, sem alterar a resolução. `audio_cue_requested` oferece hooks para SFX futuros, sem pacote novo.
- O projeto já usa base 480×270 e filtro nearest; ambos foram preservados. Não houve mudança de câmera, collider, arena nem Bosque.

## Poses e efeitos provisórios

- Poses de apresentação: idle, run, jump, fall, ground dash, air dash, Light 1/2/3, Heavy, Charged Heavy, Post-Dodge, Air Light/Heavy, Quebra-Selos, Marca, Parry, hit, Rupture/stagger, Execution e death. Elas reutilizam os quatro quadros com inclinação, deslocamento, escala, brilho e efeitos locais; não são sequências de quadros totalmente animadas. Tribunal adiciona aura local à pose corrente.
- Combat fornece `attack_id`, `phase` e progresso de tempo. As poses seguem windup, active e recovery existentes. A hitbox segue o Combat e não é reposicionada pelo visual.
- Light 1 apresenta machado horizontal; Light 2 inclina o avanço para cima; Light 3 usa a pose descendente em escala menor e com maior inclinação. Heavy, Charged Heavy e Quebra-Selos usam a pose descendente maior, com preparação e efeitos diferentes. `charge_ready()` ativa detalhes de brilho após o threshold já existente de 1,0 s.
- O dash mantém corpo e capa visíveis. Air Dash usa o mesmo princípio. A orientação acompanha o `VisualRoot.scale.x` existente.
- Condenação desenha um símbolo pequeno no alvo e até cinco segmentos, com reforço no terceiro e quinto. A contagem vem do `CarrascoRuntimeState`; ela desaparece quando o estado acaba ou a Máscara deixa o slot ativo.
- Tribunal mostra uma moldura ritualística quebrada em pixels ao redor do corpo e aquece a cor da armadura, sem cobrir telegraphs. Execution e Execution Strike usam impactos localizados distintos; não alteram posição, câmera ou duração da jogada.
- VFX curtos: slash comum, heavy, charged, posture, Quebra-Selos, Marca e Execution/Sentence. HP é comunicado pelo slash quente; pressão de Postura usa brilho frio separado. São apenas efeitos de apresentação.
- Os quadros incluem haste longa e cabeça de machado, conforme a prancha. A espada técnica anterior é ocultada enquanto a Máscara está ativa e volta no slot humano vazio. `AttackPivot` e `Hitbox` permanecem intactos. Os marcadores geométricos técnicos de active/charge são ocultos visualmente no Carrasco, mantendo seus valores para os testes antigos.

## Escala e offsets

- O corpo renderizado fica em torno da altura do collider de 26 px, com capa e machado extrapolando a silhueta sem participar da colisão. Os quatro arquivos originais são grandes; a cena aplica escala de 0,027–0,040, ancoragem nos pés e filtro nearest para a base 480×270. Esses valores serão substituídos quando houver sprites finais produzidos na resolução nativa.
- A marca de Condenação é filha visual do alvo em `(0, -29)`; esse offset é provisório para os alvos da arena técnica.
- O impacto aparece no alvo em `y -12`, ou em `y -18` para Postura. Execution usa `y -14`.
- **Colliders alterados: nenhum.** Dimensões e posições de hitbox, ataque e hurtbox não mudaram.

## Validação e limitações

- Godot 4.7.2 stable abriu o projeto e renderizou a arena em OpenGL Compatibility. Captura de inspeção foi produzida localmente em `.godot/` e não é versionada.
- O teste novo `verify_milestone8_2.gd` cobre carregamento da forma, humano sem Máscara, poses de locomoção, dash, charge, fase ativa/hitbox, Condenação, Tribunal, troca de slot e collider.
- Os nove números de golpes solicitados e os sistemas de Condenação, Tribunal, Execution, swap, Air Dash e Parry continuam cobertos pelos testes anteriores.
- A bateria completa `verify_milestone2.gd` a `verify_milestone8_2.gd` foi executada: todos os 11 testes de milestone retornaram código 0. O projeto reabriu no editor Godot 4.7.2 sem erro de script.
- Foram renderizadas 22 capturas locais de poses de locomoção, ataques, carga, Condenação, Tribunal, Execution e orientação para inspeção de escala, silhueta e colisão visual. Essas capturas são temporárias em `.godot/`, sem versionamento. Uma seleção da arena está disponível fora do repositório em `outputs/`.
- Os quatro quadros integrados têm transparência e reproduzem a máscara gradeada, armadura, capa e machado da prancha oficial. Algumas imagens geradas para salto e Light 2 tinham fundo quadriculado incorporado e foram rejeitadas. As poses derivadas ainda não constituem animação quadro a quadro; Light 2 e Light 3 merecem quadros próprios na etapa de arte final. A avaliação visual humana é necessária antes de aprovar o design como definitivo.
- Aviso ambiental observado no Godot: falha ao ler o armazenamento de certificados raiz do Windows. Não houve erro de script após o ajuste de um polígono da capa encontrado na primeira execução.

## Fora do escopo

Sem Ressonância, evoluções, Corvo, novo combate, novo inimigo, bioma, chefe, HUD final, áudio final ou câmera cinematográfica.
