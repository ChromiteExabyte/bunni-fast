// Reference for OS/browser animation callback dispatch, without Flash or Ruffle.
// Use only against the dedicated local-test browser identified by CDP_PORT.
import fs from 'node:fs';
const port=process.env.CDP_PORT||9341,prefix=process.argv[2];
if(!prefix)throw new Error('Usage: raf-control.mjs output.json');
const target=(await(await fetch(`http://localhost:${port}/json`)).json()).find(x=>x.type==='page');
if(!target.url.startsWith('http://localhost:'))throw new Error('Expected isolated local game tab.');
const ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise(r=>ws.addEventListener('open',r,{once:true}));
let id=0;const pending=new Map();ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id&&pending.has(m.id)){pending.get(m.id)(m);pending.delete(m.id);}});
const send=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,m=>m.error?reject(new Error(JSON.stringify(m.error))):resolve(m.result));ws.send(JSON.stringify({id:n,method,params}));});
const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
await send('Page.navigate',{url:'about:blank'});await new Promise(r=>setTimeout(r,1000));
await evaluate('window.__phaseFrame=0;window.__rafProbeSeconds=20;let n=0;function control(){if(++n%2===0)++window.__phaseFrame;requestAnimationFrame(control)};requestAnimationFrame(control);');
const data=await evaluate(fs.readFileSync(new URL('./raf-probe.js',import.meta.url),'utf8'));
fs.writeFileSync(prefix,JSON.stringify({kind:'blank-page-reference',...data},null,2));
console.log(JSON.stringify(data.groups,null,2));ws.close();
