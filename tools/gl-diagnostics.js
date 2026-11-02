// Opt-in diagnostic only. Evaluate in the dedicated test page before an action.
// Records timings/dimensions, never texture pixels or shader source.
(() => {
  if (window.__bunniGlProbe) return;
  window.__bunniGlProbe = true;
  window.__glStats = {};
  window.__glSlow = [];
  window.__glAllocations = [];
  const methods = ['createTexture','createFramebuffer','createRenderbuffer','texImage2D','texSubImage2D','texStorage2D','renderbufferStorageMultisample','bufferData','bufferSubData','readPixels','getBufferSubData','clientWaitSync','waitSync','finish','flush','compileShader','linkProgram','getProgramParameter','getShaderParameter'];
  for (const Constructor of [window.WebGLRenderingContext, window.WebGL2RenderingContext]) {
    if (!Constructor) continue;
    for (const name of methods) {
      const original = Constructor.prototype[name];
      if (typeof original !== 'function' || original.__bunniProbed) continue;
      const wrapped = function(...args) {
        const start = performance.now();
        try { return Reflect.apply(original,this,args); }
        finally {
          const end = performance.now(), ms = end-start;
          const stats = __glStats[name] ||= {calls:0,totalMs:0,maxMs:0};
          stats.calls++; stats.totalMs += ms; stats.maxMs = Math.max(stats.maxMs,ms);
          const numericArgs = () => args.slice(0,7).map(x=>typeof x === 'number' ? x : null);
          if (ms > 2) {
            __glSlow.push({t:end,ms,name,args:numericArgs()});
            if (__glSlow.length > 1024) __glSlow.shift();
          }
          if (name === 'texStorage2D' || name === 'texImage2D' || name === 'renderbufferStorageMultisample') {
            __glAllocations.push({t:end,name,args:numericArgs()});
            if (__glAllocations.length > 2048) __glAllocations.shift();
          }
        }
      };
      wrapped.__bunniProbed = true;
      Constructor.prototype[name] = wrapped;
    }
  }
})();
