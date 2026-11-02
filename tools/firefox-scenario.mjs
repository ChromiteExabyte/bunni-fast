// Bounded Firefox smoke/pacing test against an already loaded isolated WebDriver session.
import fs from 'node:fs';
const prefix=process.argv[2],sessionFile=process.env.FIREFOX_SESSION_FILE||'.tools/candidate-high/firefox-session.json';
if(!prefix)throw new Error('Usage: firefox-scenario.mjs evidence-prefix');
const {id}=JSON.parse(fs.readFileSync(sessionFile));
const endpoint=process.env.WEBDRIVER_URL||'http://127.0.0.1:4444';
async function request(path,body){const r=await fetch(endpoint+'/session/'+id+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(45000)});const d=await r.json();if(!r.ok||d.value?.error)throw new Error(JSON.stringify(d.value));return d.value;}
const evaluate=expression=>request('/execute/sync',{script:'return eval(arguments[0]);',args:[expression]});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function click(x,y,hold=80){const b=await evaluate('(()=>{const r=document.querySelector("#player").getBoundingClientRect();return [r.left,r.top,r.width,r.height]})()');await request('/actions',{actions:[{type:'pointer',id:'scenario-mouse',parameters:{pointerType:'mouse'},actions:[{type:'pointerMove',origin:'viewport',x:Math.round(b[0]+x*b[2]/800),y:Math.round(b[1]+y*b[3]/600),duration:0},{type:'pause',duration:150},{type:'pointerDown',button:0},{type:'pause',duration:hold},{type:'pointerUp',button:0}]}]});}
async function shot(suffix){const r=await fetch(endpoint+'/session/'+id+'/screenshot');const d=await r.json();if(!r.ok)throw new Error(JSON.stringify(d));fs.writeFileSync(prefix+suffix+'.png',Buffer.from(d.value,'base64'));}
const before=JSON.parse(await evaluate('document.querySelector("ruffle-player").ruffle().callExternalInterface("bunniBenchState")'));if(before.paused||before.map)throw new Error('Begin in unpaused game world.');
await shot('-before');const start=await evaluate('performance.now()');
console.log('stand10');await sleep(10000);
for(let i=0;i<4;i++){console.log('walk'+i);await click(...[[740,400],[100,450],[650,200],[200,220]][i],5000);}
for(let i=0;i<2;i++){console.log('save'+i);await click(765,15);await sleep(1000);await click(545,395);await sleep(1000);}
for(let i=0;i<2;i++){console.log('map'+i);await click(620,15);await sleep(1000);await click(620,15);await sleep(1000);}
console.log('stand10-end');await sleep(10000);
const data=await evaluate('(()=>{const start='+start+',end=performance.now(),r=document.querySelector("#player").getBoundingClientRect();return {start,end,url:location.href,viewport:[innerWidth,innerHeight],player:[r.width,r.height],quality:window.RufflePlayer.config.quality,frames:__gameFrameStamps.filter(x=>x.t-x.ms>=start&&x.t<=end),periods:__gamePerf.filter(x=>x.t-x.ms>=start&&x.t<=end),browser:__frameTimes.filter(x=>x.t-x.ms>=start&&x.t<=end),saves:__savePerf.filter(x=>x.t>=start&&x.t<=end),state:JSON.parse(document.querySelector("ruffle-player").ruffle().callExternalInterface("bunniBenchState")),render:document.querySelector("ruffle-player").ruffle().callExternalInterface("bunniBenchRenderInfo")}})()');
function stats(a){a=a.slice().sort((a,b)=>a-b);return {n:a.length,p50:a[a.length>>1],p95:a[Math.floor(a.length*.95)],p99:a[Math.floor(a.length*.99)],max:a.at(-1)};}
const ms=data.periods.reduce((n,x)=>n+x.ms,0);data.summary={gameFps:data.periods.reduce((n,x)=>n+x.frames,0)*1000/ms,wall:stats(data.frames.map(x=>x.ms)),browser:stats(data.browser.map(x=>x.ms)),state:data.state};
fs.writeFileSync(prefix+'.json',JSON.stringify({before,...data},null,2));await shot('-after');console.log(JSON.stringify({viewport:data.viewport,player:data.player,quality:data.quality,...data.summary},null,2));
