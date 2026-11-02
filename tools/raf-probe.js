(() => new Promise(resolve => {
  const original = window.requestAnimationFrame, ids = new WeakMap(), events = [];
  let next = 0;
  const start = performance.now();
  window.requestAnimationFrame = function(callback) {
    if (!ids.has(callback)) ids.set(callback,++next);
    const id = ids.get(callback);
    return original.call(window,function(stamp) {
      const before = window.__phaseFrame || 0, begin = performance.now();
      try { callback(stamp); }
      finally { events.push({id,name:callback.name,stamp,begin,end:performance.now(),frames:(window.__phaseFrame||0)-before}); }
    });
  };
  setTimeout(() => {
    window.requestAnimationFrame = original;
    const end = performance.now(), all = events.filter(x=>x.begin>=start&&x.end<=end);
    function stats(values) { values=values.slice().sort((a,b)=>a-b); return {n:values.length,p50:values[values.length>>1],p95:values[Math.floor(values.length*.95)],p99:values[Math.floor(values.length*.99)],max:values.at(-1)}; }
    const groups = [...new Set(all.map(x=>x.id))].map(id=> {
      const e=all.filter(x=>x.id===id), g=e.filter(x=>x.frames>0), late=[];
      for(let i=1;i<g.length;i++)if(g[i].stamp-g[i-1].stamp>44) {
        late.push({delta:g[i].stamp-g[i-1].stamp,previous:g[i-1].stamp,current:g[i].stamp,skipped:e.filter(x=>x.stamp>g[i-1].stamp&&x.stamp<g[i].stamp).map(x=>({since:x.stamp-g[i-1].stamp,cpu:x.end-x.begin}))});
      }
      return {id,name:e[0]?.name,cpu:stats(e.map(x=>x.end-x.begin)),rafIntervals:stats(e.slice(1).map((x,i)=>x.stamp-e[i].stamp)),gameIntervals:stats(g.slice(1).map((x,i)=>x.stamp-g[i].stamp)),gameFrames:g.reduce((a,x)=>a+x.frames,0),late:late.slice(-20)};
    });
    resolve({start,end,groups,events:all});
  }, (window.__rafProbeSeconds||20)*1000);
}))()
