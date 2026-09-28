# THE REFUSAL — PROJECT STATUS

Snapshot: **2026-09-28**, branch `main`. The repository root is this `the-refusal/` folder. GitHub remote `origin` points to `https://github.com/fujikavadaiki-crypto/the-refusal.git`; checkpoint `main` is published there. This asset-ingestion task does not change gameplay or Godot resources.

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

The earlier frame-by-frame AI/GIF workflow and the cutout/Skeleton2D puppet approach were **rejected as the final character-animation pipeline**. Existing 2D experiments, legacy atlases, cutouts and modular assets stay in the project as history/fallback; do not delete or treat them as the approved 3D production pipeline.

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

The high-poly visual master and experimental Blender prep remain outside the Godot repository. The current externally rigged candidate is now versioned in the repository at:

- `assets/characters/carrasco_3d/source/carrasco_forma_base_rigged.glb`
- `assets/characters/carrasco_3d/weapon/carrasco_weapon.fbx`

The GLB is the current rigged Carrasco base candidate, in GLB format, with the externally supplied humanoid rig. The separate FBX is the approved Carrasco weapon. Both binary assets are tracked by Git LFS.

Original candidate files used for this copy:

- Original high-poly visual master: `%USERPROFILE%/Downloads/fantasy armored knight 3d model.glb` — approximately **1,949,518 triangles**.
- Newer reduced, rigged candidate: `%USERPROFILE%/Downloads/fantasy+armored+knight+3d+model.glb` — **19,402 triangles**, 65 existing bones, no animation actions. The repository copy preserves these source bytes unchanged.

The newer candidate’s static appearance is close to the original, but its received weights make waist cloth/chains follow an elbow bend. Its hands remain closed fists. It is **not production rig-ready**. The candidate review, captures and Blender inspection files are in the separate Codex workspace at the separate Codex task workspace’s `outputs/tripo_candidate_02_validation/`, not in this game repository.

The preserved high-poly and the previous reduced/prep work files are in the separate Codex task workspace’s `outputs/carrasco_rig_prep_01/`. `Carrasco_RIG_PREP.blend` there is explicitly marked experimental/defective; do **not** use it to generate animation or sprites.

## Rig

The 2D cutout rig was rejected as the final animation pipeline. The external Mixamo armature on the repository GLB was validated and retained with **65 bones**. The current Blender work and its evaluation are documented below under **RUN_V2_CORRECTED**. Keep that rig, `WeaponSocket`, the leg continuity repair, and the existing Blender → 2D sprites → Godot pipeline.

## Arma

The approved weapon is available independently as `assets/characters/carrasco_3d/weapon/carrasco_weapon.fbx`. The existing 2D reference/cutout remains at `res://assets/characters/carrasco_base_official/weapon_source.png` and `parts/weapon.png`. Import the FBX into Blender with the GLB and validate scale, orientation and hand attachment; keep the source FBX unchanged.

## Próxima tarefa

1. Do not keep manually refining RUN_V2 as the final biomechanical solution; its run remains visually unapproved and reads artificially.
2. Start from a humanoid run animation that has already been validated, then retarget it to the current 65-bone Mixamo rig.
3. Adapt the retargeted motion for Carrasco's weight, forward posture, and weapon carry. Preserve `WeaponSocket` and the leg continuity repair.
4. Continue the existing Blender → transparent 2D sprites → Godot pipeline. Keep the Godot integration and gameplay intact while validating the animation.

## RUN_V2_CORRECTED — estado corrente

The current Blender delivery and review material are in `work/carrasco_animation/current/` on branch `feature/carrasco-animation-current`.

- `RUN_V2_CORRECTED` exists as a separate action and Blender working file. The original RUN_V2 action, 65-bone Mixamo rig, `WeaponSocket`, ground point, and original GLB/FBX remain preserved.
- A local opaque inner surface repairs the visible leg openings. The pose of the arms, hands, and carried weapon was adjusted, and the torso received a modest increase in forward lean.
- **The run is not visually approved. Its biomechanics still look artificial.** Do not continue manual polishing of this run as the final solution.
- Recommended next step: retarget a previously validated humanoid run to the existing rig, then adapt posture, weight, and weapon carry.
- The delivery includes the Blender file, before/after videos, captures, report, and verification data. See `work/carrasco_animation/current/RUN_CORRECTION_REPORT.md` and `RUN_CORRECTION_REVIEW.html`.
- This work did not change Godot, Bosque B, Player/controller, camera, collisions, or gameplay.

## NÃO REPETIR

Do not return to PixelLab or independent AI-generated frames as the character-animation solution, the rejected cutout puppet as the final character pipeline, or reconstructing Bosque B from large terrain/tile blocks. Do not use AVI/MJPEG as the video intermediate. Keep the approved room, video, collisions, camera and gameplay intact while working on the character.
