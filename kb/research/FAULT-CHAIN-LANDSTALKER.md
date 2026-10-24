# Fault Chain Documentation — GTA SA Landstalker GL Render (2026-10-11)

## Summary
Built a ps5-native OpenGL app that renders the GTA SA Landstalker SUV on PS5 hardware GPU via
ps5-opengl (GL 4.6 Mesa/Gallium). The car went through multiple visual fault stages before
reaching current "looks like a car" state. Each fault is documented below with root cause,
diagnosis method, and fix.

---

## Fault 1: BLACK SCREEN (no render at all)
**Symptom:** Console showed nothing — app launched but displayed black.
**Root cause:** Comma-operator bug in EGL init. Code inserted `!f(...), g(...)` in an
`eglInitialize` call — the comma operator evaluated `f()` (init) successfully then evaluated
`g()` which returned 1, causing `return 1` (error exit). Init succeeded but app exited before
rendering.
**Diagnosis:** Added debug prints to EGL init sequence. Found init calls succeeding but
returning early.
**Fix:** Removed the comma-operator hack. Used the canonical pattern from
`ps5-opengl/examples/core33-triangle/main.c` (straight-line `eglInitialize` → `eglGetDisplay`).
**Files:** `sa_gl_app.cpp` EGL init block.

## Fault 2: GARISH/FLAT TEXTURES (RGB static)
**Symptom:** Car rendered but textures looked like random noise/static — no recognizable surfaces.
**Root cause:** Custom DXT1 (S3TC) decompressor produced wrong colors. The decompressor passed
the S3TC spec but had a byte-swapping bug in the 4×4 block decode (RGB values swapped).
**Diagnosis:** Compared decompressed output against known texture content (librw decode).
The output was RGB static — deterministic garbage.
**Fix:** Replaced custom DXT1 decompressor with the S3TC reference implementation from
`sa_raster.c` (which was already validated against the original game).
**Files:** `sa_raster.c` DXT1 decode function.

## Fault 3: MISSING TEXTURES (green/pink fallback)
**Symptom:** Some surfaces showed solid green or pink instead of textures. One texture (paint)
was green.
**Root cause:** Actually TWO separate issues:
  a) **Missing vehicle.txd textures** — 10 of 11 textures come from `models/generic/vehicle.txd`
     (a loose file, NOT in gta3.img). The loader only looked in gta3.img. Fixed by adding
     vehicle.txd parsing.
  b) **Green paint = carcols sentinel** — The DFF stores `(60,255,0)` as a placeholder color
     for the primary paint slot. GTA SA replaces it at runtime from `carcols.dat` (8 combos
     for Landstalker). Our app rendered the placeholder literally. Fixed by `apply_paint_slots()`
     which remaps (60,255,0)→midnight-blue (38,55,57) and (255,0,175)→white (245,245,245).
**Diagnosis:** m1_paint agent verified all 11 textures load (file sizes, MD5, paths). The
green persisted even with textures confirmed loading → the color was coming from the material
table, not a texture failure. Cross-referenced with re3 source: `GetEditableMaterialListCB`
maps `0x3C,0xFF,0` → forced white, then carcols replacement.
**Fix:** (a) vehicle.txd loader added. (b) `apply_paint_slots()` added after `load_manifest()`.
**Files:** `sa_gl_app.cpp` texture loading, `sa_txd.c` vehicle.txd parser, `apply_paint_slots()`.

## Fault 4: WHEELS LOOKED BOXY/SQUARE
**Symptom:** Wheels rendered as flat diamonds/squares instead of round tires.
**Root cause:** TWO issues:
  a) **chassis_vlo (geom 0) occluded wheels** — The low-detail chassis LOD draws flat
     4-triangle diamond fans at x=±1.040 (outboard of the real wheel at x≤1.009). These
     diamonds sat in front of the wheels, making them invisible or boxy.
  b) **Only 1 wheel instance** — The DFF contains 1 wheel geometry (geom 25) at FR position.
     SA instances wheels at 4 `wheel_*_dummy` frames at runtime. We only rendered FR.
**Diagnosis:** m4_wheels agent analyzed vertex data: geom 25 is a correct 12-facet cylinder
(round), but geom 0's diamond fans were drawn on top. Only 1 of 4 wheel positions had tris.
**Fix:** (a) Dropped chassis_vlo from merge (3190→2785 tris). (b) Instanced wheel geom 25
at all 4 dummy positions (FR, FL, RR, RL) with 180° Z-rotation for left side. (c) Dropped
`*_dam` variants (11 parts, 717 tris) to stop z-fighting.
**Files:** `make_landstal_bin.py` (model generator), `landstal_model.bin` (regenerated).

## Fault 5: WINDSHIELD/GLASS TOO DARK
**Symptom:** Windshield and windows appeared nearly black.
**Root cause:** TWO issues:
  a) **Low alpha in vehicleshatter128** — Mean alpha 0.36 (70% of texels a≈0.2). With
     `SRC_ALPHA/ONE_MINUS_SRC_ALPHA` blending, 82% of each pixel was dark background.
  b) **No sky-lift or depth-mask** — Dark navy clear color showed through the translucent glass.
     Coplanar glass strips self-occluded without depth-mask.
**Diagnosis:** m3_color agent measured texture alpha statistics and verified blend state.
**Fix:** (a) `glDepthMask(GL_FALSE)` in blend pass. (b) Sky-lift clear color to (0.25,0.35,0.45).
(c) Blend coverage from `u_color.a` instead of `tex.a*mat.a` (windshield 0.18→0.95).
(d) Ambient lift `c.rgb *= 1.2` in fragment shader.
**Files:** `sa_gl_app.cpp` blend pass + fragment shader.

## Fault 6: CAMERA EXPOSURE (operational, not code)
**Symptom:** User's PC camera (cv2 index 1) captured too-dark images (mean 2-3).
**Root cause:** Camera exposure/gain settings not tuned for TV screen capture. Previous
settings (AUTO_EXPOSURE=1, EXPOSURE=-8, GAIN=0) produced mean 3-6.
**Fix:** Adjusted to EXPOSURE=-6, GAIN=30, BRIGHTNESS=80, CONTRAST=50 → mean 9-10.
**Files:** `build/render_test/capture.py` (updated settings).

---

## Current State (v2 deployment)
- Paint: midnight-blue (38,55,57) with grunge streaks ✅
- 4 wheels: round, with spokes, at correct positions ✅
- Windshield: lighter (sky-lift + blend coverage) ✅
- Brown side trim, white grille/bumper, dark windows ✅
- Spinning on PS5 hardware GPU (GL 4.6, 3840×2160) ✅
- No z-fighting (dam variants removed) ✅

## Remaining Known Items
- Real wheel DFFs extracted (`wheel_gn1/or1/sr1.bin`) but not yet swapped in — current wheels
  are the 12-facet cylinder from landstal.dff (looks correct but low-poly).
- sRGB vs linear color-space question open (aborted agent).
- Full world streaming (IDE/IPL), camera/physics, SAMP client — future phases.
