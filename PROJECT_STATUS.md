# THE REFUSAL — PROJECT STATUS

Snapshot: **2026-09-28**, branch `main`. The repository root is this `the-refusal/` folder. The repository has local Git history (the audit found 10 prior commits) but no GitHub remote was configured at the time of this snapshot. The working checkout already contained the Bosque B/Player changes listed in the checkpoint; this documentation/LFS task did not change gameplay or Godot resources.

## Estado geral

Projeto **Godot 4** de action roguelite 2D dark fantasy. `project.godot` declares feature level `4.7`, a 960 × 540 viewport, and starts `res://scenes/biomes/forest/bosque_room_aprovada.tscn`. The checked-in project document for the official Carrasco base records a previous validation with Godot 4.7.2. No Godot runtime test was run as part of this Git organization task.

## Primeiro bioma

**Bosque dos Esquecidos / Bosque B.**

Sala principal selecionada no projeto:

`res://scenes/biomes/forest/bosque_room_aprovada.tscn`

`res://scenes/biomes/forest/bosque_trecho_01_playable.tscn` is also present as a playable slice. The approved room keeps the Bosque B artwork as its main composition and uses invisible `CollisionPolygon2D` nodes for walkable geometry. The approved room file contains **11 `CollisionPolygon2D` nodes**. Treat that geometry as accepted and do not rebuild it without finding a concrete defect.

## Cenário

The room and its playable route were previously validated in project work. The current scene combines approved environmental imagery with real collision polygons. PixelLab tile/building/path assets are additional content; they are not a replacement for the approved Bosque composition.

## Background

The approved room has a `BACKGROUND_VIDEO/VideoStreamPlayer` node using:

`res://assets/biomes/forest/approved/bosque_b_firefly_background.ogv`

The node autoplays, loops, and has its audio muted. The project copy is **34,455,717 bytes (32.86 MiB)**. Keep it as a project asset. The accepted quality-conversion pipeline was:

**original MP4 → FFV1 lossless intermediate → Ogg Theora, Quality 10 VBR**.

The OGV is in this repository’s working tree; the source MP4 and temporary FFV1 intermediate are outside the repository and are not part of this checkpoint. The source MP4 supplied earlier is located at `%USERPROFILE%/Downloads/Firefly Crie um vídeo em loop de 8 a 10 segundos usando exatamente a imagem enviada como base._Quero.mp4`.

## Câmera

Confirmed in `res://scripts/biomes/forest/bosque_room_aprovada.gd`: `Camera2D.zoom = Vector2(0.9, 0.9)`. The project viewport is **960 × 540**. The playable-slice script sets its own camera to `Vector2.ONE`; for the approved main stage, use the approved room values.

## Player / gameplay

The existing Player and controller scripts are:

- Player/input orchestration: `res://scripts/player/player.gd`
- Run, jump, gravity and coyote/buffer handling: `res://scripts/player/player_locomotion.gd`
- Attacks and charge/combo timing: `res://scripts/player/player_combat.gd`
- Dash, air dash and parry: `res://scripts/player/player_defense.gd`
- Visual state/controller integration: `res://scripts/player/player_visual_controller.gd`
- Player camera follow/impact: `res://scripts/player/player_camera.gd`
- Attack resource schema: `res://scripts/combat/attack_data.gd`
- Carrasco attack resources: `res://data/attacks/carrasco_heavy.tres`, `res://data/attacks/carrasco_charged_heavy.tres`, `res://data/attacks/carrasco_air_heavy.tres`, and related resources in `res://data/attacks/`

The current working tree already included edits to `project.godot`, `scenes/player/player.tscn`, `scenes/test_room.tscn`, `scripts/player/player_visual_controller.gd`, and `tests/verify_milestone8_3.gd`, plus new room/visual assets and scripts. They were preserved for the checkpoint; they were not made during this Git task. Review that checkpoint as the exact current project state.

## Pipeline 2D do Carrasco

The earlier frame-by-frame AI/GIF workflow and the cutout/Skeleton2D puppet approach are **not the final character-animation direction**. Existing 2D experiments, legacy atlases, cutouts and modular assets stay in the project as history/fallback; do not delete or treat them as the approved 3D production pipeline.

## Carrasco canônico

Canonical character direction: **CARRASCO — FORMA BASE**. Preserve the reference sheet, multi-view boards and weapon artwork. In-project references include:

- `res://assets/characters/carrasco_base_official/reference_sheet.png`
- `res://assets/characters/carrasco_approved_board/approved_concept.png`
- `res://docs/art_reference/carrasco_approved_animation_board.png`
- `res://docs/art_reference/carrasco_master_gameplay.png`
- `res://docs/art_reference/carrasco_official_evolution_board.png`
- `res://assets/characters/carrasco_base_official/weapon_source.png`

## Pipeline atual de personagens

The project remains a **2D game**. Current character-production direction:

**external 3D master → Blender → validated rig/deformation → animation → orthographic camera → transparent sprite renders → Godot 2D.**

## Blender

The portable **Blender 4.5.14 LTS** was previously validated outside this repository in background mode, with an orthographic camera, transparency, a 512 × 512 render, and save/reopen/re-render. The executable is in the separate Codex workspace at the separate Codex workspace’s `work/blender_portable/unpacked/blender-4.5.14-windows-x64/blender.exe`.

## Master 3D

The Tripo candidate files currently exist outside the Godot repository:

- Original high-poly visual master: `%USERPROFILE%/Downloads/fantasy armored knight 3d model.glb` — approximately **1,949,518 triangles**.
- Newer reduced, rigged candidate: `%USERPROFILE%/Downloads/fantasy+armored+knight+3d+model.glb` — **19,402 triangles**, 65 existing bones, no animation actions.

The newer candidate’s static appearance is close to the original, but its received weights make waist cloth/chains follow an elbow bend. Its hands remain closed fists. It is **not production rig-ready**. The candidate review, captures and Blender inspection files are in the separate Codex workspace at the separate Codex task workspace’s `outputs/tripo_candidate_02_validation/`, not in this game repository.

The preserved high-poly and the previous reduced/prep work files are in the separate Codex task workspace’s `outputs/carrasco_rig_prep_01/`. `Carrasco_RIG_PREP.blend` there is explicitly marked experimental/defective; do **not** use it to generate animation or sprites. No GLB/GLTF/FBX/Blend character master is currently in the Godot repository.

## Rig

The 2D cutout rig is not the final animation pipeline. Validate the bones and weights on the received 3D candidate; do not replace a received rig automatically. The current 19,402-triangle candidate’s armature is only a starting point: fix weights and joint deformations, separate the rigid armor and secondary-motion pieces, and prepare the hand before making production animations.

## Arma

The weapon must remain an independent asset, with an attachment/socket for the main hand and support for a second hand. The game repository contains the 2D reference/cutout `res://assets/characters/carrasco_base_official/weapon_source.png` and `parts/weapon.png`. The requested external weapon **FBX was not found** in the repository or the checked Downloads/Carrasco folders. A separate weapon reference image is present outside the project at `%USERPROFILE%/Downloads/Carrasco/MESHY/05_carrasco_arma_separada.png`.

## Próxima tarefa

1. Work from the two preserved Tripo files; keep the high-poly original immutable.
2. Correct and test the reduced candidate’s weights at elbow/shoulder and stop waist cloth/chains from following arm/finger bones.
3. Prepare real hand articulation and an A-pose without losing the approved silhouette.
4. Locate or receive the separate weapon model; prepare its attachment and second-hand support.
5. Only after the master/rig review gate, make a first run animation and inspect it from the orthographic camera.
6. Render transparent 2D sprites and then test them in Bosque B.

## NÃO REPETIR

Do not return to PixelLab or independent AI-generated frames as the character-animation solution, the rejected cutout puppet as the final character pipeline, or reconstructing Bosque B from large terrain/tile blocks. Do not use AVI/MJPEG as the video intermediate. Keep the approved room, video, collisions, camera and gameplay intact while working on the character.
