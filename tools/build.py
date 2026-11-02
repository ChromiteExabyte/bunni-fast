"""Recompile AS3 patches with FFDec, preserving the live SWF if any class fails.

python tools/build.py
python tools/build.py --patches path/to/alternative/as3 --output .tools/alternative.swf
"""
import argparse
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
FFDEC = ROOT / '.tools/ffdec/ffdec.jar'
ORIGINAL = ROOT / 'original'
PATCHES = ROOT / 'patches/as3'
GAME = ROOT / 'site/game'


def class_names(patches):
    names = [str(p.relative_to(patches).with_suffix('')).replace('\\', '.').replace('/', '.')
             for p in sorted(patches.rglob('*.as'))]
    if 'Land.Land' not in names:
        sys.exit('The patch set must include Land.Land.')
    # FFDec compiles other classes against the new Land.queue/blit/flush API.
    ordered = [n for n in ['Land.Land', 'Tutorial.Tasks'] if n in names]
    return ordered + [n for n in names if n not in ordered]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--patches', type=pathlib.Path, default=PATCHES)
    parser.add_argument('--output', type=pathlib.Path, default=GAME / 'LandOfBunnies.swf')
    args = parser.parse_args()
    patches, output = args.patches.resolve(), args.output.resolve()
    if not FFDEC.exists():
        sys.exit(f'FFDec not found at {FFDEC}; run bash tools/setup.sh first.')
    names = class_names(patches)
    output.parent.mkdir(parents=True, exist_ok=True)
    # Keep alternative builds separate and leave the original input untouched.
    if output.parent == GAME:
        for f in ORIGINAL.iterdir():
            if f.suffix in ('.swf', '.xml') and f.name != 'LandOfBunnies.swf':
                shutil.copy2(f, GAME / f.name)
        shutil.copy2(ORIGINAL / 'LandOfBunnies.swf', GAME / 'LandOfBunnies.orig.swf')
    with tempfile.TemporaryDirectory(prefix='bunni-build-', dir=ROOT / '.tools') as work:
        current = pathlib.Path(work) / 'current.swf'
        temporary = pathlib.Path(work) / 'next.swf'
        source = ORIGINAL / 'LandOfBunnies.swf'
        for name in names:
            as_file = patches / (name.replace('.', '/') + '.as')
            print(f'replace {name}', flush=True)
            result = subprocess.run([
                'java', '-Xmx512m', '-XX:ParallelGCThreads=2', '-XX:ConcGCThreads=1',
                '-jar', str(FFDEC), '-replace', str(source), str(temporary), name, str(as_file),
            ], capture_output=True, text=True)
            if result.returncode != 0 or not temporary.exists():
                sys.exit(f'FFDec failed on {name}; live SWF preserved:\n{result.stdout}\n{result.stderr}')
            temporary.replace(current)
            source = current
        current.replace(output)
    print(f'wrote {output}')
    if output == GAME / 'LandOfBunnies.swf':
        subprocess.run([sys.executable, str(ROOT / 'tools/make-web-patch.py')], check=True)


if __name__ == '__main__':
    main()
