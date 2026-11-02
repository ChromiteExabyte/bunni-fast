// Run against an already loaded, visible-world headless Chrome test profile.
// CDP_PORT=9341 node tools/gameplay-scenario.mjs .tools/evidence/name
import fs from 'node:fs';
const prefix=process.argv[2],port=process.env.CDP_PORT||9341;
if(!prefix)throw new Error('Supply an evidence filename prefix.');
const targets=await(await fetch(`http://localhost:${port}/json`)).json();
const target=targets.find(x=>x.type==='page');
const ws=new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r=>ws.addEventListener('open',r,{once:true}));
let seq=0;const pending=new Map();
ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id&&pending.has(m.id)){pending.get(m.id)(m);pending.delete(m.id);}});
const send=(method,params={})=>new Promise((resolve,reject)=>{const id=++seq;pending.set(id,m=>m.error?reject(new Error(JSON.stringify(m.error))):resolve(m.result));ws.send(JSON.stringify({id,method,params}));});
const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const state=async()=>JSON.parse(await evaluate('player.ruffle().callExternalInterface("bunniBenchState")'));
async function point(x,y){const r=await evaluate('(()=>{let r=document.querySelector("#player").getBoundingClientRect();return [r.left,r.top,r.width,r.height]})()');return{x:r[0]+x*r[2]/800,y:r[1]+y*r[3]/600};}
async function click(x,y){const p=await point(x,y);await send('Input.dispatchMouseEvent',{type:'mouseMoved',...p});await sleep(150);await send('Input.dispatchMouseEvent',{type:'mousePressed',...p,button:'left',clickCount:1});await sleep(80);await send('Input.dispatchMouseEvent',{type:'mouseReleased',...p,button:'left',clickCount:1});}
async function hold(x,y,ms){const p=await point(x,y);await send('Input.dispatchMouseEvent',{type:'mouseMoved',...p});await send('Input.dispatchMouseEvent',{type:'mousePressed',...p,button:'left',clickCount:1});await sleep(ms);await send('Input.dispatchMouseEvent',{type:'mouseReleased',...p,button:'left',clickCount:1});}
async function shot(suffix){if(process.env.NO_INLINE_SHOTS==='1'&&!['-before','-after'].includes(suffix))return;const r=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(prefix+suffix+'.png',Buffer.from(r.data,'base64'));}
async function mark(name){console.log(name);await evaluate(`performance.mark(${JSON.stringify(name)});window.__scenarioEvents.push({name:${JSON.stringify(name)},t:performance.now()});`);}
const before=await state();if(before.paused)throw new Error('Game is paused; begin in the world.');
await shot('-before');
await evaluate('window.__scenarioEvents=[];window.__scenarioStart=performance.now();window.__frameTimes=[];window.__gameFrameTimes=[];window.__gameFrameStamps=[];window.__lastGameStamp=0;window.__gamePerf=[];window.__savePerf=[];window.__long=[];');
await mark('standing');await sleep(10000);
const bubble=before.items.find(x=>!["Bunni","Fox","Panda","Pirate","Deer","Monster"].includes(x.name)&&x.type.endsWith('::StoreItem')&&x.rect&&x.rect[0]>0&&x.rect[0]+x.rect[2]<800&&x.rect[1]>30&&x.rect[1]+x.rect[3]<600);
if(bubble){
 await mark('item-card-open');await click(bubble.rect[0]+bubble.rect[2]/2,bubble.rect[1]+bubble.rect[3]/2);await sleep(1400);await shot('-card');
 const s=await state();if(s.paused){await click(400,400);await sleep(2500);}
 const item=(await state()).items.find(x=>x.type.endsWith('::PlacementItem')&&x.rect);
 if(item){
  await mark('placement-drag');const p=await point(item.rect[0]+item.rect[2]/2,item.rect[1]+item.rect[3]/2),q=await point(650,350);
  await send('Input.dispatchMouseEvent',{type:'mouseMoved',...p});await sleep(200);await send('Input.dispatchMouseEvent',{type:'mousePressed',...p,button:'left',buttons:1,clickCount:1});await sleep(200);await send('Input.dispatchMouseEvent',{type:'mouseMoved',...q,button:'left',buttons:1});await sleep(2000);await shot('-drag');await send('Input.dispatchMouseEvent',{type:'mouseReleased',...q,button:'left',buttons:0,clickCount:1});await sleep(2500);
 }
}
for(let n=1;n<=2;n++){await mark('save-open-'+n);await click(765,15);await sleep(1800);await shot('-save-'+n);await mark('save-close-'+n);await click(545,395);await sleep(1800);}
for(let n=1;n<=3;n++){await mark('map-open-'+n);await click(620,15);await sleep(2000);await mark('map-close-'+n);await click(620,15);await sleep(2000);}
for(let n=0;n<8;n++){await mark('walking-'+n);await hold(...[[750,450],[80,150],[700,220],[100,450]][n%4],5000);}
await mark('standing-end');await sleep(15000);await mark('complete');
const after=await state();
const result=await evaluate(`(()=>{
 const start=__scenarioStart,end=__scenarioEvents.at(-1).t,frames=__frameTimes.filter(x=>x.t-x.ms>=start&&x.t<=end),game=__gameFrameTimes.filter(x=>x>0),periods=__gamePerf.filter(x=>x.t-x.ms>=start);
 function stats(values){values=values.slice().sort((a,b)=>a-b);return {samples:values.length,p50:values[Math.floor(values.length*.50)],p95:values[Math.floor(values.length*.95)],p99:values[Math.floor(values.length*.99)],worst:values.at(-1),over50ms:values.filter(x=>x>50.5).length};}
 const r=document.querySelector('#player').getBoundingClientRect(),ms=periods.reduce((a,x)=>a+x.ms,0);
 return {url:location.href,viewport:[innerWidth,innerHeight],player:[r.width,r.height],pixelRatio:devicePixelRatio,quality:config.quality,renderer:__log.find(x=>x.includes('Used renderer')),metadata:player.ruffle().metadata,durationMs:end-start,gameFps:1000*periods.reduce((a,x)=>a+x.frames,0)/ms,gameFrameTimes:stats(game),wallClockGameFrameTimes:stats(__gameFrameStamps.filter(x=>x.t-x.ms>=start&&x.t<=end).map(x=>x.ms)),browserFrameTimes:stats(frames.map(x=>x.ms)),longTasks:__long.filter(x=>x.t>=start),saves:__savePerf,events:__scenarioEvents,frames,gameFrames:game,gamePeriods:periods};
})()`);
await shot('-after');
fs.writeFileSync(prefix+'.json',JSON.stringify({...result,before,after},null,2));
const {frames,gameFrames,gamePeriods,...summary}=result;console.log(JSON.stringify(summary,null,2));ws.close();
