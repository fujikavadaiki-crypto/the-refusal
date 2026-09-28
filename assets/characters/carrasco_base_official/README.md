# Carrasco — Forma Base: padrão inicial jogável

## Referência e diagnóstico

`reference_sheet.png` preserva a prancha enviada em 27/09/2026, sem alterações.
Ela é a referência canônica de design. Armadura escura/bronze, cabelo exposto,
máscara de barras, tecidos rasgados vermelhos, correntes e arma ensanguentada
orientam esta adaptação de gameplay.

O Player anterior já usava `scenes/player/visuals/carrasco_modular.tscn`:
21 peças transparentes retiradas de uma fonte de 256 × 256, Skeleton2D/Bone2D,
poses procedurais para idle, corrida, salto, dash e ataques. A fonte anterior
permanece em `assets/characters/carrasco_modular/approved_base.png` e todos os
seus arquivos foram preservados.

`PlayerVisualController` lê movimento, defesa e combate. Ele entrega `set_pose`
ao rig e espelha `VisualRoot` conforme a direção. O rig não move o Player, não
arma hitboxes e não determina duração, dano ou alcance dos ataques.

## Medidas na room aprovada

| Medida | Anterior | Forma Base inicial |
|---|---:|---:|
| Canvas do corpo | 256 × 256 | 256 × 384 |
| Altura visível da fonte, alpha ≥ 128 | 201 px | 367 px |
| Escala externa aplicada pela room | 0,34 | 0,34 |
| Escala interna de apresentação | 1 | 0,514 |
| Altura aproximada no mundo | 68,3 px | 64,1 px |
| Altura na tela, câmera 0,9 | 61,5 px | 57,7 px |
| Largura da nova silhueta, sem arma | — | 32 px no mundo / 29 px na tela |

Viewport: **960 × 540**. Zoom da câmera: **0,9**, preservado.
A nova forma ocupa aproximadamente 10,7% da altura da tela.
O ponto dos pés fica no eixo local do rig. Na room, `VisualRoot.y = 13`
continua alinhado ao fundo da cápsula existente: altura 64, raio 7, centro y=-19.
Nenhuma colisão foi reduzida para acompanhar o visual.

Filtering do novo personagem: **Linear**, para minificação da arte detalhada.
Armadura/cabeça recebem ganho local de 10% para leitura; tecidos e arma
mantêm sua intensidade. A modulação ambiental da room continua intacta.

## Arte usada

`cutout_source.png` e `weapon_source.png` são adaptações transparentes feitas
pela ferramenta de imagem a partir da prancha. **Não são extrações pixel a
pixel**: há pequenas diferenças de pose e microdetalhes. A prancha original
continua sendo a autoridade visual, e esta versão é uma prova inicial jogável.
Não foi gerada uma sequência de frames de animação.

`gameplay_base.png` é a fonte normalizada. `parts/` contém 20 regiões anatômicas
e uma arma separada. O processo determinístico de divisão está em
`tools/build_carrasco_base_official.gd`. Ele preserva a fonte e fornece três
pixels de sobreposição nas juntas. Pequenos preenchimentos escuros ficam
atrás da armadura para evitar fendas transparentes durante a articulação.

## Rig

Cena: `scenes/player/visuals/carrasco_base_official.tscn`.
Script: `scripts/player/visuals/carrasco_base_official.gd`.
O nome da raiz continua `CarrascoModular` para manter a integração da room.
São 22 Bone2D e 21 imagens funcionais.

```text
CarrascoModular
└── Skeleton2D
    └── Pelvis
        ├── Torso
        │   ├── Head
        │   ├── ArmLeft → ForearmLeft → HandLeft
        │   ├── ArmRight → ForearmRight → HandRight
        │   ├── CapeLeft / CapeRight / CapeCenter
        │   ├── ChainLeft / ChainRight
        │   └── Weapon → BloodiedWeapon
        ├── FrontCloth
        ├── ThighLeft → ShinLeft → BootLeft
        └── ThighRight → ShinRight → BootRight
```

Idle: respiração mínima e movimentos pequenos de tecido/correntes.
Run: ciclo contínuo próximo de 2,1 Hz, oposição de braços/pernas, inclinação
do tronco, bob controlado e atraso de tecidos/correntes.
Heavy attack: preparação, arco do golpe e recuperação acompanham as fases
e o progresso do `PlayerCombat` existente. A arma segue o ponto da mão direita.
Salto, queda e dash têm poses compatíveis para preservar a travessia.

Na locomoção, a arma fica atrás do manto com a mesma escala. Só pomo e cabo
ficam expostos; a lâmina é ocultada pela região de apresentação. Isso é uma
oclusão visual aproximada, não uma animação final de desembainhar.

Comparação reversível: desative `VisualRoot.official_base_enabled` para voltar
ao rig modular anterior. Desativar `modular_carrasco_enabled` ainda permite a
apresentação antiga por atlas. Não é necessário apagar assets ou trocar lógica.

## Controles preservados

- A/D ou setas: movimento.
- Espaço: salto.
- L: dash/esquiva.
- K: ataque pesado; manter pressionado usa a carga já existente.
- J: ataque leve; I: parry.

## Validação

Godot 4.7.2, renderização OpenGL Compatibility.

- `tests/capture_carrasco_base_official.gd`: capturas reais e gravação do Player;
  confirma montagem do rig e fases WINDUP, ACTIVE e RECOVERY do ataque pesado.
- `tests/verify_bosque_room.gd`: caminho principal, desnível, plataforma elevada,
  vão sem colisão, travessia com salto/dash e saída. Resultado: todas as condições
  verdadeiras, zero quedas.
- Fonte anterior, controller de movimento, física, recursos de ataque, câmera, cenário,
  vídeo e os 11 CollisionPolygon2D não foram editados nesta etapa.
- `tests/verify_milestone8_3.gd`: PASS; a apresentação anterior por atlas,
  troca de forma e valores de dano/postura continuam compatíveis.

## Limites e próximo acabamento

Esta base funciona tecnicamente e conserva a identidade principal. Ainda não
é animação final desenhada quadro a quadro. A fonte é uma pose única: as faces
ocultas da armadura não existem, e rotações extremas podem revelar a divisão
das peças. O manuseio da arma usa um socket de uma mão; falta refinar apoio da
segunda mão e a passagem da arma da cintura para combate. O alcance/dano
original permaneceu intacto e precisa de uma revisão visual de contato antes
de combate final com inimigos. Os microdetalhes da prancha não são legíveis
integralmente a 58 px de altura na câmera aberta.

Próximo passo: acabamento localizado de juntas, apoio das mãos e arco da arma,
seguido de revisão visual com a mesma câmera. Não exige novas evoluções,
inimigos, NPCs ou reconstrução do estágio.

## Prompts de adaptação (ferramenta integrada de imagem)

Corpo:
> Use case: background-extraction. Create a clean transparent gameplay sprite
> cutout from ONLY the fourth full-body figure labeled '3/4' in the provided
> character sheet. The body must match that figure closely: same 3/4 standing
> pose, dark exposed hair, vertical barred face mask, bronze-dark layered armor,
> gray front cloth with red emblem, torn dark red trailing strips, chains,
> greaves, boots. Keep the linework and proportions of the source figure. No
> weapon. Absolutely NO background of any kind: no black backdrop, no red
> glow/halo, no shadow, no floor, no extra canvas texture. Every pixel outside
> the physical character silhouette must have alpha zero, including gaps
> between limbs and cloth. No text, no other panels. Full character head to
> soles, centered.

Arma:
> Use case: background-extraction. Asset type: transparent 2D game weapon
> cutout. From the attached Carrasco — Forma Base sheet, isolate ONLY the single
> complete horizontal oversized bloodied cleaver/axe displayed in the ARMA
> section at lower right, including circular pommel, leather wrapped long grip,
> metal shaft, broad perforated blade and pointed tip. Keep its exact
> left-to-right orientation, proportions, bronze/steel/red pixel art detail and
> visual identity. Remove every label, guide, border, thumbnails and backdrop.
> No hand, no character, no new effects, no shadow or halo. Every pixel outside
> the physical weapon silhouette is transparent. Center full weapon with
> slight transparent padding.
