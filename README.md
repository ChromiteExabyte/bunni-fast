# Bunni: How We First Met - browser preservation patch

A patch for the Internet Archive's copy of LunaDrift's 2009 Flash game, running in modern browsers under [Ruffle](https://ruffle.rs).

**Play in your browser:** [original size](https://chromiteexabyte.github.io/bunni-fast/?size=original) | [larger 4:3 presentation](https://chromiteexabyte.github.io/bunni-fast/?size=large). Nothing to install.

The target is the original **30 game updates per second**, at **HIGH quality** with the original animation and timer pacing. The larger presentation is **1440 x 1080**, keeping the original 4:3 aspect ratio. Existing bitmap artwork is enlarged; this does not replace it with new HD artwork.

## What changes

- Build the island map in one GPU pass instead of thousands of separate bitmap draws.
- Render the world through pooled display objects and a bounded map viewport, avoiding repeated screen-bitmap GPU/CPU transfers and huge filtered textures.
- Reuse original Map label artwork instead of recreating text/vector objects every frame. Skip fully offscreen bitmap quads before the screen filter.
- Use a documented custom Ruffle renderer to bound cached captures and reuse temporary GPU textures, reducing allocation stalls without dropping filters or quality. [Source and build provenance](patches/ruffle/README.md).
- Accelerate avatar land queries with a conservative spatial index. Keep the original compiled shore-movement fallback and exact circle predicate.
- Replace the unavailable account-server save flow with browser-local saves, autosaving every 15 seconds between complete, unpaused updates. Manual **Save** also exports/imports portable JSON backups.
- Use Ruffle's `wgpu-webgl` backend by default. On the tested system, WebGPU had a Firefox staging-buffer panic and a Chrome bitmap readback stall. The SWF alone cannot select a host player's backend.

The authored SWF remains **800 x 600 / 30 FPS / AS3**. Rendering quality, original effects, pixel-based item hit testing, animation rates and movement speeds are retained.

## Playing and saving

Serve `site/` over HTTP, then open the page:

```bash
python -m http.server 8137 --directory site
```

- Original presentation: `http://localhost:8137/?size=original`
- Larger presentation: `http://localhost:8137/?size=large`

Wait for the title's artwork to load before choosing New Game or Continue. The first load can take about 20-35 seconds on the tested laptop.

Saves belong to the current browser, profile and website address. Choose **Continue** in the same slot next time. Use **Save -> Export backup** before switching browsers or addresses. **Import backup** validates the file, preserves the previous good record, then asks you to reload and Continue. Clearing site data removes browser saves.

Local records include placed items, inventory, workers and job links, balances, avatar position, tutorial/quest progress, collected cards/hearts, bridges and pending heart animations. As in the original save loader, generated forest children are reconstructed; individual resource-tree layouts are not identical after reloading. Online sharing, forums, account login and purchases from the retired service are not restored.

## Verification and limits

Tests use actual game-world screenshots, valid viewports and game-update counters, not the title-screen browser FPS. See [the performance and verification notes](docs/performance.md).

Chrome 156 and Firefox 159 on Windows 11 / Intel Iris Xe have been tested at HIGH quality using `wgpu-webgl`. Persistent progress, browser restarts, portable backups and heart-animation recovery were checked. The released patch also passed 300 movement comparisons against the original compiled movement method with zero mismatches.

Matched comparisons found a Map-label allocation storm: the original path created 960 label objects and over 2,100 GPU textures in eight seconds. Reusing the same artwork reduced both to almost zero and improved actual browser frame p95 from 54-74 ms to about 26 ms at the same HIGH quality. Offscreen culling also reduced oversized filtered bounds. The final Chrome 1440 x 1080 walking/menu test averaged 30.00 game FPS; Firefox averaged 29.96 in its final scenario. Both passed full browser restart and save checks.

The subsequent custom-runtime repair reduced matched Chrome 1440 x 1080 held-item game-frame p95 from 133.4 to 34.8 ms. A 77-second walking/Map/Save comparison improved game p95 from 48.4 to 39.1 ms and worst from 91.1 to 56 ms. Both browsers passed full restart/save checks and 13 rendering comparisons each. Occasional longer frames remain: an earlier same-source Firefox run had a 245 ms first-Map browser gap that did not recur in the final packaged-runtime repeat. This is not a guarantee of zero jitter or a full-game completion test. After an update, **Save, then refresh** the existing page to load the new code. Save records keep their existing format.

## Building

Needs Java 8+, Python 3, Git Bash, and Node 20+ for browser diagnostics.

```bash
bash tools/setup.sh
python tools/build.py
node tools/verify-web-patch.mjs
```

`tools/setup.sh` downloads the preserved originals, FFDec 26.4.0 and Ruffle 0.7.1. Originals are kept unchanged; setup preserves the existing vendored runtime. The published player uses the [custom renderer build](patches/ruffle/README.md), based on Ruffle 0.7.1, with exact hashes in `site/ruffle/provenance.json`. `tools/build.py` recompiles `patches/as3/`, writes the local patched SWF and generates the browser patch.

The published player fetches original game files from the [Internet Archive item](https://archive.org/details/bunnibunni), verifies their SHA-256 and applies a checked binary delta in memory. Original SWFs/XML and the complete patched SWF are excluded from Git. This repository does not claim a redistribution license for the game; abandonware status is not a license. Availability of the original files and Archive CORS remains an external dependency.

## Credits and licenses

Game: LunaDrift / bunnibunni.com, 2009. Preserved original: Internet Archive item `bunnibunni`. Emulator: [Ruffle](https://github.com/ruffle-rs/ruffle), with a [documented custom renderer patch](patches/ruffle/README.md) and its MIT/Apache-2.0 licenses included under `site/ruffle/`. Decompiler/compiler: [JPEXS FFDec](https://github.com/jindrapetrik/jpexs-decompiler). No game-asset license is granted by this repository.
