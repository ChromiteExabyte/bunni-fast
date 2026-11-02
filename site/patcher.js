/* COPY/LITERAL delta application. Fetch original game assets from their Archive host. */
(() => {
  const hash = async bytes => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
  async function inflate(bytes, format) {
    return new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream(format))).arrayBuffer());
  }
  async function unpackSwf(bytes) {
    if (String.fromCharCode(...bytes.subarray(0, 3)) === 'CWS') {
      const body = await inflate(bytes.subarray(8), 'deflate');
      const out = new Uint8Array(body.length + 8);
      out.set(bytes.subarray(0, 8)); out[0] = 70; out.set(body, 8); bytes = out;
    }
    if (String.fromCharCode(...bytes.subarray(0, 3)) !== 'FWS' || new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getUint32(4, true) !== bytes.length) throw new Error('Unexpected game file format.');
    return bytes;
  }
  function apply(source, patch, expectedLength) {
    if (patch.length < 9 || String.fromCharCode(...patch.subarray(0, 4)) !== 'BNP1') throw new Error('Invalid patch header.');
    const view = new DataView(patch.buffer, patch.byteOffset, patch.byteLength);
    const size = view.getUint32(4, true);
    if (size !== expectedLength || size > 8 * 1024 * 1024) throw new Error('Invalid patched game size.');
    const out = new Uint8Array(size);
    let p = 8, w = 0, ended = false;
    function uint32() { if (p + 4 > patch.length) throw new Error('Truncated patch.'); const n = view.getUint32(p, true); p += 4; return n; }
    while (p < patch.length) {
      const tag = patch[p++];
      if (tag === 255) { ended = true; break; }
      if (tag === 0) {
        const offset = uint32(), length = uint32();
        if (offset + length > source.length || w + length > size) throw new Error('Invalid patch copy.');
        out.set(source.subarray(offset, offset + length), w); w += length;
      } else if (tag === 1) {
        const length = uint32();
        if (p + length > patch.length || w + length > size) throw new Error('Invalid patch literal.');
        out.set(patch.subarray(p, p + length), w); p += length; w += length;
      } else throw new Error('Invalid patch instruction.');
    }
    if (!ended || p !== patch.length || w !== size) throw new Error('Incomplete patch.');
    return out;
  }
  async function verifiedPatch(original, packed, manifest) {
    if (await hash(original) !== manifest.sourceSha256 || await hash(packed) !== manifest.patchSha256) throw new Error('File verification failed. Please reload to try again.');
    const source = await unpackSwf(original);
    if (await hash(source) !== manifest.sourceFwsSha256) throw new Error('Unexpected original game version.');
    const target = apply(source, await inflate(packed, 'gzip'), manifest.targetLength);
    if (await hash(target) !== manifest.targetFwsSha256) throw new Error('Patched game verification failed.');
    return target;
  }
  globalThis.BunniPatch = { hash, inflate, unpackSwf, apply, verifiedPatch };
})();
