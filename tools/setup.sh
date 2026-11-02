#!/usr/bin/env bash
# One-time setup: original game files from archive.org, JPEXS FFDec, Ruffle, and a decompiled copy for reading.
set -eu
cd "$(dirname "$0")/.."
FFDEC_VERSION=26.4.0
RUFFLE_VERSION=0.7.1

mkdir -p original .tools
for f in LandOfBunnies.swf Sounds.swf piratepeach.swf title.swf tutorial.swf vector_art.swf wedding.swf \
         game.xml game_no_mt.xml save_data.xml store_items.xml; do
  [ -f "original/$f" ] || curl -sfL -o "original/$f" "https://archive.org/download/bunnibunni/$f"
done
echo "original/: ok"

if [ ! -f .tools/ffdec/ffdec.jar ]; then
  curl -sfL -o .tools/ffdec.zip "https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version$FFDEC_VERSION/ffdec_$FFDEC_VERSION.zip"
  mkdir -p .tools/ffdec && unzip -q -o .tools/ffdec.zip -d .tools/ffdec
fi
echo ".tools/ffdec: ok"

if [ ! -f site/ruffle/ruffle.js ]; then
  mkdir -p .tools/npm site/ruffle
  curl -sfL -o .tools/npm/ruffle.tgz "https://registry.npmjs.org/@ruffle-rs/ruffle/-/ruffle-$RUFFLE_VERSION.tgz"
  tar xzf .tools/npm/ruffle.tgz -C .tools/npm
  cp .tools/npm/package/*.js .tools/npm/package/*.wasm .tools/npm/package/LICENSE* site/ruffle/
fi
echo "site/ruffle: ok"

if [ ! -d decompiled/LandOfBunnies ]; then
  java -jar .tools/ffdec/ffdec.jar -export script decompiled/LandOfBunnies original/LandOfBunnies.swf > /dev/null
fi
echo "decompiled/: ok"
