# Ruffle renderer repair

This is a custom build based on [Ruffle 0.7.1](https://github.com/ruffle-rs/ruffle/tree/89a7049965f3090e706265670df309a5128233ac), commit `89a7049965f3090e706265670df309a5128233ac`. Ruffle remains MIT/Apache-2.0 licensed; both licenses are included in `site/ruffle/`. This repository is not an official Ruffle release.

`renderer.patch` changes six Rust files. It bounds eligible zero-blur cached captures on their original physical-pixel grid with a guard, preserves capture-origin dirtiness, and reuses temporary GPU textures through an admission-bounded idle cache. Per-target weak draw history admits recurring bitmap draws; one-time and large draws keep the original resource lifetime. It keeps original filters, blending, MSAA and game timing. It does not bypass pixel hit testing or modify the scheduler. The game SWF and save format are unchanged.

## Rebuild

1. Check out the upstream commit above, then apply `renderer.patch` with `git apply` from the checkout root.
2. Use Rust 1.95.0 with `wasm32-unknown-unknown`, Node 24.22.2 and `wasm-bindgen-cli` 0.2.127. The source uses Rust edition 2024. In `web/`, run `npm ci`, then `npm run build --workspace=ruffle-core`. The tested build used `CARGO_BUILD_JOBS=2`, no `wasm-opt`, and the upstream lockfiles.
3. Preserve `web/packages/core/dist/ruffle_web_bg.wasm`. To remove private build-home paths, run this repository's `tools/sanitize-ruffle-build-paths.py INPUT.wasm OUTPUT.wasm [build-home-prefix]`. The output must be a new file. It replaces equal-length source-path strings only in data/custom sections and verifies executable-code section hashes are unchanged. Validate the output with `WebAssembly.validate`, then copy it into the core dist path for bundling.
4. From `web/`, run `npm run build --workspace=ruffle-selfhosted`. Do not rerun the core build after cleanup. Publish its JS/WASM and upstream licenses. Keep source changes available alongside the custom runtime.

[Provenance and exact tested hashes](../../site/ruffle/provenance.json) include raw tested source hashes and normalized-LF hashes. Build metadata and local paths can change full binary hashes on another machine. The published WASM is `ad9db6ce4bc4db575bcbeac75d3d87e0c38f399c8ac57f65d8486cecdcddf482`; debug-path cleanup changed 440 data-section strings without changing executable code.

The idle-cache estimate is capped at 256 MiB, four entries per key and 64 recent keys. Active resources, game assets, staging buffers and driver memory are outside this estimate. [Measured gameplay, rendering and save checks](../../docs/performance.md) document benefits and remaining tails. This host-side repair requires the custom runtime; a SWF cannot force the Internet Archive's player to use it. Older hashed vendored files remain for rollback but are not requested by the current bootstrap.
