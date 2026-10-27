# Resume paper animation backlog

## Status

**Phase 1 — complete.** The source was inspected and a separate Blender 5.2 working copy was rebaked. No final Flutter animation assets have been exported.

## Source and working copy

- Original, unchanged: `Paper Crumple Animation/Paper Crumple.blend`
- Working copy: `blender/resume_paper/resume_paper_working.blend`
- Source license: CC0 / public domain
- Scene: frames 1–330 at 30 FPS
- Rendering tests: `blender/resume_paper/inspection/` (low-resolution frame-selection previews only)

## Verified paper motion

| Milestone | Frame | Notes |
| --- | ---: | --- |
| Flat paper | 1–40 | Flat sheet with only camera movement. |
| First visible crumple | 41 | The deformation starts naturally. |
| Strong crumple | 81–150 | The sheet folds quickly and is no longer usable as an unfolded resume. |
| Compact paper ball | 255 | First stable compact result suitable for the crumpled-paper state. |
| Stable paper ball | 255–330 | Minor movement only; frame 255 is the preferred endpoint. |

## Approved candidate range for review

- **Crumple:** frames **1 → 255**, sampled at 10 FPS for an approximately 2.55-second frame sequence.
- **Uncrumple:** reverse the same PNG sequence, **255 → 1**.
- The reverse playback is viable because the source begins as a clean, flat sheet and ends as a stable compact paper ball.

## Next work — pending frame-range approval

1. Render frames 1–255 in the working copy as centered 768px RGBA PNG frames into `frontend/assets/animations/resume_paper/`.
2. Register the asset directory in `frontend/pubspec.yaml`.
3. Build a reusable Flutter frame player.
4. Connect it to resume open, close, and download flows:
   - Open: paper ball → centre → reverse frames → resume sheet.
   - Close: resume sheet → crumple frames → bottom-right trash bin.
   - Download: resume sheet → crumple frames → upper-right exit.