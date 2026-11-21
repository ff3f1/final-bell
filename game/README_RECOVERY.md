# Final Bell — recovered editable codebase (Godot 4.7.2)

**Status: editable development baseline, not a validated game build.**

## Recovered
- All **38** GDScript files from the 655,820,476-byte Windows export PCK were decompiled with GDRETools 2.7.4; tool reported **38/38 success, 0 errors**.
- Each of the 38 files compiled back to GDC using GDRETools bytecode revision `4.5.0-stable / ebc36a7`; this does **not** replace full Godot 4.7.2 editor/gameplay testing.
- All four shader files and the main scene path were restored. `scenes/main.tscn` comes from the earlier ZIP snapshot; the PCK main scene points to the same script and node structure.
- 13 FX PNGs were converted from the PCK, including the five textures preloaded by `MixamoRig`; GDRETools reported one lossy conversion.
- `project.godot` recovered with autoloads `Game` and `Sfx`, engine version Godot 4.7.2. `anim_info.json` preserved if present.

## Missing
- Original Blender projects and editable original Mixamo/GLTF character models are not included in this compact baseline. Compiled models and animations remain in the full original PCK.
- Music, environment assets, crowd textures and portraits are intentionally omitted for the compact baseline. The code has procedural character fallback if no GLTF/GLB assets are present; this has **not been run as a full fight**.
- Restoring all imported resources requires a separate GDRETools conversion pass; mass export was stopped during resource conversion, but per-resource conversion works.

## How to open on Windows
1. Install **Godot 4.7.2** (standard version) from https://godotengine.org/download/archive/4.7.2-stable/.
2. Open the Project Manager, choose **Import**, then pick `project.godot` in this extracted folder.
3. Let Godot reimport resources; run the scene (`F6`) or the project (`F5`) and inspect the debugger. Do not overwrite your original game export.
4. Test the menu and one fight, then save the error log if problems appear.

### Verified / not verified
- ✓ 38 recovered source files, 38 bytecode recompiles
- ✓ 13 restored FX images; four shader sources available
- ✓ Godot 4.7.2 project configuration, main scene, class names and autoload declarations
- ? Runtime/editor load, class resolution, shader rendering and GPU performance (requires standalone Godot 4.7.2)
- ? Complete high-fidelity 3D boxer assets (originals not recovered)

Check `RECOVERY_MANIFEST.json` for per-file SHA-256 checksums and provenance. All work is a preservation baseline. There is **no new Windows EXE** in this archive.
