# Fluent Friends (Unified Flutter App)

Fluent Friends is a speech therapy app for children who stutter. This project uses a shared Flutter codebase for both **mobile** and **web** platforms.

## 🚀 Features
- 🎤 Voice recognition using:
  - `speech_to_text` on Android/iOS
  - Web Speech API via JavaScript interop on Web
- 🎯 Sound-specific pronunciation practice
- 👄 Visual feedback with diagrams
- 📊 Progress tracking and positive reinforcement
- 🔁 3 tries per sound, then move forward

## 🛠 Tech Stack
- Flutter
- speech_to_text
- fl_chart
- dart:js interop
- Conditional imports for platform-specific logic

## 📂 Project Structure
```
lib/
  main.dart
  services/
    speech_service.dart          # conditional switch
    speech_service_mobile.dart
    speech_service_web.dart
    speech_service_stub.dart
  web_speech_bridge.dart

web/
  index.html
  speech_recognition.js
```

## ✅ How to Run

### Mobile:
```bash
flutter pub get
flutter run -d android  # or ios
```

### Web:
```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome
```

## 🌐 Deploying Web App
```bash
flutter build web
```
Host the contents of `build/web/` on:
- Firebase Hosting
- GitHub Pages
- Netlify
- Vercel

## 📦 Version Control
1. `git init`
2. `git remote add origin https://github.com/YOUR_USERNAME/fluent_friends.git`
3. `git add .`
4. `git commit -m "Initial commit"`
5. `git push -u origin main`

---

Happy learning and speaking! 🎉