# Performance and verification

## Scope

Original game: 800 x 600, 30 FPS, ActionScript 3. Test system: Windows 11, Intel Iris Xe, Chrome 156.0.8078.80 and Firefox 159.0.1, custom Ruffle renderer based on 0.7.1 (commit `89a7049965f3090e706265670df309a5128233ac`). Default tested backend: `wgpu-webgl`, HIGH quality. HD means a 1440 x 1080 presentation in a 1920 x 1144 viewport; rasterized original art is enlarged.

## November 5: cold-menu stalls and memory use

The previous published runtime still stalled on the first item card and pickup. Light browser/API tracing found a 108.67 ms GPU-process WebGL flush with only 1.459 ms thread CPU, while the main thread spent about 123.8 ms idle during a 147.8 ms callback gap. This shows waiting/descheduling, not 109 ms of measured GPU computation. Native kernel/system-call tracing was unavailable because of the earlier OS-policy denial; no kernel stack is claimed.

The rotating original card generated a 3,312 x 3,250 RGBA capture and matching 4x-MSAA renderbuffer, about 215 MiB combined, despite the 1,440 x 1,080 presentation. Its original white reveal animates BlurFilter strength from about 143 through 57 to zero. Nested placement blur also captured 3,027 x 1,449 pixels. The new runtime bounds eligible captures to the known target, preserving a conservative blur dependency halo, physical-pixel sampling grid, guard and original effects. Unsupported cases retain the original capture. Exact gradient sharing removes duplicate allocations: 5,845 uploads contained only 610 distinct 1,024-byte RGBA arrays. Exact scale-1 mesh reuse avoids another duplicate allocation.

Matched comparisons used fresh isolated profiles with the same copied save, unchanged game CWS/FWS/delta, HIGH, wgpu-webgl, DPR 1, a 1,920 x 1,144 viewport and a 1,440 x 1,080 player. The control was the November 3 deployed runtime, not stock Ruffle. Each cold window starts before the first item interaction and includes the original card effect, pickup and held placement for about 13.5 seconds. Screenshots were outside timing windows and show the real game world.

| Actual callback / memory measurement | November 3 control | November 5 candidate |
| --- | --- | --- |
| Chrome: cold-interaction browser worst | 199.8 ms | 32.5 ms |
| Firefox: cold-interaction browser worst | 437 ms | 52 ms |
| Chrome: moving-held-item browser p95 / worst | 17.5 / 32.4 ms | 17.7 / 31.8 ms |
| Firefox: moving-held-item browser p95 / worst | 19 / 34 ms | 19 / 34 ms |
| Chrome: isolated browser-tree private commit after interaction | 2,701.5 MiB | 2,399.8 MiB |
| Chrome: same measurement, GPU process private commit | 2,123.3 MiB | 1,834.1 MiB |

The cold stalls improved; repeated movement was comparable. Private commit is not resident RAM or GPU residency, and GPU counters must not be added to process totals. Earlier testing alongside another memory-heavy game had only about 292 MiB free and heavy paging. That pressure is a separate contributor, not proof of a Bunni memory leak. The improved runtime still uses substantial memory on this system.

The exact candidate then completed walking, two Save open/close cycles and two Map open/close cycles in each browser. Chrome's three real walking segments had game-update p95 36.0 / 36.8 / 36.9 ms and worst 48.5 / 50.3 / 46.2 ms. Firefox's had p95 36 / 36 / 36 ms and worst 56 / 49 / 52 ms. Actual movement was checked, not inferred from clicks or nominal FPS. Browser-frame maxima across those phases were 34.6 ms in Chrome and 39 ms in Firefox. Occasional game-update tails remain; this is not a zero-jitter claim.

All 33 deterministic rendering comparisons per browser were pixel-identical to the previous runtime: original card art and blur, nested/rotated/reflected/fractional captures, scroll-rectangle fallbacks, bitmap draws, masks, Multiply, gradient types/spread/ratio edges, and cache resize/filter transitions. Nine bounds/blur-kernel tests and three exact-cache tests passed. Full process restart without reseeding restored all 14 compared save categories in Chrome and Firefox, and actual Export UI downloads had valid checksums. The SWF, save code and format are unchanged.

Exact WASM SHA-256: `723d56eddfc8a90b6c577a8aefaea7a1b59dcbc39fcc298ff83a14b831a23d84`. [Source/build provenance](../site/ruffle/provenance.json) records all 13 source hashes and the binary. The patch was applied to a clean upstream file tree and its normalized source hashes matched. Privacy cleanup changed 440 source-path strings without changing executable code. Raw traces, full screenshots, copied saves and diagnostic harnesses remain private under the ignored `.tools/2026-11-05-lag/` directory. No full-ending or arbitrary-hardware coverage is claimed. Save and refresh an already-open page to load the update.

## Historical November 3 custom runtime: matched HD validation

After the earlier SWF repair, first interactions and held-item rendering still stalled. Browser/API profiling linked GPU readback waits to `BitmapData.hitTest -> BitmapRawDataWrapper::sync -> QueueSyncHandle::capture -> getBufferSubData`. A full-HD baseline measured one 617.7 ms readback. Held placement also repeatedly allocated oversized MSAA captures despite the clipped stage; the stalls could occur without long synchronous GL calls.

The [then-six-file renderer patch](../patches/ruffle/README.md) preserves filters, effects, exact pixel hit testing, HIGH quality, MSAA and the authored clock. It crops only conservatively eligible zero-blur cached captures on their original physical-pixel grid, with a guard and capture-origin invalidation. Temporary-texture reuse has bounded idle admission and weak per-target recent-draw history. One-shot/large bitmap draws keep the stock lifetime, avoiding an earlier rejected startup regression. No experimental scheduler, broad pixel prewarming or identity-filter bypass is shipped.

Fresh isolated Chrome 156 profiles used the same copied save, exact game SWF, `wgpu-webgl`, viewport 1920 x 1144, DPR 1 and actual 1440 x 1080 presentation at HIGH. No concurrent heavy benchmarks or screenshots occurred inside timing windows.

| Actual interval / allocation measurement | Stock-built control | Published custom candidate |
| --- | --- | --- |
| Held item, 20 seconds: new texture-storage calls | 1,116 | 0 |
| Held item: game interval p95 / p99 / worst | 133.4 / 154.2 / 191.8 ms | 34.8 / 35.5 / 37.4 ms |
| Held item: browser interval p95 / worst | 134.7 / 193.9 ms | 17.1 / 19.7 ms |
| Walking/Map/Save, 77 seconds: game p95 / p99 / worst | 48.4 / 62.2 / 91.1 ms | 39.1 / 48.7 / 56 ms |
| Same scenario: game intervals over 50.5 ms | 75 | 8 |
| Same scenario: browser p95 / p99 / worst | 27.6 / 43.8 / 67.8 ms | 17.2 / 28.4 / 48 ms |
| Same scenario: browser intervals over 50.5 ms | 15 | 0 |

The exact packaged runtime also completed Firefox 159's 77.6-second walking/two Save/three Map scenario at HIGH, viewport 1493 x 848, DPR 1.5, player 1045.32 x 783.98 CSS pixels: actual game p95/p99/worst 37/53/76 ms; actual browser 27/40/77 ms. This is a different presentation, not a cross-browser ratio. Startup with the fixed 35-second title-wait protocol remained about 50-52 seconds in control/candidate/restarts.

Both exact-package browsers passed full close/reopen without reseeding: avatar, balances, island/inventory, animals, NPC progress, tutorial, hearts, cards, bridges, quests and checksums restored. Actual Firefox Export UI downloaded a valid backup. Dynamic NPC positions, hunger and contextual hints continue normally. Thirteen rendering cases per browser were pixel-identical to the control, covering masks, blur, growing blur, multiply, bitmap draws and fractional clip/resize/rotation/filter transitions. An initial Firefox control capture before its first painted frame was rejected; four settled control/candidate captures with explicit colored-content checks matched. Fifteen focused Rust correctness tests passed.

The exact tested/published WASM SHA-256 is `ad9db6ce4bc4db575bcbeac75d3d87e0c38f399c8ac57f65d8486cecdcddf482`. [Build/source/artifact provenance](../site/ruffle/provenance.json) records all hashes. Privacy cleanup changed only equal-length source paths in WASM data, not executable code. The idle texture estimate cap is 256 MiB; active textures, game assets, staging buffers and driver memory are outside it.

Limits: an earlier same-source Firefox run had a 245 ms first-open Map browser gap (205 ms game gap), without a coincident slow GL call. It did not recur in the exact packaged repeat, but its cause remains unattributed. Readbacks still exist; zero jitter, every machine and complete ending/late-game coverage are not promised. Native WPR kernel recording was denied by OS profiling policy; browser/API traces were used instead. This repair requires the custom runtime on the host. The game SWF/delta/save format stay unchanged; save and refresh an already-open tab to load the update.

## Earlier November 3 SWF repair (stock runtime)

At that stage, the published build still stuttered in a progressed island scene. Short nominal-30-FPS samples had missed it. That SWF repair retained stock Ruffle, HIGH quality, the original zero-radius/nonzero screen filters, exact pixel item hit testing and the authored 30-FPS clock. No custom runtime was shipped at that earlier stage.

Two causes were isolated with alternating off/on comparisons in the same loaded scene, at viewport 1471 x 835, DPR 1.5, Windows 11 / Intel Iris Xe on AC:

| Comparison (eight seconds per condition) | Original path | Optimized path |
| --- | --- | --- |
| Map label objects created | 960 | 0 |
| New GPU textures during Map | 2,119-2,899 | 0-6 |
| Actual browser callback interval p95 during Map | 53.6-74.4 ms | 26.2-26.4 ms |
| World display-list logical bounds | 2,886 x 796, including offscreen fruit | 800 x 622 |
| Actual browser callback interval p95 during world culling A/B | 35.8-42.2 ms | 23.4-24.6 ms |

Both original and optimized paths could report about 30 game updates per second. The allocation counts and actual callback times reveal the presentation stalls. Per-item Map labels retain their original symbols, first-frame appearance, text and movement; text changes update the cached label. A weak dictionary leaves the inherited item instance layout unchanged. Bitmap culling uses a conservative affine-quad bounds check with a one-unit margin and skips no simulation updates.

The final source build passed Chrome full-browser restart at the saved avatar position, currencies, island contents, inventory, tutorial flags and collected progress. Firefox passed the same checks; its actual Export button downloaded a valid JSON backup. Dynamic NPC movement, animal hunger and contextual hints continue normally after loading; generated resource-tree layouts and runtime object IDs are reconstructed as before.

Final Chrome test: actual 1440 x 1080 presentation, viewport 1920 x 1144, DPR 1, HIGH; walking and Save/Map interactions averaged 29.995 game FPS, actual game intervals p95 45.3 ms / p99 55.1 ms / max 82.7 ms, browser intervals p95 16.9 ms / p99 33.5 ms / max 50.2 ms. Final Firefox walking/Save/Map: viewport 1471 x 835, DPR 1.5, HIGH; 29.964 game FPS, actual game intervals p95 55 ms / p99 69 ms / max 83 ms. These are different scenarios/presentations, not a cross-browser speed ratio.

A longer 97-second candidate interaction test, including first item-card opening and placement, averaged 29.88 game FPS but still contained longer tails. A `getBufferSubData` bitmap readback took 100.8 ms. The measured Map allocation storm and unnecessary offscreen work are fixed; all first-use or OS/driver hitches are not claimed eliminated. Save format and original effects are unchanged. Save and refresh an already-open tab to load an update.

## Historical measurements (November 2)

1. **Startup map generation.** The original drew individual island blobs into a 4640 x 2390 bitmap with separate offscreen passes. The historical Chrome/WebGPU baseline froze for over 300 seconds after New Game; this is not a matched-backend speedup ratio. The one-pass map build reached the world in roughly 8-13 seconds after New Game on this laptop; title asset loading is additional.
2. **Per-frame screen transfers.** Alternating GPU bitmap draws and CPU copies forced readbacks. Pooled stage objects and a screen-sized GPU map crop remove that screen readback loop. Original screen filters are retained, including the intro's residual zero-radius BlurFilter. A proposed bypass was rejected after pixel differences.
3. **Avatar land collision.** Phase probes isolated redundant stationary/shore scans. The conservative circle index and stationary fast path retain the original circle predicate and compiled blocked-step fallback. 300 deterministic movement/point comparisons passed without mismatches. Do not interpret different saved-scene CPU runs as a controlled whole-game speedup ratio.
4. **Local-save CPU work.** An early full 42 KB save caused roughly 181-344 ms stalls. Compact changing-state snapshots and avoiding repeated validation on freshly generated data reduced typical early-game saves to approximately 2-9 ms. Checksum/schema validation remains at the storage/import boundary.
5. **Menu pixel hit testing.** A synchronized CPU/GPU/API capture identified `BitmapData.hitTest -> BitmapRawDataWrapper::sync -> QueueSyncHandle::capture -> getBufferSubData`. One readback took 9.3 ms; that menu capture had no browser long task. Ruffle already performs an exact bounds check before readback, so no redundant bounds patch or approximate hit test was introduced. A previous first-use GPU flush reached 80.8 ms; larger hitches are not claimed eliminated by this capture.

## Historical timing checkpoints (November 2)

| Test | Result |
| --- | --- |
| Chrome, 20 seconds, stock runtime, HIGH/HD | 600 world updates; scheduled game intervals p95 33.5 ms, p99 33.7 ms, max 33.8 ms |
| Chrome, 37 seconds standing/walking, HIGH/HD | 1,113 measured updates; update CPU p95 1.8 ms, p99 5.8 ms, max 10.6 ms |
| Same 37-second run, actual wall-clock update starts | p95 47.9 ms, p99 49.1 ms, max 50.7 ms |
| Blank-page reference, no Ruffle/game, 20 seconds | actual every-second-RAF interval p95 34.1 ms, p99 47.5 ms, max 48.9 ms |

Scheduled RAF timestamps and actual callback arrival times differ. A smooth timestamp sequence alone is insufficient evidence of smooth presentation. The blank reference establishes that Bunni is not required for every observed refresh-sized delay; it does not prove every gameplay hitch is external.

The experimental 0.5 ms Ruffle accumulator tolerance did not establish a reliable benefit and is **not shipped**. Stock WASMs are retained. Native Windows WPR CPU/GPU capture was denied by OS profiling policy (`0xc5585011`); no kernel/system-call trace is claimed. Browser CPU/GPU/API traces were used instead.

## Gameplay and persistence checks

Checked on Chrome and Firefox: startup, walking, original-quality tree-card dismissal/resume, forest placement, local save/Continue, browser close/reopen, avatar position, currencies, placed sawmill/house/forest, worker-follow state, pending heart restoration, and a real clicked heart resuming once without duplicate cards. Chrome additionally passed a real file-picker backup export/import and corrupt-backup rejection without changing the good record.

Additional current-candidate checks: a real worker drag to the sawmill saved its workplace ID and survived a full Chrome restart; a zero-wood/zero-gold snapshot restored without starter refill. Matching Firefox restart checks passed, including the exact workplace link, zero balances, and 300 movement comparisons. A 51-second Firefox walking/Save/Map scenario at HIGH/HD averaged 30.003 game FPS; actual update intervals were p95 35 ms, p99 37 ms, max 52 ms. A real Firefox storage-quota rejection preserved both the on-disk and in-memory good save; the temporary test filler was removed. Previous-good-record recovery passed after corrupting only the current checksum in an isolated test slot. Native-size final-release smoke tests at 878 x 664 measured 30.02 game FPS in Firefox and 30.01 in Chrome, with valid local saves. The public GitHub Pages build passed real-world startup, Save UI and full-browser restart in both browsers: Firefox at 800 x 600 / viewport 878 x 664; Chrome at 1440 x 1080 / viewport 1920 x 1144. Both hosted 12-second world samples measured 30.01 game FPS. Avatar position, balances, tutorial progress and the forest bubble matched before/after restart. Chrome also passed the real production Save/Export UI with `allowScriptAccess:false`; the downloaded backup checksum was verified. These short hosted smoke tests supplement the longer local scenarios above. Full late-game/ending coverage is not claimed.

Screenshots, raw traces and private test backups remain in the ignored `.tools/candidate-high/` and `.tools/2026-11-03-real-lag/` directories. Public game assets are not included here.

## Reproducing diagnostics

Use an isolated test browser/profile and the local server. Add `?bench=1&size=large` to enable observation callbacks. Keep the title/world loading period outside measurement windows.

```powershell
$env:CDP_PORT='9341'
node --experimental-websocket tools/cdp.mjs shot .tools/world-before.png
node --experimental-websocket tools/phase-bench.mjs .tools/world-phases
node --experimental-websocket tools/render-cache-ab.mjs labels .tools/map-ab
node --experimental-websocket tools/render-cache-ab.mjs cull .tools/cull-ab
$env:NO_INLINE_SHOTS='1'
node --experimental-websocket tools/gameplay-scenario.mjs .tools/world-scenario
$env:GL_PROBE='1'
node --experimental-websocket tools/profile-menu.mjs .tools/menu Bunni
```

`tools/raf-probe.js` records both scheduled stamps and actual callback begin/end times. `tools/raf-control.mjs` navigates the **dedicated local test tab** to a blank reference and measures dispatch without Ruffle; save first.

Use full screenshots only. Cropped CDP captures previously collapsed the viewport to 1 x 1. View the screenshot to establish that the game world is running. Do not take screenshots inside timing windows: they can force readback. Do not run competing browser benchmarks. Detailed GPU decoder/service tracing produced artificial 233-600 ms stalls and is excluded from baseline results. A hidden normal tab may throttle to about 1 FPS.

## Published release

[Original presentation](https://chromiteexabyte.github.io/bunni-fast/?size=original) | [Larger presentation](https://chromiteexabyte.github.io/bunni-fast/?size=large). [Initial successful deployment](https://github.com/ChromiteExabyte/bunni-fast/actions/runs/41417729919), code commit `d20ffa9d957bcf0ae6200f5906fb59bbcb44be45`.

Patched local CWS SHA-256: `c59866f927909a534a53c624a40163dab6556869da6d928c48d8cc3c236ee59c`. Browser FWS: 1,394,917 bytes; delta: 82,805 bytes. Recompiling the final sources produced the same CWS hash. Both stock Ruffle WASMs were hash-checked against the original vendored binaries. The hosted full-SWF URL returns 404; only the patch and emulator are published.
