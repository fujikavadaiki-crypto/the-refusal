# Carrasco GIF gameplay trial

These are the exact GIFs supplied for the September 2026 gameplay test. The five
side-view clips are copied unchanged in `source_gifs/`; the two extra direction
GIFs are retained there as references only. This trial does not replace the
previous `carrasco_base_gameplay` atlas.

Each GIF frame was exported to a full-size RGBA PNG without cropping, resizing,
interpolation, or recoloring opaque pixels. The source GIFs already have binary
transparency and no opaque green pixels. Fully transparent green RGB values were
normalized to transparent black. `frames.json` records the source hashes, frame
counts, native canvas sizes, playback rates, and ground anchors.

| State | Source frames | Playback | Direction |
| --- | ---: | ---: | --- |
| Idle | 9 | 6 FPS | East; mirrored west |
| Walk | 6 | 8 FPS | East; mirrored west |
| Run | 8 per side | 12 FPS | Original east and west GIFs |
| Jump | 0–4 of 9 | 15 FPS | East; mirrored west |
| Fall | 5–8 of 9 | 15 FPS | Jump GIF reused; mirrored west |

The frame anchor follows each frame's lowest opaque row so the character stays
grounded while the physics body remains unchanged. The Sprite2D uses native 1x
pixel size and nearest filtering; Godot import uses lossless compression and no
mipmaps. Combat and other states continue using the older atlas until approved
animation assets exist.
