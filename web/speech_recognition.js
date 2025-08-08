let recognizer;
let onResultCallback;

function startRecognition(callbackName) {
  onResultCallback = window[callbackName];

  if (!('webkitSpeechRecognition' in window)) {
    alert('Speech Recognition not supported in this browser');
    return;
  }

  recognizer = new webkitSpeechRecognition();
  recognizer.continuous = false;
  recognizer.interimResults = false;
  recognizer.lang = 'en-US';

  recognizer.onresult = function (event) {
    const transcript = event.results[0][0].transcript;
    if (onResultCallback) onResultCallback(transcript);
  };

  recognizer.onerror = function (event) {
    alert('Speech error: ' + event.error);
  };

  recognizer.start();
}
