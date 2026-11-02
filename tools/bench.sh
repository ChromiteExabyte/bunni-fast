#!/usr/bin/env bash
# Repeatable perf scenario against headless Chrome (see AGENTS.md for starting it).
#   tools/bench.sh                       # patched build
#   tools/bench.sh LandOfBunnies.orig.swf  # original, for comparison
#   QUALITY=low tools/bench.sh             # override the page's stage quality
# Prints fps / long-task samples at each stage and saves screenshots to .tools/bench-*.png
set -eu
PORT="${CDP_PORT:-9333}"
SWF="${1:-LandOfBunnies.swf}"
URL="${BASE_URL:-http://localhost:8137/}?bench=1&swf=$SWF${QUALITY:+&quality=$QUALITY}${LOCAL:+&local=1}${RENDERER:+&renderer=$RENDERER}"
cd "$(dirname "$0")/.."
C() { timeout "${T:-30}" node --experimental-websocket --no-warnings tools/cdp.mjs "$@"; }

# Wait for Chrome's debugging endpoint after starting a fresh browser.
for ready in {1..15}; do
  curl -sf http://localhost:${PORT}/json/version >/dev/null && break
  sleep 1
done
curl -sf http://localhost:${PORT}/json/version >/dev/null

# fresh tab
for id in $(curl -s http://localhost:${PORT}/json | python -c "import json,sys;[print(t['id']) for t in json.load(sys.stdin) if t['type']=='page']"); do
  curl -s "http://localhost:${PORT}/json/close/$id" >/dev/null
done
# Chrome's /json/new endpoint drops URL options following '&'. Navigate via CDP instead.
curl -s -X PUT "http://localhost:${PORT}/json/new?about:blank" >/dev/null
C open "$URL"
start=$(date +%s)

echo "== loading title ($SWF)"
echo "  requested $URL"
sleep 8
# Loading is done once the main thread is quiet for two samples in a row; the game ignores clicks before that.
quiet=0
while [ $quiet -lt 2 ]; do
  if C perf 3 | grep -q '"longTasks":0,'; then quiet=$((quiet + 1)); else quiet=0; fi
  if [ $(( $(date +%s) - start )) -gt 180 ]; then echo "  title never settled"; exit 1; fi
done
echo "  title ready after $(( $(date +%s) - start ))s"
C eval "JSON.stringify({url:location.href,quality:config.quality,viewport:[innerWidth,innerHeight],metadata:player.ruffle().metadata,renderer:__log.find(s=>s.includes('Used renderer'))})"
C shot .tools/bench-1-title.png

# Stage point (650,300) is black on the title screen and land or water in the world.
in_world() { local px; px=$(T=8 C pixel 650 300) || return 1; [ $(( $(echo "$px" | tr ',' '+') )) -gt 60 ]; }

echo "== new game"
# Click exactly once: the New Game button stays clickable while the world generates, and a second
# click starts a second game on top of the first (double the per-frame work).
# Ruffle sometimes spends a click on unlocking audio, so a click can be lost; only re-click after giving
# the world 30 s to appear while the page stays responsive (a frozen page means generation is running).
started=""
for attempt in 1 2 3; do
  C click 265 368
  t0=$(date +%s)
  while [ $(( $(date +%s) - t0 )) -lt 30 ]; do
    sleep 2
    px=$(T=8 C pixel 650 300) || { started=frozen; break; }
    [ $(( $(echo "$px" | tr ',' '+') )) -gt 60 ] && { started=world; break; }
  done
  [ -n "$started" ] && break
  echo "  click $attempt didn't start a game, retrying"
done
[ -z "$started" ] && { echo "  could not start a game"; C shot .tools/bench-1b-clicked.png; exit 1; }
# wait until the world is on screen, up to 5 minutes (the original freezes the tab here)
until in_world; do
  if [ $(( $(date +%s) - t0 )) -gt 300 ]; then echo "  still no world 300s after New Game, giving up"; exit 1; fi
  sleep 2
done
echo "  world on screen $(( $(date +%s) - t0 ))s after New Game"
vp=$(C eval "innerWidth+'x'+innerHeight")
case "$vp" in 1x1|0x0|"") echo "  viewport is $vp, numbers would be meaningless"; exit 1;; esac
echo "  viewport $vp"
sleep 3
C perf 4
C shot .tools/bench-2-world.png

echo "== first step (spawns the tutorial bubble + arrow)"
C hold 600 400 400
sleep 3
for i in 1 2 3; do C perf 4 || echo "  frozen"; done

C shot .tools/bench-2b-step.png

echo "== walking"
(C hold 750 450 5000 &)
C perf 5 || echo "  frozen"
(C hold 80 120 5000 &)
C perf 5 || echo "  frozen"
sleep 1
C shot .tools/bench-3-walk.png
echo "total $(( $(date +%s) - start ))s"
