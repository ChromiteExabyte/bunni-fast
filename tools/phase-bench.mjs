import fs from 'node:fs';
const prefix=process.argv[2],port=process.env.CDP_PORT||9341;
const page=(await(await fetch(`http://localhost:${port}/json`)).json()).find(x=>x.type==='page');
const ws=new WebSocket(page.webSocketDebuggerUrl);await new Promise(r=>ws.addEventListener('open',r,{once:true}));let id=0;const pending=new Map();
ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id&&pending.has(m.id)){pending.get(m.id)(m.result);pending.delete(m.id);}});
const send=(method,params={})=>new Promise(r=>{const n=++id;pending.set(n,r);ws.send(JSON.stringify({id:n,method,params}));});
const evaluate=async expression=>(await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true})).result.value;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const shot=async suffix=>fs.writeFileSync(prefix+suffix+'.png',Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
async function hold(x,y,ms){const b=await evaluate('(()=>{let b=document.querySelector("#player").getBoundingClientRect();return [b.left,b.top,b.width,b.height]})()');const p={x:b[0]+x*b[2]/800,y:b[1]+y*b[3]/600};await send('Input.dispatchMouseEvent',{type:'mouseMoved',...p});await send('Input.dispatchMouseEvent',{type:'mousePressed',...p,button:'left',clickCount:1});await sleep(ms);await send('Input.dispatchMouseEvent',{type:'mouseReleased',...p,button:'left',clickCount:1});}
await shot('-before');await evaluate('__phasePerf=[];__frameStarts=[];__gameFrameStamps=[];__lastGameStamp=0;__phaseStart=performance.now();');
console.log('standing15');await sleep(15000);console.log('walking12');await hold(750,350,6000);await hold(90,250,6000);console.log('standing10');await sleep(10000);
const data=await evaluate('({phases:__phasePerf,starts:__frameStarts,ends:__gameFrameStamps,viewport:[innerWidth,innerHeight],url:location.href,quality:config.quality})');
function stats(a){a=a.slice().sort((x,y)=>x-y);return{n:a.length,p50:a[a.length>>1],p95:a[Math.floor(a.length*.95)],p99:a[Math.floor(a.length*.99)],max:a.at(-1)};}
const phases={};for(const phase of data.phases)(phases[phase.name]??=[]).push(phase.ms);
const starts=new Map(data.starts.map(x=>[x.frame,x.t]));const cpu=data.phases.filter(x=>x.name==='saved'&&starts.has(x.frame)).map(x=>({frame:x.frame,t:x.t,ms:x.t-starts.get(x.frame)}));
const summary={url:data.url,viewport:data.viewport,quality:data.quality,phases:Object.fromEntries(Object.entries(phases).map(([k,v])=>[k,stats(v)])),cpu:stats(cpu.map(x=>x.ms)),startIntervals:stats(data.starts.slice(1).map((x,i)=>x.t-data.starts[i].t)),endIntervals:stats(data.ends.map(x=>x.ms)),slowCpu:cpu.filter(x=>x.ms>15)};
fs.writeFileSync(prefix+'.json',JSON.stringify({...data,summary},null,2));console.log(JSON.stringify(summary,null,2));await shot('-after');ws.close();
