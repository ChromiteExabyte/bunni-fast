// Capture CPU and detailed GPU commands in one process so the menu action is
// guaranteed to fall inside both recording windows. Raw traces remain private.
import fs from 'node:fs';
const [prefix,name='Bunni']=process.argv.slice(2),port=process.env.CDP_PORT||9341;
if(!prefix)throw new Error('Usage: profile-menu.mjs evidence-prefix [shop-item-name]');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function connect(url){
 const ws=new WebSocket(url);await new Promise(r=>ws.addEventListener('open',r,{once:true}));let id=0;const pending=new Map(),listeners=[];
 ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id&&pending.has(m.id)){pending.get(m.id)(m);pending.delete(m.id);}else listeners.forEach(f=>f(m));});
 return{ws,listeners,send:(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,m=>m.error?reject(new Error(JSON.stringify(m.error))):resolve(m.result));ws.send(JSON.stringify({id:n,method,params}));})};
}
const targets=await(await fetch(`http://localhost:${port}/json`)).json(),version=await(await fetch(`http://localhost:${port}/json/version`)).json();
const page=await connect(targets.find(x=>x.type==='page').webSocketDebuggerUrl),browser=await connect(version.webSocketDebuggerUrl);
async function evaluate(expression){const r=await page.send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails));return r.result.value;}
const state=JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
if(state.paused)throw new Error('Begin in the unpaused world.');
const item=state.items.find(x=>x.name===name&&x.type.endsWith('::StoreItem')&&x.rect&&x.rect[0]>0&&x.rect[0]+x.rect[2]<800&&x.rect[1]>30&&x.rect[1]+x.rect[3]<600);
if(!item)throw new Error('Requested shop is not fully visible: '+name);
const shot=async suffix=>{const r=await page.send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(prefix+suffix+'.png',Buffer.from(r.data,'base64'));};
await shot('-before');
if(process.env.GL_PROBE==='1')await evaluate(fs.readFileSync(new URL('./gl-diagnostics.js',import.meta.url),'utf8'));
const events=[];let done;
const complete=new Promise(r=>done=r);browser.listeners.push(m=>{if(m.method==='Tracing.dataCollected')events.push(...m.params.value);if(m.method==='Tracing.tracingComplete')done();});
await page.send('Profiler.enable');await page.send('Profiler.setSamplingInterval',{interval:200});await page.send('Profiler.start');
await browser.send('Tracing.start',{traceConfig:{includedCategories:['gpu','gpu.angle','devtools.timeline','blink.user_timing','toplevel','v8',...(process.env.GPU_TRACE_DETAIL==='1'?['disabled-by-default-gpu.decoder','disabled-by-default-gpu.service']:[])],excludedCategories:['*']}});
await evaluate('window.__profileMenuStart=performance.now();performance.mark("profile-menu-open");__frameTimes=[];__long=[];');
const box=await evaluate('(()=>{let r=document.querySelector("#player").getBoundingClientRect();return [r.left,r.top,r.width,r.height]})()');
const x=box[0]+(item.rect[0]+item.rect[2]/2)*box[2]/800,y=box[1]+(item.rect[1]+item.rect[3]/2)*box[3]/600;
await page.send('Input.dispatchMouseEvent',{type:'mouseMoved',x,y});await sleep(150);await page.send('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});await sleep(80);await page.send('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});
await sleep(5000);
const measurement=await evaluate('({start:__profileMenuStart,end:performance.now(),origin:performance.timeOrigin,frames:__frameTimes.filter(x=>x.t-x.ms>=__profileMenuStart),glStats:window.__glStats,glSlow:window.__glSlow,glAllocations:window.__glAllocations,longTasks:__long.filter(x=>x.t>=__profileMenuStart),state:JSON.parse(player.ruffle().callExternalInterface("bunniBenchState")),viewport:[innerWidth,innerHeight],quality:config.quality})');
await browser.send('Tracing.end');const {profile}=await page.send('Profiler.stop');await complete;
fs.writeFileSync(prefix+'.trace.json',JSON.stringify({traceEvents:events}));fs.writeFileSync(prefix+'.cpuprofile',JSON.stringify(profile));fs.writeFileSync(prefix+'.measurement.json',JSON.stringify(measurement,null,2));await shot('-after');
const names=new Map(events.filter(x=>x.ph==='M'&&x.name==='thread_name').map(x=>[x.pid+':'+x.tid,x.args.name]));
const gpu=events.filter(x=>x.ph==='X'&&names.get(x.pid+':'+x.tid)==='CrGpuMain'&&x.dur>5000);
console.log(JSON.stringify({item:name,viewport:measurement.viewport,pausedAfter:measurement.state.paused,frameSpikes:measurement.frames.filter(x=>x.ms>33.5),longTasks:measurement.longTasks,traceEvents:events.length,gpuLongest:gpu.sort((a,b)=>b.dur-a.dur).slice(0,30).map(x=>({name:x.name,ms:x.dur/1000,args:x.args}))},null,2));
page.ws.close();browser.ws.close();
