# Ruffle renderer repair

This is a custom build based on [Ruffle 0.7.1](https://github.com/ruffle-rs/ruffle/tree/89a7049965f3090e706265670df309a5128233ac), commit `89a7049965f3090e706265670df309a5128233ac`. Ruffle remains MIT/Apache-2.0 licensed; both licenses are included in `site/ruffle/`. This repository is not an official Ruffle release.

`renderer.patch` changes 13 Rust files. It retains the previous admission-bounded temporary GPU texture cache and extends conservatively bounded cached captures to eligible blur-only objects. Captures keep their original physical-pixel grid, guard, capture-origin invalidation and full blur dependency halo. A known local render-target clip handles nested captures; unrestricted bitmap draws and unsupported transform/filter/blend cases keep the original input. Active blur with an object's own scroll rectangle also falls back to the complete input.

An exact-content, device-local LRU shares immutable gradient textures (1,024 entries, full 1,024-byte RGBA keys). Uniforms, transforms, spread/interpolation, shaders and MSAA are unchanged. Exact scale-1 mesh reuse avoids registering a duplicate base mesh after a cache miss; nearest-scale selection is unchanged. The patch preserves pixel hit testing, original filters, HIGH quality and game timing. The game SWF and save format are unchanged.

## Rebuild

1. Check out the upstream commit above, then apply `renderer.patch` with `git apply` from the checkout root.
2. Use Rust 1.95.0 with `wasm32-unknown-unknown`, Node 24.22.2 and `wasm-bindgen-cli` 0.2.127. The source uses Rust edition 2024. In `web/`, run `npm ci`, then `npm run build --workspace=ruffle-core`. The tested build used `CARGO_BUILD_JOBS=1`, no `wasm-opt`, and the upstream lockfiles.
3. Preserve `web/packages/core/dist/ruffle_web_bg.wasm`. To remove private build-home paths, run this repository's `tools/sanitize-ruffle-build-paths.py INPUT.wasm OUTPUT.wasm [build-home-prefix]`. The output must be a new file. It replaces equal-length source-path strings only in data/custom sections and verifies executable-code section hashes are unchanged. Validate the output with `WebAssembly.validate`, then copy it into the core dist path for bundling.
4. From `web/`, run `npm run build --workspace=ruffle-selfhosted`. Do not rerun the core build after cleanup. Publish its JS/WASM and upstream licenses. Keep source changes available alongside the custom runtime.

[Provenance and exact tested hashes](../../site/ruffle/provenance.json) include raw tested source hashes and normalized-LF hashes. Build metadata and local paths can change full binary hashes on another machine. The published WASM is `723d56eddfc8a90b6c577a8aefaea7a1b59dcbc39fcc298ff83a14b831a23d84`; debug-path cleanup changed 440 data-section strings without changing executable code.

The patch applies cleanly to the upstream commit, and the applied source matches all 13 normalized-LF source hashes. Nine bounds/blur-margin tests and three exact-cache tests passed.

The idle-cache estimate is capped at 256 MiB, four entries per key and 64 recent keys. Active resources, game assets, staging buffers and driver memory are outside this estimate. [Measured gameplay, rendering and save checks](../../docs/performance.md) document benefits and remaining tails. This host-side repair requires the custom runtime; a SWF cannot force the Internet Archive's player to use it. Older hashed vendored files remain for rollback but are not requested by the current bootstrap.
