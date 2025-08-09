let utterance = null;
let bestVoice = null;
let voicesLoaded = false;
const VOICE_PREF_KEY = 'ttsPreferredVoiceName';

// Heuristic: try to detect female voices on the web (no official gender field)
function isLikelyFemale(voice) {
  const name = (voice.name || '').toLowerCase();
  const femaleHints = [
    'female', 'woman', 'girl',
    'aria', 'jessa', 'jenny', 'emma', 'lisa', 'sara', 'sarah', 'salli', 'joanna', 'ivy', 'zoe', 'zoey'
  ];
  return femaleHints.some(h => name.includes(h));
}

// Rank voices: higher score = better
function rankVoice(v) {
  let score = 0;
  const name = (v.name || '').toLowerCase();
  const lang = (v.lang || '').toLowerCase();

  // Language match
  if (lang === 'en-us') score += 6;
  else if (lang.startsWith('en-')) score += 4;
  else if (lang.startsWith('en')) score += 3;

  // Vendor / quality hints
  if (name.includes('google')) score += 4;
  if (name.includes('microsoft')) score += 4;
  if (name.includes('apple') || name.includes('siri')) score += 3;
  if (name.includes('neural') || name.includes('wavenet') || name.includes('natural')) score += 3;

  // Prefer local service
  if (v.localService) score += 1;

  // Prefer likely female (requested)
  if (isLikelyFemale(v)) score += 3;

  // Penalize weak/default voices
  if (name.includes('default') || name.includes('basic') || name.includes('compact') || name.includes('android') || name.includes('native')) {
    score -= 3;
  }

  return score;
}

function pickBestVoice(voices) {
  if (!voices || !voices.length) return null;

  // Honor saved preference
  const prefName = localStorage.getItem(VOICE_PREF_KEY);
  if (prefName) {
    const chosen = voices.find(v => v.name === prefName);
    if (chosen) return chosen;
  }

  // Else highest-ranked
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

// ---- Public API ----

// Simple speak (does not await)
async function speakText(text) {
  await speakTextAndWait(text);
}

function stopSpeaking() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
}

// ✅ Speak and resolve when finished (use this for correct mic timing)
async function speakTextAndWait(text) {
  if (!('speechSynthesis' in window)) return;

  await ensureVoicesReady();
  stopSpeaking();

  return new Promise(resolve => {
    utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = bestVoice?.lang || 'en-US';
    utterance.rate = 0.9;
    utterance.pitch = 1.0;
    if (bestVoice) utterance.voice = bestVoice;

    utterance.onend = () => resolve();
    utterance.onerror = () => resolve(); // resolve to avoid blocking flow on errors

    window.speechSynthesis.speak(utterance);
  });
}

// Return TOP 5 FEMALE voice names; fallback to top 5 overall
async function getVoiceNames() {
  if (!('speechSynthesis' in window)) return [];
  await ensureVoicesReady();
  const voices = window.speechSynthesis.getVoices();

  const sorted = [...voices].sort((a, b) => rankVoice(b) - rankVoice(a));
  const femaleFirst = sorted.filter(isLikelyFemale);
  const list = (femaleFirst.length >= 5 ? femaleFirst : sorted).slice(0, 5);

  return list.map(v => v.name);
}

// Persist preferred voice by name and set it active
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

// Refresh bestVoice if voices change and no explicit preference is set
if ('speechSynthesis' in window) {
  window.speechSynthesis.onvoiceschanged = () => {
    if (!voicesLoaded) return;
    if (!localStorage.getItem(VOICE_PREF_KEY)) {
      const voices = window.speechSynthesis.getVoices();
      bestVoice = pickBestVoice(voices);
    }
  };
}
