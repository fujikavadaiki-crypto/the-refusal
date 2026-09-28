# Retomada — THE REFUSAL

## Abra

- Projeto Godot: `the-refusal/project.godot` in the clone root
- Branch local atual: `main`
- Sala principal: `res://scenes/biomes/forest/bosque_room_aprovada.tscn`
- Status completo: [`PROJECT_STATUS.md`](../PROJECT_STATUS.md)

Remote `origin` aponta para `https://github.com/fujikavadaiki-crypto/the-refusal.git`; o checkpoint e a tag estão publicados. A entrega atual do Carrasco fica isolada em `feature/carrasco-animation-current`, sem merge em `main`.

## Estado

Bosque B permanece na sala aprovada com o OGV em loop e **11 colisões `CollisionPolygon2D`**. Câmera: zoom 0,9, viewport 960×540. Player/controller, câmera, cenário e gameplay não foram alterados nesta etapa.

O pipeline 3D → Blender → sprites 2D → Godot segue ativo. O GLB do Carrasco mantém seu rig humanoide Mixamo de **65 bones**; a arma oficial continua em FBX. A entrega técnica mais recente está em `work/carrasco_animation/current/`, incluindo `Carrasco_RUN_V2_CORRECTED.blend`, vídeos, capturas, relatório e dados de verificação.

RUN_V2_CORRECTED inclui um reparo geométrico local para a continuidade das pernas, ajustes na pose das mãos/arma e maior inclinação do tronco. **A corrida ainda não está aprovada visualmente; a biomecânica continua parecendo artificial.** Não continuar refinando manualmente esse ciclo como solução final. Preservar o rig atual, `WeaponSocket` e o reparo das pernas.

## Próxima ação

Usar uma animação humanoide de corrida já validada como base e retargetar para o rig Mixamo atual. Depois adaptar a postura, o peso e o porte da arma ao Carrasco, mantendo `WeaponSocket` e o reparo das pernas. O ciclo RUN_V2_CORRECTED serve como registro/comparação, não como solução biomecânica final. Preservar o pipeline Blender → sprites 2D → Godot e o Bosque B aprovado. O pipeline por cutout 2D/Skeleton2D foi rejeitado como solução final.

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
