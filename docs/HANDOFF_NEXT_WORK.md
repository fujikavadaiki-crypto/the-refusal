# Retomada — THE REFUSAL

## Abra

- Projeto Godot: `the-refusal/project.godot` in the clone root
- Branch local atual: `main`
- Sala principal: `res://scenes/biomes/forest/bosque_room_aprovada.tscn`
- Status completo: [`PROJECT_STATUS.md`](../PROJECT_STATUS.md)

Remote `origin` aponta para `https://github.com/fujikavadaiki-crypto/the-refusal.git`; branch `main` e tag do checkpoint foram publicadas. Os novos assets desta etapa devem ser publicados em `main` após o commit.

## Estado

Bosque B está na sala aprovada com o OGV em loop e **11 colisões `CollisionPolygon2D`**. Câmera: zoom 0,9, viewport 960×540. O checkout tinha alterações existentes do Bosque/Player; elas foram preservadas para o checkpoint e não foram produzidas por esta tarefa.

O 3D é a direção atual do Carrasco. O GLB reduzido com rig humanoide externo está agora versionado em `assets/characters/carrasco_3d/source/carrasco_forma_base_rigged.glb` (**19.402 triângulos, 65 ossos, sem actions de animação**). O candidato preserva bem a aparência, mas os pesos deformam tecido/correntes indevidamente e as mãos seguem fechadas. Ele precisa ser validado no Blender antes de criar outro rig. A arma oficial está separada em `assets/characters/carrasco_3d/weapon/carrasco_weapon.fbx`. A revisão completa e renders de defeito estão na pasta externa the separate Codex task workspace’s `outputs/tripo_candidate_02_validation/`. Os `.blend` experimentais na pasta irmã `outputs/carrasco_rig_prep_01/` incluem um `Carrasco_RIG_PREP.blend` marcado como defeituoso; não usar como rig pronto.

## Próxima ação

Importar o GLB e o FBX versionados no Blender. Validar o skeleton e os weights, deformações de ombros/cotovelos/joelhos, tecido/correntes, escala e attachment da arma. Corrigir somente defeitos confirmados em cópias de trabalho separadas, sem alterar os originais. Depois da validação do master, produzir a primeira corrida 3D. Ainda não integrar ao Godot antes dessa validação. O pipeline de personagem por cutout 2D foi rejeitado; não retomá-lo como solução final.

## Inventário real

| Recurso | Caminho |
|---|---|
| Projeto Godot | `project.godot` |
| Bosque B aprovado | `scenes/biomes/forest/bosque_room_aprovada.tscn` |
| Sala curta jogável | `scenes/biomes/forest/bosque_trecho_01_playable.tscn` |
| OGV de fundo (32,86 MiB) | `assets/biomes/forest/approved/bosque_b_firefly_background.ogv` |
| Player | `scenes/player/player.tscn`; `scripts/player/player.gd` |
| Movimento, dash/parry, combate/câmera | `scripts/player/player_locomotion.gd`, `player_defense.gd`, `player_combat.gd`, `player_camera.gd` |
| Controlador visual | `scripts/player/player_visual_controller.gd` |
| Forma 2D oficial atual/protótipo | `scenes/player/visuals/carrasco_base_official.tscn`, `scripts/player/visuals/carrasco_base_official.gd`, `assets/characters/carrasco_base_official/` |
| Rig modular 2D legado/fallback | `scenes/player/visuals/carrasco_modular.tscn`, `assets/characters/carrasco_modular/` |
| Tentativa anterior de sprites GIF | `assets/characters/carrasco_gif_test/` |
| Referência canônica e arma | `assets/characters/carrasco_base_official/reference_sheet.png`, `weapon_source.png`, `assets/characters/carrasco_approved_board/`, `docs/art_reference/` |
| GLB base rigado, candidato externo a master | `assets/characters/carrasco_3d/source/carrasco_forma_base_rigged.glb` |
| Arma oficial separada | `assets/characters/carrasco_3d/weapon/carrasco_weapon.fbx` |
| Master 3D HIGH preservado (fora do repo) | `%USERPROFILE%/Downloads/fantasy armored knight 3d model.glb` |
| GLB recebido original preservado (fora do repo) | `%USERPROFILE%/Downloads/fantasy+armored+knight+3d+model.glb` |
| Inspeção Blender do GLB recente (fora do repo) | `separate Codex task workspace: outputs/tripo_candidate_02_validation/Carrasco_Candidate_02_Inspection.blend` |
| Relatório técnico do GLB (fora do repo) | `separate Codex task workspace: outputs/tripo_candidate_02_validation/CANDIDATE_02_REVIEW.md` |
| Blender portátil 4.5.14 (fora do repo) | separate Codex task workspace: `work/blender_portable/unpacked/blender-4.5.14-windows-x64/blender.exe` |

## Preservar

Não refazer Bosque B, vídeo, colisões, câmera ou controles. Não remover experiências 2D antigas. Não usar o rig recebido sem corrigir os pesos. Não gerar sprites/Idle/Run antes da validação e aprovação do master. Referência operacional: `PROJECT_STATUS.md`.
