"""Build a small COPY/LITERAL delta; game assets stay on Internet Archive.

Format: gzip(BNP1, target_length:u32le, then records).
COPY=0, offset:u32le, length:u32le; LITERAL=1, length:u32le, bytes; END=255.
Hashes and source URL are in the adjacent manifest. No third-party packages.
"""
from pathlib import Path
import gzip
import hashlib
import json
import struct
import zlib

ROOT = Path(__file__).resolve().parent.parent


def unpack_swf(data):
    if data[:3] == b'CWS':
        data = b'FWS' + data[3:8] + zlib.decompress(data[8:])
    if data[:3] != b'FWS' or len(data) != struct.unpack_from('<I', data, 4)[0]:
        raise ValueError('Invalid SWF header/length')
    return data


def make_delta(source, target):
    block = 64
    index = {}
    for i in range(0, len(source) - block + 1, 16):
        key = source[i:i+block]
        # Repeated fill patterns need only a few candidates; bound generation cost.
        offsets = index.setdefault(key, [])
        if len(offsets) < 4:
            offsets.append(i)
    result = bytearray(b'BNP1' + struct.pack('<I', len(target)))
    literal = bytearray()

    def emit_literal():
        if literal:
            result.extend(b'\x01' + struct.pack('<I', len(literal)) + literal)
            literal.clear()

    p = 0
    while p < len(target):
        best_at, best_len = 0, 0
        for offset in index.get(target[p:p+block], []):
            length = block
            limit = min(len(source) - offset, len(target) - p)
            while length < limit and source[offset+length] == target[p+length]:
                length += 1
            if length > best_len:
                best_at, best_len = offset, length
        if best_len:
            emit_literal()
            result.extend(b'\x00' + struct.pack('<II', best_at, best_len))
            p += best_len
        else:
            literal.append(target[p])
            p += 1
    emit_literal()
    result.append(255)
    return bytes(result)


def apply_delta(source, patch):
    assert patch[:4] == b'BNP1'
    expected = struct.unpack_from('<I', patch, 4)[0]
    out = bytearray()
    p = 8
    while patch[p] != 255:
        tag = patch[p]
        p += 1
        if tag == 0:
            offset, length = struct.unpack_from('<II', patch, p)
            p += 8
            assert offset + length <= len(source)
            out.extend(source[offset:offset+length])
        elif tag == 1:
            length = struct.unpack_from('<I', patch, p)[0]
            p += 4
            out.extend(patch[p:p+length])
            p += length
        else:
            raise ValueError('Invalid patch opcode')
    assert p + 1 == len(patch) and len(out) == expected
    return bytes(out)


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', type=Path, default=ROOT / 'site/game/LandOfBunnies.swf')
    parser.add_argument('--destination', type=Path, default=ROOT / 'site/patches')
    args = parser.parse_args()
    original = (ROOT / 'original/LandOfBunnies.swf').read_bytes()
    source = unpack_swf(original)
    target = unpack_swf(args.target.read_bytes())
    delta = make_delta(source, target)
    assert apply_delta(source, delta) == target, 'Delta roundtrip failed'
    packed = gzip.compress(delta, mtime=0)
    destination = args.destination
    destination.mkdir(exist_ok=True)
    (destination / 'land-of-bunnies.bpatch.gz').write_bytes(packed)
    manifest = {
        'format': 'BNP1',
        'sourceUrl': 'https://archive.org/cors/bunnibunni/LandOfBunnies.swf',
        'sourceSha256': hashlib.sha256(original).hexdigest(),
        'sourceFwsSha256': hashlib.sha256(source).hexdigest(),
        'targetFwsSha256': hashlib.sha256(target).hexdigest(),
        'patchedSwfSha256': hashlib.sha256(args.target.read_bytes()).hexdigest(),
        'patchSha256': hashlib.sha256(packed).hexdigest(),
        'targetLength': len(target),
        'authoredFrameRate': 30,
    }
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Browser delta: {len(packed):,} bytes; exact SWF roundtrip verified')


if __name__ == '__main__':
    main()
