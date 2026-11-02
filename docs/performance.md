# Performance and verification

## Scope

Original game: 800 × 600, 30 FPS, ActionScript 3. Test system: Windows 11, Intel Iris Xe, Chrome 156.0.8078.76 and Firefox 159.0, stock Ruffle 0.7.1 (commit `89a7049965f3090e706265670df309a5128233ac`). Default tested backend: `wgpu-webgl`, HIGH quality. HD means a 1440 × 1080 presentation in a 1920 × 1144 viewport; rasterized original art is enlarged.

## Measured causes and changes

1. **Startup map generation.** The original drew individual island blobs into a 4640 × 2390 bitmap with separate offscreen passes. The historical baseline froze for over 300 seconds after New Game. The one-pass map build reached the world in roughly 8–13 seconds after New Game on this laptop; title asset loading is additional.
2. **Per-frame screen transfers.** Alternating GPU bitmap draws and CPU copies forced readbacks. Pooled stage objects and a screen-sized GPU map crop remove that screen readback loop. Original screen filters are retained, including the intro's residual zero-radius BlurFilter. A proposed bypass was rejected after pixel differences.
3. **Avatar land collision.** Phase probes isolated redundant stationary/shore scans. The conservative circle index and stationary fast path retain the original circle predicate and compiled blocked-step fallback. 300 deterministic movement/point comparisons passed without mismatches. Do not interpret different saved-scene CPU runs as a controlled whole-game speedup ratio.
4. **Local-save CPU work.** An early full 42 KB save caused roughly 181–344 ms stalls. Compact changing-state snapshots and avoiding repeated validation on freshly generated data reduced typical early-game saves to approximately 2–9 ms. Checksum/schema validation remains at the storage/import boundary.
5. **Menu pixel hit testing.** A synchronized CPU/GPU/API capture identified `BitmapData.hitTest → BitmapRawDataWrapper::sync → QueueSyncHandle::capture → getBufferSubData`. One readback took 9.3 ms; that menu capture had no browser long task. Ruffle already performs an exact bounds check before readback, so no redundant bounds patch or approximate hit test was introduced. A previous first-use GPU flush reached 80.8 ms; larger hitches are not claimed eliminated by this capture.

## Latest timing checkpoints

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

Additional current-candidate checks: a real worker drag to the sawmill saved its workplace ID and survived a full Chrome restart; a zero-wood/zero-gold snapshot restored without starter refill. Matching Firefox restart checks passed, including the exact workplace link, zero balances, and 300 movement comparisons. A 51-second Firefox walking/Save/Map scenario at HIGH/HD averaged 30.003 game FPS; actual update intervals were p95 35 ms, p99 37 ms, max 52 ms. A real Firefox storage-quota rejection preserved both the on-disk and in-memory good save; the temporary test filler was removed. The final hosted smoke test is recorded in the project handoff when completed. Full late-game/ending coverage is not claimed.

Screenshots, raw traces and private test backups remain in the ignored `.tools/candidate-high/` directory. Public game assets are not included here.

## Reproducing diagnostics

Use an isolated test browser/profile and the local server. Add `?bench=1&size=large` to enable observation callbacks. Keep the title/world loading period outside measurement windows.

```powershell
$env:CDP_PORT='9341'
node --experimental-websocket tools/cdp.mjs shot .tools/world-before.png
node --experimental-websocket tools/phase-bench.mjs .tools/world-phases
$env:NO_INLINE_SHOTS='1'
node --experimental-websocket tools/gameplay-scenario.mjs .tools/world-scenario
$env:GL_PROBE='1'
node --experimental-websocket tools/profile-menu.mjs .tools/menu Bunni
```

`tools/raf-probe.js` records both scheduled stamps and actual callback begin/end times. `tools/raf-control.mjs` navigates the **dedicated local test tab** to a blank reference and measures dispatch without Ruffle; save first.

Use full screenshots only. Cropped CDP captures previously collapsed the viewport to 1 × 1. View the screenshot to establish that the game world is running. Do not take screenshots inside timing windows: they can force readback. Do not run competing browser benchmarks. Detailed GPU decoder/service tracing produced artificial 233–600 ms stalls and is excluded from baseline results. A hidden normal tab may throttle to about 1 FPS.
