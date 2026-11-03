const q = new URLSearchParams(location.search);
// Presentation-only caps; the SWF, quality and clock remain unchanged.
const presentationCaps = {original:800,large:1440};
if (Object.hasOwn(presentationCaps,q.get('size'))) {
  document.getElementById('player').style.maxWidth = presentationCaps[q.get('size')] + 'px';
}
const local = q.get('local') === '1';
const archiveBase = 'https://archive.org/cors/bunnibunni/';
const swf = q.get('swf') || 'LandOfBunnies.swf';
const original = swf === 'LandOfBunnies.orig.swf';
window.__log = [];
window.__trace = [];
window.__gamePerf = [];
window.__frameTimes = [];
window.__gameFrameTimes = [];
window.__gameFrameStamps = [];
window.__lastGameStamp = 0;
window.__phasePerf = [];
window.__frameStarts = [];
window.__phaseLast = 0;
window.__phaseFrame = 0;
window.__savePerf = [];
window.__long = [];
window.__perf = [];
window.__loadError = null;
const origLog = console.log;
console.log = (...a) => { if (__log.length < 200) __log.push(a.join(' ')); origLog(...a); };
const config = {
  autoplay:'on', unmuteOverlay:'hidden', splashScreen:false,
  contextMenu:'on', letterbox:'on',
  // Preserve normal high-quality rendering, the authored 800x600 stage and 30-fps timing.
  quality:q.get('quality') || 'high',
  preferredRenderer:q.get('renderer') || 'wgpu-webgl',
  base:local ? 'game/' : archiveBase,
  allowNetworking:'all', allowScriptAccess:q.get('bench') === '1',
  openUrlMode:'deny', logLevel:q.get('log') || 'error', maxExecutionDuration:30,
};
window.RufflePlayer = window.RufflePlayer || {};
window.RufflePlayer.config = config;
const player = window.RufflePlayer.newest().createPlayer();
document.getElementById('player').appendChild(player);
document.getElementById('retry').addEventListener('click', () => location.reload());
const flip = new URLSearchParams(q);
if (original) flip.delete('swf'); else flip.set('swf', 'LandOfBunnies.orig.swf');
const which = document.getElementById('which');
which.textContent = original ? 'Original version \u00b7 ' : 'Patched for its original 30 fps \u00b7 ';
const compare = document.createElement('a');
compare.href = '?' + flip;
compare.textContent = original ? 'play the patched version' : 'compare the original';
which.appendChild(compare);

async function fetchBytes(url) {
  const response = await fetch(url, {credentials:'omit'});
  if (!response.ok) throw new Error(`Could not load a game file (HTTP ${response.status}).`);
  return new Uint8Array(await response.arrayBuffer());
}
async function start() {
  if (!/^LandOfBunnies(?:\.orig|\.variantC)?\.swf$/.test(swf)) throw new Error('Unknown game version.');
  let options;
  if (local) options = {url:'game/' + swf};
  else if (original) options = {url:archiveBase + 'LandOfBunnies.swf'};
  else {
    const response = await fetch('patches/manifest.json', {cache:'no-cache'});
    if (!response.ok) throw new Error('Could not load the game patch.');
    const manifest = await response.json();
    window.__bunniBuild = manifest.targetFwsSha256;
    const [source, patch] = await Promise.all([
      fetchBytes(manifest.sourceUrl), fetchBytes('patches/land-of-bunnies.bpatch.gz?sha=' + encodeURIComponent(manifest.patchSha256)),
    ]);
    document.getElementById('load-message').textContent = 'Preparing Bunni...';
    options = {data:await BunniPatch.verifiedPatch(source, patch, manifest), swfFileName:'LandOfBunnies.swf'};
  }
  options.parameters = {bunniBench:q.get('bench') === '1' ? '1' : '0'};
  // Explicit diagnostic override only; default game quality remains high.
  if (q.has('quality')) options.parameters.bunniQuality = q.get('quality');
  await player.ruffle().load(options);
  player.ruffle().traceObserver = message => {
    const m = /^bunni-fast-frames (\d+) (\d+) (\w+)/.exec(message);
    if (m) {
      __gamePerf.push({t:performance.now(),frames:+m[1],ms:+m[2],quality:m[3]});
      if (__gamePerf.length > 600) __gamePerf.shift();
    } else if (message.startsWith('bunni-fast-phase ')) {
      const name = message.slice(17), t = performance.now();
      if (name === 'begin') {
        ++__phaseFrame; __frameStarts.push({t,frame:__phaseFrame});
        if (__frameStarts.length > 3600) __frameStarts.shift();
      } else {
        __phasePerf.push({t,frame:__phaseFrame,name,ms:t-__phaseLast});
        if (__phasePerf.length > 18000) __phasePerf.shift();
      }
      __phaseLast = t;
    } else if (message === 'bunni-fast-paused') {
      __lastGameStamp = 0;
    } else if (message === 'bunni-fast-frame') {
      const t = performance.now();
      if (__lastGameStamp) __gameFrameStamps.push({t,ms:t-__lastGameStamp});
      __lastGameStamp = t;
      if (__gameFrameStamps.length > 18000) __gameFrameStamps.splice(0,__gameFrameStamps.length-18000);
    } else if (message.startsWith('bunni-fast-frame-times ')) {
      __gameFrameTimes.push(...message.slice(23).split(',').filter(Boolean).map(Number));
      if (__gameFrameTimes.length > 18000) __gameFrameTimes.splice(0,__gameFrameTimes.length-18000);
    } else if (message.startsWith('bunni-fast-save')) {
      __savePerf.push({t:performance.now(),message});
      performance.mark(message.startsWith('bunni-fast-save-start') ? 'bunni-save-start' : 'bunni-save-end');
    } else if (__trace.length < 200) __trace.push(message.slice(0, 600));
  };
  document.getElementById('loading').hidden = true;
}
start().catch(error => {
  window.__loadError = error.message;
  document.getElementById('load-message').textContent = `Bunni could not load. ${error.message} Please check your connection and try again.`;
  document.getElementById('retry').hidden = false;
  console.error(error);
});
try {
  new PerformanceObserver(list => {
    for (const e of list.getEntries()) __long.push({t:e.startTime,ms:e.duration});
    if (__long.length > 1000) __long.splice(0,__long.length-1000);
  }).observe({type:'longtask',buffered:true});
} catch {}
const hud = document.getElementById('hud');
hud.hidden = q.get('hud') !== '1';
let last = performance.now(), frames = 0, worst = 0, acc = 0;
(function tick(now) {
  const dt = now-last; last=now;
  if (q.get('bench') === '1') {
    __frameTimes.push({t:now,ms:dt});
    if (__frameTimes.length > 36000) __frameTimes.splice(0,__frameTimes.length-36000);
  } frames++; acc+=dt; worst=Math.max(worst,dt);
  if (acc >= 1000) {
    const fps = frames*1000/acc;
    __perf.push({t:now,fps:+fps.toFixed(1),worst:Math.round(worst)});
    if (__perf.length > 600) __perf.shift();
    if (!hud.hidden) {
      const g = __gamePerf.at(-1);
      hud.textContent = g ? `${(g.frames*1000/g.ms).toFixed(1)} game fps \u00b7 ${fps.toFixed(0)} browser fps` : `${fps.toFixed(0)} browser fps \u00b7 game authored at 30 fps`;
    }
    frames=0; acc=0; worst=0;
  }
  requestAnimationFrame(tick);
})(last);
