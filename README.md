# FrontierCast

A personal, ad-free Android podcast player built with Flutter. "Ad-free" means
the app shows **no in-app ads** — ads baked into podcast audio are left
untouched. It's meant to be sideloaded (no Play Store).

## Features

- Subscribe via **iTunes search**, **OPML import**, or **add-by-URL**
- Library grid with unplayed-episode badges; episode lists with artwork
- **Playback** with lock-screen / notification controls, speed, buffering states
- **Up-next queue** with reorder + auto-advance
- **Sleep timer** (timed or end-of-episode)
- **Configurable skip** forward/back (5–60s or custom; long-press the skip buttons)
- **Downloads** for offline listening
- **Sharing** that links to the episode/show's original source
- Optional **Whisper transcription** via a small local server (see below)

## Requirements

- **Flutter** stable **3.44+** (bundles Dart)
- **JDK 17** (e.g. Temurin or `openjdk@17`)
- **Android SDK** with platform-tools, platform 36, build-tools
- A device on **Android 8.0+** (minSdk 26)

The Android Gradle toolchain is pinned in the repo (AGP 8.11.1 / Gradle 8.14 /
Kotlin 2.2.20), which is the combination this project builds cleanly with on
Flutter 3.44.

## Build & run

```bash
flutter pub get
# generate the drift database code
dart run build_runner build
# run on a connected device…
flutter run
# …or produce a debug APK to sideload
flutter build apk --debug
```

> Tip: if the first Android build flakes on a `libsqlite3` download, just re-run
> it — that's a transient network fetch from a native plugin.

## Transcription (optional)

Transcription runs **on your own machine** (designed for an Apple Silicon Mac
with [`mlx-whisper`](https://pypi.org/project/mlx-whisper/)), reached from the
phone over your LAN or Tailscale.

1. In a Python env that has `mlx_whisper` and `httpx`, set a token and run the
   server:
   ```bash
   FRONTIERCAST_TOKEN="your-secret" python server/frontiercast_server.py
   ```
   It listens on `:8765` and writes transcripts to
   `~/Documents/AI/podcasts/transcripts`.
2. In the app: **Settings → Transcription** — set the **Server URL**
   (`http://<your-computer-ip>:8765`) and the **same token**, then **Test
   connection**.
3. On any episode, open it and tap **Transcribe**.

## Notes

- The bundled OPML is just a 2-feed **sample** — import your own export or add
  feeds by URL.
- Package id is `com.martin.frontiercast`; change it in
  `android/app/build.gradle.kts` if you like.
- Built with the help of Claude Code.
