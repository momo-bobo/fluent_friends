let utterance = null;

function speakText(text) {
  if (!('speechSynthesis' in window)) {
    alert('Text-to-Speech not supported in this browser');
    return;
  }
  stopSpeaking();
  utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'en-US';
  utterance.rate = 0.9;
  utterance.pitch = 1.0;
  window.speechSynthesis.speak(utterance);
}

function stopSpeaking() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
}
