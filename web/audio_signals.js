// Simple oscillator beep
function playBeep(freq, durationMs) {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    gain.gain.value = 0.05; // soft
    osc.connect(gain).connect(ctx.destination);
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, durationMs || 150);
  } catch (e) {
    // ignore
  }
}

// Mic level meter (dispatches levels to Dart via callback)
let _meter = { ctx: null, src: null, analyser: null, raf: null, stream: null };
function startMicLevel(onLevel) {
  stopMicLevel();
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return;
  navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const src = ctx.createMediaStreamSource(stream);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 512;
    src.connect(analyser);

    const data = new Uint8Array(analyser.fftSize);
    function tick() {
      analyser.getByteTimeDomainData(data);
      // Compute RMS
      let sum = 0;
      for (let i = 0; i < data.length; i++) {
        const v = (data[i] - 128) / 128.0;
        sum += v * v;
      }
      let rms = Math.sqrt(sum / data.length);
      // Map to 0..1 with a mild curve
      const level = Math.max(0, Math.min(1, rms * 2));
      try { onLevel(level); } catch (e) {}
      _meter.raf = requestAnimationFrame(tick);
    }
    tick();

    _meter = { ctx, src, analyser, raf: _meter.raf, stream };
  }).catch(() => {});
}

function stopMicLevel() {
  if (_meter.raf) cancelAnimationFrame(_meter.raf);
  if (_meter.ctx) try { _meter.ctx.close(); } catch (e) {}
  if (_meter.stream) {
    _meter.stream.getTracks().forEach(t => t.stop());
  }
  _meter = { ctx: null, src: null, analyser: null, raf: null, stream: null };
}
