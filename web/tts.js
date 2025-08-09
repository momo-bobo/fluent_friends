let utterance = null;
let bestVoice = null;
let voicesLoaded = false;
const VOICE_PREF_KEY = 'ttsPreferredVoiceName';

// Rank voices: higher score = better
function rankVoice(v) {
  let score = 0;
  const name = (v.name || '').toLowerCase();
  const lang = (v.lang || '').toLowerCase();

  if (lang === 'en-us') score += 6;
  else if (lang.startsWith('en-')) score += 4;
  else if (lang.startsWith('en')) score += 3;

  if (name.includes('google')) score += 4;
  if (name.includes('microsoft')) score += 4;
  if (name.includes('apple') || name.includes('siri')) score += 3;
  if (name.includes('neural') || name.includes('wavenet') || name.includes('natural')) score += 3;

  if (v.localService) score += 1;

  if (name.includes('default') || name.includes('basic') || name.includes('compact') || name.includes('android') || name.includes('native')) {
    score -= 3;
  }

  return score;
}

function pickBestVoice(voices) {
  if (!voices || !voices.length) return null;

  const prefName = localStorage.getItem(VOICE_PREF_KEY);
  if (prefName) {
    const chosen = voices.find(v => v.name === prefName);
    if (chosen) return chosen;
  }

  let best = null;
  let bestScore = -Infinity;
  for (const v of voices) {
    const s = rankVoice(v);
    if (s > bestScore) {
      best = v;
      bestScore = s;
    }
  }
  return best;
}

function ensureVoicesReady() {
  return new Promise(resolve => {
    const tryLoad = () => {
      const voices = window.speechSynthesis.getVoices();
      if (voices && voices.length) {
        bestVoice = pickBestVoice(voices);
        voicesLoaded = true;
        resolve();
      } else {
        setTimeout(tryLoad, 100);
      }
    };
    tryLoad();
  });
}

async function speakText(text) {
  if (!('speechSynthesis' in window)) {
    alert('Text-to-Speech not supported in this browser');
    return;
  }
  await ensureVoicesReady();

  stopSpeaking();

  utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = bestVoice?.lang || 'en-US';
  utterance.rate = 0.9;
  utterance.pitch = 1.0;
  if (bestVoice) utterance.voice = bestVoice;

  window.speechSynthesis.speak(utterance);
}

function stopSpeaking() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
}

// New: return array of voice names for UI
async function getVoiceNames() {
  if (!('speechSynthesis' in window)) return [];
  await ensureVoicesReady();
  const voices = window.speechSynthesis.getVoices();
  return voices.map(v => v.name);
}

// New: set preferred voice by name (persists)
function setPreferredVoiceByName(name) {
  if (!('speechSynthesis' in window)) return false;
  const voices = window.speechSynthesis.getVoices();
  const match = voices.find(v => v.name === name);
  if (match) {
    localStorage.setItem(VOICE_PREF_KEY, name);
    bestVoice = match;
    return true;
  }
  return false;
}

// Keep bestVoice fresh if voices change
if ('speechSynthesis' in window) {
  window.speechSynthesis.onvoiceschanged = () => {
    if (!voicesLoaded) return;
    if (!localStorage.getItem(VOICE_PREF_KEY)) {
      const voices = window.speechSynthesis.getVoices();
      bestVoice = pickBestVoice(voices);
    }
  };
}
