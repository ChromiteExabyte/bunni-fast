// Tiny Chrome DevTools Protocol client for poking at the game from the command line.
// Start Chrome first (see AGENTS.md), then:
//   node --experimental-websocket tools/cdp.mjs open "http://localhost:8137/?swf=LandOfBunnies.orig.swf"
//   node --experimental-websocket tools/cdp.mjs click 253 352        (stage coords, 800x600)
//   node --experimental-websocket tools/cdp.mjs shot out.png
//   node --experimental-websocket tools/cdp.mjs eval "JSON.stringify(window.__perf)"
//   node --experimental-websocket tools/cdp.mjs perf 10              (sample frame times for N seconds)
const PORT = process.env.CDP_PORT || 9333;
const [cmd, ...args] = process.argv.slice(2);

const targets = await (await fetch(`http://localhost:${PORT}/json`)).json();
const page = targets.find(t => t.type === "page");
// "trace" needs the browser-level target; everything else talks to the page.
const wsUrl = (cmd === "trace" || cmd === "close" || cmd === "download-dir" || cmd === "categories")
  ? (await (await fetch(`http://localhost:${PORT}/json/version`)).json()).webSocketDebuggerUrl
  : page.webSocketDebuggerUrl;
const ws = new WebSocket(wsUrl);
await new Promise(r => ws.addEventListener("open", r, { once: true }));
let nextId = 1;
const pending = new Map();
ws.addEventListener("message", e => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
});
const send = (method, params = {}) => new Promise(r => {
  const id = nextId++; pending.set(id, r); ws.send(JSON.stringify({ id, method, params }));
});
const evaluate = async expr => {
  const r = await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true });
  return r.result?.result?.value ?? r.result?.exceptionDetails?.text;
};
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Stage (800x600) coords -> page coords, using the player element's box.
async function toPage(x, y) {
  const box = JSON.parse(await evaluate(`(() => { const r = document.querySelector("#player").getBoundingClientRect(); return JSON.stringify([r.left, r.top, r.width, r.height]); })()`));
  return [box[0] + x * box[2] / 800, box[1] + y * box[3] / 600];
}

switch (cmd) {
  case "raf-probe": {
    const fs=await import("node:fs");
    await evaluate('window.__rafProbeSeconds='+Number(args[1]||20));
    const data=await evaluate(fs.readFileSync(new URL("./raf-probe.js",import.meta.url),"utf8"));
    fs.writeFileSync(args[0],JSON.stringify(data,null,2));console.log(JSON.stringify(data.groups,null,2));break;
  }
  case "copy-save-origin": {
    const destination=new URL(args[0]);
    if(destination.hostname!=="localhost"||!String(await evaluate('location.origin')).startsWith("http://localhost:"))throw new Error("This helper is restricted to local test origins.");
    const data=await evaluate('Object.fromEntries(Object.entries(localStorage).filter(([k])=>k==="localhost//bunni-fast-save-v1-slot1"||k==="localhost//bunni-fast-slot-v1-1"))');
    if(Object.keys(data).length!==2)throw new Error("Expected both private test slot records.");
    await send("Page.navigate",{url:args[0]});await sleep(1000);
    await evaluate('for(const [key,value] of Object.entries('+JSON.stringify(data)+'))localStorage.setItem(key,value);window.__testSaveCopied=true;');
    const copied=await evaluate('Object.keys(localStorage).filter(k=>k.includes("bunni-fast"))');
    if(copied.length<2)throw new Error("Local save copy was not confirmed.");
    await send("Page.navigate",{url:args[0]});await sleep(1000);
    console.log(await evaluate('JSON.stringify({url:location.href,copied:window.__testSaveCopied,keys:Object.keys(localStorage).filter(k=>k.includes("bunni-fast"))})'));break;
  }
  case "export-backup": {
    const data=await evaluate('player.ruffle().callExternalInterface("bunniBenchBackup")');
    (await import("node:fs")).writeFileSync(args[0],data);console.log(JSON.stringify({bytes:data.length}));break;
  }
  case "import-backup": {
    const data=(await import("node:fs")).readFileSync(args[0],'utf8');
    console.log(await evaluate('player.ruffle().callExternalInterface("bunniBenchImport",'+JSON.stringify(data)+')'));break;
  }
  case "file-choose": {
    await send("Page.enable");
    await send("Page.setInterceptFileChooserDialog",{enabled:true});
    const chooser = new Promise((resolve,reject)=>{
      const timer=setTimeout(()=>reject(new Error("No file chooser appeared")),10000);
      ws.addEventListener("message",e=>{
        const m=JSON.parse(e.data);
        if(m.method==="Page.fileChooserOpened"){clearTimeout(timer);resolve(m.params);}
      });
    });
    const [x,y]=await toPage(+args[0],+args[1]);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x,y});
    await sleep(200);
    await send("Input.dispatchMouseEvent",{type:"mousePressed",x,y,button:"left",clickCount:1});
    await sleep(80);
    await send("Input.dispatchMouseEvent",{type:"mouseReleased",x,y,button:"left",clickCount:1});
    const event=await chooser;
    console.log(JSON.stringify(event));
    await send("DOM.setFileInputFiles",{files:[args[2]],backendNodeId:event.backendNodeId});
    await send("Page.setInterceptFileChooserDialog",{enabled:false});
    break;
  }
  case "categories": console.log(JSON.stringify((await send("Tracing.getCategories")).result.categories.filter(x=>/gpu|angle|shader|vulkan/i.test(x)))); break;
  case "download-dir": await send("Browser.setDownloadBehavior",{behavior:"allow",downloadPath:args[0]}); break;
  case "close": await send("Browser.close"); break;
  case "viewport": {
    await send("Emulation.setDeviceMetricsOverride",{width:+args[0],height:+args[1],deviceScaleFactor:1,mobile:false});
    console.log(await evaluate("JSON.stringify({viewport:[innerWidth,innerHeight],pixelRatio:devicePixelRatio})"));
    break;
  }
  case "open":
    await send("Page.navigate", { url: args[0] });
    break;
  case "click": {
    const [px, py] = await toPage(+args[0], +args[1]);
    // Flash buttons need a frame in the "over" state before they accept a press.
    await send("Input.dispatchMouseEvent", { type: "mouseMoved", x: px, y: py });
    await sleep(200);
    await send("Input.dispatchMouseEvent", { type: "mousePressed", x: px, y: py, button: "left", clickCount: 1 });
    await sleep(80);
    await send("Input.dispatchMouseEvent", { type: "mouseReleased", x: px, y: py, button: "left", clickCount: 1 });
    break;
  }
  case "hold": { // hold mouse at a point for N ms (the avatar walks toward a held mouse)
    const [px, py] = await toPage(+args[0], +args[1]);
    await send("Input.dispatchMouseEvent", { type: "mouseMoved", x: px, y: py });
    await send("Input.dispatchMouseEvent", { type: "mousePressed", x: px, y: py, button: "left", clickCount: 1 });
    await sleep(+(args[2] || 1000));
    await send("Input.dispatchMouseEvent", { type: "mouseReleased", x: px, y: py, button: "left", clickCount: 1 });
    break;
  }
  case "drag-worker": {
    const state=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
    const animal=state.items.find(x=>x.name===args[0]&&x.type.includes("Animals::")&&x.rect),work=state.items.find(x=>x.name===args[1]&&x.type.includes("Building::"));
    if(state.paused||!animal||!work)throw new Error("Visible worker and workplace are required.");
    const [sx,sy]=await toPage(animal.rect[0]+animal.rect[2]/2,animal.rect[1]+animal.rect[3]/2),[x,y]=await toPage(work.sx,work.sy);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x:sx,y:sy});await sleep(150);
    await send("Input.dispatchMouseEvent",{type:"mousePressed",x:sx,y:sy,button:"left",buttons:1,clickCount:1});await sleep(250);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x,y,button:"left",buttons:1});await sleep(500);
    const dragging=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
    await send("Input.dispatchMouseEvent",{type:"mouseReleased",x,y,button:"left",buttons:0,clickCount:1});await sleep(1000);
    console.log(JSON.stringify({dragging:dragging.dragging,after:JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'))}));break;
  }
  case "drag-item": {
    const before=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
    if(before.paused)throw new Error("Dismiss the modal before dragging.");
    const item=before.items.find(x=>x.name===args[0]&&x.type.endsWith("::PlacementItem"));
    if(!item?.rect)throw new Error("No matching placement item is visible.");
    const [sx,sy]=await toPage(item.rect[0]+item.rect[2]/2,item.rect[1]+item.rect[3]/2),[x,y]=await toPage(+args[1],+args[2]);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x:sx,y:sy});await sleep(100);
    await send("Input.dispatchMouseEvent",{type:"mousePressed",x:sx,y:sy,button:"left",buttons:1,clickCount:1});await sleep(100);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x,y,button:"left",buttons:1});await sleep(600);
    const dragging=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
    await send("Input.dispatchMouseEvent",{type:"mouseReleased",x,y,button:"left",buttons:0,clickCount:1});await sleep(600);
    const after=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
    console.log(JSON.stringify({dragging:dragging.dragging,canPlace:dragging.canPlace,paused:dragging.paused,after}));break;
  }
  case "drag-start": {
    const [sx,sy]=await toPage(+args[0],+args[1]);
    const [ex,ey]=await toPage(+args[2],+args[3]);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x:sx,y:sy});
    await sleep(200);
    await send("Input.dispatchMouseEvent",{type:"mousePressed",x:sx,y:sy,button:"left",buttons:1,clickCount:1});
    await sleep(200);
    await send("Input.dispatchMouseEvent",{type:"mouseMoved",x:ex,y:ey,button:"left",buttons:1});
    break;
  }
  case "release": {
    const [x,y]=await toPage(+args[0],+args[1]);
    await send("Input.dispatchMouseEvent",{type:"mouseReleased",x,y,button:"left",buttons:0,clickCount:1});
    break;
  }
  case "shot": {
    const r = await send("Page.captureScreenshot", { format: "png" });
    (await import("node:fs")).writeFileSync(args[0] || "shot.png", Buffer.from(r.result.data, "base64"));
    break;
  }
  case "pixel": { // r,g,b of the screen at a stage point (e.g. to tell the title screen from the game world)
    // Full screenshot, decoded here: a clipped screenshot shrinks the headless viewport to the clip size.
    const [px, py] = (await toPage(+args[0], +args[1])).map(Math.round);
    const r = await send("Page.captureScreenshot", { format: "png" });
    const png = Buffer.from(r.result.data, "base64");
    const width = png.readUInt32BE(16), bpp = png[25] === 6 ? 4 : 3;  // 8-bit RGBA or RGB
    const idat = [];
    for (let o = 8; o < png.length;) {
      const len = png.readUInt32BE(o), type = png.toString("ascii", o + 4, o + 8);
      if (type === "IDAT") idat.push(png.subarray(o + 8, o + 8 + len));
      o += 12 + len;
    }
    const raw = (await import("node:zlib")).inflateSync(Buffer.concat(idat));
    const stride = width * bpp;
    let prev = Buffer.alloc(stride), row;
    for (let y = 0; y <= py; y++) {  // undo PNG row filters down to the row we need
      const f = raw[y * (stride + 1)], src = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
      row = Buffer.alloc(stride);
      for (let i = 0; i < stride; i++) {
        const a = i >= bpp ? row[i - bpp] : 0, b = prev[i], c = i >= bpp ? prev[i - bpp] : 0;
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        const pred = [0, a, b, (a + b) >> 1, pa <= pb && pa <= pc ? a : pb <= pc ? b : c][f];
        row[i] = (src[i] + pred) & 255;
      }
      prev = row;
    }
    console.log([row[px * bpp], row[px * bpp + 1], row[px * bpp + 2]].join(","));
    break;
  }
  case "eval":
    console.log(await evaluate(args.join(" ")));
    break;
  case "perf": { // fps and long-task load over the next N seconds
    const secs = +(args[0] || 10);
    const start = await evaluate("performance.now()");
    await sleep(secs * 1000);
    console.log(await evaluate(`(() => {
      const p = window.__perf.filter(s => s.t > ${start});
      const l = window.__long.filter(s => s.t > ${start});
      const g = (window.__gamePerf || []).filter(s => s.t - s.ms >= ${start});
      const gameMs = g.reduce((a, b) => a + b.ms, 0);
      const gameFrames = g.reduce((a, b) => a + b.frames, 0);
      const fps = p.map(s => s.fps).sort((a, b) => a - b);
      return JSON.stringify({ gameFps: gameMs ? +(gameFrames * 1000 / gameMs).toFixed(2) : null, gameSamples: g.length, gameQuality: g.length ? g[g.length-1].quality : null, seconds: p.length, medianFps: fps[fps.length >> 1], minFps: fps[0],
        worstFrameMs: Math.max(0, ...p.map(s => s.worst)), longTasks: l.length,
        busyPct: Math.round(100 * l.reduce((a, b) => a + b.ms, 0) / (${secs} * 1000)) });
    })()`));
    break;
  }
  case "stack": { // pause the page wherever it is (works even when it's frozen) and print the call stack
    const paused = new Promise(r => ws.addEventListener("message", e => {
      const m = JSON.parse(e.data);
      if (m.method === "Debugger.paused") r(m.params);
    }));
    send("Debugger.enable");
    send("Debugger.pause");
    const p = await Promise.race([paused, sleep(20000).then(() => null)]);
    if (!p) { console.log("could not pause"); break; }
    for (const f of p.callFrames.slice(0, +(args[0] || 25)))
      console.log(`${f.functionName || "(anon)"}  ${f.url.split("/").pop()}:${f.location.lineNumber}`);
    await send("Debugger.resume");
    break;
  }
  case "profile": { // CPU profile for N seconds, top functions by self time
    await send("Profiler.enable");
    await send("Profiler.setSamplingInterval", { interval: 200 });
    await send("Profiler.start");
    await sleep(+(args[0] || 5) * 1000);
    const { result } = await send("Profiler.stop");
    const prof = result.profile;
    if(args[2]) (await import("node:fs")).writeFileSync(args[2],JSON.stringify(prof));
    const self = new Map(), byId = new Map(prof.nodes.map(n => [n.id, n]));
    const dts = prof.timeDeltas;
    prof.samples.forEach((id, i) => {
      const n = byId.get(id), f = n.callFrame;
      const key = `${f.functionName || "(anon)"} ${f.url.split("/").pop()}`;
      self.set(key, (self.get(key) || 0) + (dts[i] || 0) / 1000);
    });
    const total = [...self.values()].reduce((a, b) => a + b, 0);
    for (const [k, ms] of [...self].sort((a, b) => b[1] - a[1]).slice(0, +(args[1] || 25)))
      console.log(`${(100 * ms / total).toFixed(1).padStart(5)}%  ${ms.toFixed(0).padStart(6)}ms  ${k}`);
    break;
  }
  case "trace": { // Chrome trace for N seconds: busiest events per process/thread (finds GPU-side cost)
    const events = [];
    ws.addEventListener("message", e => {
      const m = JSON.parse(e.data);
      if (m.method === "Tracing.dataCollected") events.push(...m.params.value);
    });
    const done = new Promise(r => ws.addEventListener("message", e => {
      if (JSON.parse(e.data).method === "Tracing.tracingComplete") r();
    }));
    await send("Tracing.start", { traceConfig: { includedCategories: ["gpu", "gpu.dawn", "disabled-by-default-gpu.dawn", "toplevel", "viz", "blink", "v8.execute", "devtools.timeline", "blink.user_timing", "v8", "cc", "renderer.scheduler"] } });
    await sleep(+(args[0] || 4) * 1000);
    await send("Tracing.end");
    await done;
    if (args[2]) (await import("node:fs")).writeFileSync(args[2], JSON.stringify({traceEvents:events}));
    const names = new Map(), totals = new Map();
    for (const ev of events) if (ev.ph === "M" && ev.name === "thread_name") names.set(`${ev.pid}:${ev.tid}`, ev.args.name);
    for (const ev of events) if (ev.ph === "X" && ev.dur) {
      const key = `${names.get(`${ev.pid}:${ev.tid}`) || ev.tid} | ${ev.name}`;
      totals.set(key, (totals.get(key) || 0) + ev.dur / 1000);
    }
    for (const [k, ms] of [...totals].sort((a, b) => b[1] - a[1]).slice(0, +(args[1] || 30)))
      console.log(`${ms.toFixed(0).padStart(7)}ms  ${k}`);
    break;
  }
  default:
    console.error("commands: open <url> | click x y | hold x y ms | shot file | eval js | perf secs");
}
ws.close();
