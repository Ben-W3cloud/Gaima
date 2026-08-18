# Gaima

Privacy-first, fully on-device AI chatbot for Android — no servers, no accounts, no analytics. Chat with a local LLM entirely offline after a one-time model download.

![platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![license](https://img.shields.io/badge/license-MIT-blue)
![status](https://img.shields.io/badge/status-in%20development-yellow)

---

## Overview

Gaima is a ChatGPT-style mobile chatbot that runs **100% on-device**. After downloading a quantized Gemma-2B model on first launch (~1.5GB, one time, Wi-Fi recommended), the app works entirely without an internet connection — no API calls, no data leaving the phone, no telemetry.

Built to demonstrate on-device LLM inference on mobile, Flutter isolate architecture, and offline-first app design.

## Features

- 🔒 **Fully offline inference** — chat runs locally via `llama.cpp`, nothing sent to a server
- 💬 **Multi-session chat** — ChatGPT-style sidebar, independent history per session
- 🧠 **Live streaming responses** with a collapsible "Thinking..." view and Stop control
- 🧵 **Rolling context management** — automatic 2,048-token window with an OOM safety guard
- 💾 **Local persistence** — full chat history stored on-device via Sqflite
- 🎨 **Light & dark mode** — custom white/brown theme, fully token-driven
- 📦 **Minimal install size** — model is fetched on first launch, not bundled in the APK

## Tech Stack

| Layer | Tool |
|---|---|
| Framework | Flutter (Android) |
| Inference | `llama_cpp_dart` (llama.cpp FFI) |
| Model | Gemma-2B-Instruct (Q4 GGUF) |
| Storage | Sqflite |
| Networking | Dio |
| State management | Riverpod |
| Markdown rendering | `flutter_markdown` |

## Requirements

- Android device with 6–8GB+ RAM recommended
- ~2GB free storage for the model
- Wi-Fi connection for the initial model download only

## Getting Started

```bash
# Clone the repo
git clone https://github.com/yourusername/offline-gemma-chat.git
cd offline-gemma-chat

# Install dependencies
flutter pub get

# Run on a connected Android device
flutter run
```

On first launch, the app will download the Gemma-2B model (~1.5GB). Keep the device on Wi-Fi until the download completes.

## Project Status

🚧 Actively in development. Core chat loop, model download, and persistence are the current focus. See [Roadmap](#roadmap) below.

## Roadmap

- [x] Model provisioning & download flow
- [x] On-device inference pipeline
- [x] Multi-session chat with local persistence
- [x] Streaming responses with collapsible thinking view
- [ ] Haptic feedback during streaming
- [ ] Custom character/system prompt presets
- [ ] iOS support

## Disclaimer

This app runs a quantized language model locally on your device. Generation speed and quality are constrained by on-device hardware — expect 5–15 tokens/sec depending on your phone. Extended use may cause the device to warm up and throttle performance. Text input/output only; no image support.

## License

MIT — see [LICENSE](LICENSE) for details. Note: the Gemma model itself is distributed under Google's own license terms, separate from this repository's code license — review Gemma's terms before redistribution or commercial use.

## Acknowledgements

- [llama.cpp](https://github.com/ggerganov/llama.cpp) for the inference engine
- [Google DeepMind](https://ai.google.dev/gemma) for the Gemma model family