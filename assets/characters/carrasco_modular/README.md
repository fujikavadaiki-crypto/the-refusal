# Carrasco modular

`approved_base.png` is a byte-for-byte copy of the transparent 256 × 256 base
found as `pixellab-Create-a-single-playable-chara-1790430602936.png` on
26 September 2026. SHA-256:
`1c0651281fcbfd06b53908e167cd7488605eb549798fc2d0d89bd8569d696d9a`.
It is the local image matching the latest requested design: exposed dark hair,
barred mask, bronze armor, red torn cloth, chains, and axe.

`parts/` contains 21 transparent images derived from that source. The Godot
scene at `res://scenes/player/visuals/carrasco_modular.tscn` uses a Skeleton2D
and Bone2D pivot hierarchy. The axe has its own bone. During locomotion it
rests behind the waist; in idle and combat it returns to the grip position.

The source is a single flattened pose, so hidden sides of joints are absent.
The slicer reuses approved pixels for overlap at cuts and mirrors already
visible leg armor under the far leg. The rig supplies small, dark underpaint
behind joints and the torn skirt. These are functional fills, not new frames.

To regenerate the parts with Godot 4.7.2:

```text
godot --headless --path . --script res://tools/slice_carrasco_modular.gd
```

The Player visual adapter mounts this scene for the Carrasco base mask. Setting
`VisualRoot.modular_carrasco_enabled` to `false` retains the old atlas/GIF
presentation for comparison. Combat mechanics and mask data are unchanged.
