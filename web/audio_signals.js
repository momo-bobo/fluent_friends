// ------- Singleton AudioContext with auto-resume --------
let _AUDIO_CTX = null;
function _getCtx() {
  if (!_AUDIO_CTX) {
    _AUDIO_CTX = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (_AUDIO_CTX.state === 'suspended') {
    // Try to resume; will succeed after a user gesture
    _AUDIO_CTX.resume().catch(() => {});
  }
  return _AUDIO_CTX;
}

// Soft sine beep with tiny fade in/out to avoid clicks
function playBeep(freq, durationMs) {
  try {
    const ctx = _getCtx();
    const dur = Math.max(0.08, (durationMs || 150) / 1000); // seconds
    const now = ctx.currentTime + 0.01; // tiny scheduling offset

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq || 800, now);

    // gentle envelope
    gain.gain.setValueAtTime(0.0, now);
    gain.gain.linearRampToValueAtTime(0.08, now + 0.02);    // fade in
    gain.gain.linearRampToValueAtTime(0.0, now + dur - 0.02); // fade out

    osc.connect(gain).connect(ctx.destination);
    osc.start(now);
    osc.stop(now + dur);

    osc.onended = () => {
      try { osc.disconnect(); } catch (_) {}
      try { gain.disconnect(); } catch (_) {}
    };
  } catch (_) {
    // ignore
  }
}

// --------- Mic level (unchanged) ----------
let _meter = { ctx: null, src: null, analyser: null, raf: null, stream: null };
function startMicLevel(onLevel) {
  stopMicLevel();
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return;
  navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
    const ctx = _getCtx();
    const src = ctx.createMediaStreamSource(stream);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 512;
    src.connect(analyser);

    const data = new Uint8Array(analyser.fftSize);
    function tick() {
      analyser.getByteTimeDomainData(data);
      let sum = 0;
      for (let i = 0; i < data.length; i++) {
        const v = (data[i] - 128) / 128.0;
        sum += v * v;
      }
      let rms = Math.sqrt(sum / data.length);
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
  if (_meter.stream) {
    try { _meter.stream.getTracks().forEach(t => t.stop()); } catch (_) {}
  }
  _meter = { ctx: _meter.ctx, src: null, analyser: null, raf: null, stream: null };
}
