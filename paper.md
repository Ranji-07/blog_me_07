# Resume paper animation backlog

Status: Phase 1 inspection is complete. No source frame has been rendered.

## Source

- Original: `Paper Crumple Animation/Paper Crumple.blend`
- License: CC0 / public domain
- Scene: frames 1–330 at 30 FPS
- Candidate paper deformation range: frames 151–290

## Next work

1. Create a working copy of the Blender file; never alter the original.
2. Recover the legacy cloth cache in the working copy by rebaking it.
3. Inspect frames 151–290 and record exact flat, first-crumple, and fully-crumpled frames.
4. Enable transparent film and hide the `Backdrop` only in the working copy.
5. Report the final selected range before rendering any assets.
6. Render the approved range as centered 768px RGBA PNG frames into `frontend/assets/animations/resume_paper/`.
7. Add the asset directory to `frontend/pubspec.yaml`.
8. Create a reusable Flutter frame player, then integrate it with resume open, close, and download flows.

## Compatibility note

Blender 5.2 cannot read the source's old cloth-cache compression. A working-copy rebake is required before the exact visual frame milestones can be confirmed.
