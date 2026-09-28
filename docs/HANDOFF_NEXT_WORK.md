# Retomada — THE REFUSAL

## Abra

- Projeto Godot: `the-refusal/project.godot` in the clone root
- Branch local atual: `main`
- Sala principal: `res://scenes/biomes/forest/bosque_room_aprovada.tscn`
- Status completo: [`PROJECT_STATUS.md`](../PROJECT_STATUS.md)

No momento da auditoria, ainda não havia remote GitHub configurado. O checkpoint local pode ser publicado assim que o usuário fornecer o repositório de destino.

## Estado

Bosque B está na sala aprovada com o OGV em loop e **11 colisões `CollisionPolygon2D`**. Câmera: zoom 0,9, viewport 960×540. O checkout tinha alterações existentes do Bosque/Player; elas foram preservadas para o checkpoint e não foram produzidas por esta tarefa.

O 3D é a direção atual do Carrasco. O master HIGH de ~1,95 milhão de triângulos e o GLB reduzido mais recente moram fora do repositório. O candidato de 19.402 triângulos preserva bem a aparência, mas os pesos deformam tecido/correntes indevidamente e as mãos seguem fechadas. A revisão completa e renders de defeito estão na pasta externa the separate Codex task workspace’s `outputs/tripo_candidate_02_validation/`. Os `.blend` experimentais na pasta irmã `outputs/carrasco_rig_prep_01/` incluem um `Carrasco_RIG_PREP.blend` marcado como defeituoso; não usar como rig pronto.

## Próxima ação

Continuar a validação/correção de weights do novo GLB em uma cópia de trabalho. Abrir `Carrasco_Candidate_02_Inspection.blend` para ver o candidato. Corrigir braços sem arrastar os tecidos e acessórios, validar ombro/cotovelo/joelho, preparar mão e A-pose. Só depois do gate de aprovação criar corrida; então render transparente e testar os sprites no Bosque B.

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
| Master 3D HIGH (fora do repo) | `%USERPROFILE%/Downloads/fantasy armored knight 3d model.glb` |
| GLB reduzido com rig recebido (fora do repo) | `%USERPROFILE%/Downloads/fantasy+armored+knight+3d+model.glb` |
| FBX da arma | Não localizado. Há `weapon_source.png` no projeto e referência PNG separada em `%USERPROFILE%/Downloads/Carrasco/MESHY/05_carrasco_arma_separada.png` |
| Inspeção Blender do GLB recente (fora do repo) | `separate Codex task workspace: outputs/tripo_candidate_02_validation/Carrasco_Candidate_02_Inspection.blend` |
| Relatório técnico do GLB (fora do repo) | `separate Codex task workspace: outputs/tripo_candidate_02_validation/CANDIDATE_02_REVIEW.md` |
| Blender portátil 4.5.14 (fora do repo) | separate Codex task workspace: `work/blender_portable/unpacked/blender-4.5.14-windows-x64/blender.exe` |

## Preservar

Não refazer Bosque B, vídeo, colisões, câmera ou controles. Não remover experiências 2D antigas. Não usar o rig recebido sem corrigir os pesos. Não gerar sprites/Idle/Run antes da validação e aprovação do master. Referência operacional: `PROJECT_STATUS.md`.
