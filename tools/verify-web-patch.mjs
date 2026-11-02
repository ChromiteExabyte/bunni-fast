// Verify the exact same patch parser used by the browser, with real local fixtures.
import {readFile} from 'node:fs/promises';
import {webcrypto} from 'node:crypto';
globalThis.crypto ??= webcrypto;
await import('../site/patcher.js');
const root = new URL('../', import.meta.url);
const bytes = async p => new Uint8Array(await readFile(new URL(p, root)));
const manifest = JSON.parse(await readFile(new URL('site/patches/manifest.json', root), 'utf8'));
const source = await bytes('original/LandOfBunnies.swf');
const patch = await bytes('site/patches/land-of-bunnies.bpatch.gz');
const result = await BunniPatch.verifiedPatch(source, patch, manifest);
const expected = await BunniPatch.unpackSwf(await bytes('site/game/LandOfBunnies.swf'));
if (await BunniPatch.hash(result) !== await BunniPatch.hash(expected)) throw new Error('SWF roundtrip differs');
for (const corrupt of ['source', 'patch']) {
  const badSource = source.slice(), badPatch = patch.slice();
  (corrupt === 'source' ? badSource : badPatch)[20] ^= 1;
  let rejected = false;
  try { await BunniPatch.verifiedPatch(badSource, badPatch, manifest); } catch { rejected = true; }
  if (!rejected) throw new Error(`Corrupted ${corrupt} was accepted`);
}
console.log(`Browser patch roundtrip verified (${result.length} bytes); corrupted inputs rejected.`);
