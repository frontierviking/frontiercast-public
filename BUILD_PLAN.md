# FrontierCast — Build Plan

A personal, ad-free Android podcast player (Flutter). "Ad-free" means **no in-app
ads** — ads baked into podcast audio are intentionally left untouched. Single user
(the owner), sideloaded APK, no Play Store.

> This file is the spec/brief. Open a fresh Claude Code session in this directory and
> tell it to follow `BUILD_PLAN.md`, starting at Phase 0.

---

## Target device & build
- **Device**: Samsung Galaxy S22 Ultra — One UI 6 / Android 14, arm64-v8a
- **SDKs**: `compileSdk` 34, `targetSdk` 34, `minSdk` 26
- **Package id**: `com.martin.frontiercast` (adjust if desired)
- **Dev loop**: USB debugging + `flutter run` for iteration; `flutter build apk --release` → sideload for installs
- **Signing**: create a release keystore once so update-over-install works cleanly

---

## Stack (decided)
| Layer | Choice |
|---|---|
| UI | Flutter + Material 3 (dark default) |
| State management | **Riverpod** (async notifiers) |
| Local DB | **drift** (SQLite, type-safe) |
| Audio playback | `just_audio` + `just_audio_background` (lock-screen/notification + foreground service) |
| Feed parsing | `webfeed` (or `dart_rss`) — must handle iTunes/podcast namespaces |
| Podcast search | iTunes Search API for v1 (no key); Podcast Index API as later upgrade |
| Downloads | `background_downloader` (resumable) |
| KV settings | `shared_preferences` |
| Images | `cached_network_image` |
| Periodic refresh | `workmanager` (Phase 4) |

---

## Data model (drift tables)
- **Podcasts**: id (pk), title, feedUrl (unique), imageUrl, author, description, lastFetched
- **Episodes**: id (pk), podcastId (fk), guid (unique per podcast), title, showNotes,
  audioUrl, durationMs, pubDate, localPath (nullable), downloadState (enum),
  positionMs (default 0), isPlayed (bool)
- **Transcripts** (Phase 5): episodeId (fk, unique), text, language, createdAt
- Indexes: Episodes(podcastId), Episodes(guid)

---

## Folder structure
```
lib/
  main.dart
  app.dart                 # MaterialApp + theme + router
  data/
    db/                    # drift database + tables + DAOs
    feed/                  # RSS fetch + parse
    search/                # iTunes Search API client
    repositories/          # PodcastRepository, EpisodeRepository
    transcribe/            # Whisper API client (Phase 5)
  domain/                  # plain models / enums
  features/
    library/
    search/
    podcast_detail/
    player/
    settings/
  services/
    audio_handler.dart     # just_audio_background wiring
```

---

## Phases

### Phase 0 — Scaffold
- [ ] `flutter create` here; set package id; configure compile/target/minSdk
- [ ] Add all deps listed above
- [ ] drift tables (Podcasts, Episodes) + generated DAOs
- [ ] Material 3 theme, dark default, basic bottom-nav shell (Library / Search / Settings)
- [ ] Riverpod ProviderScope in main()

### Phase 1 — Feeds, search & library
- [ ] **In-app search** via iTunes Search API: query → results w/ artwork → tap → resolve feedUrl → subscribe
- [ ] **OPML import** (Castbox export): file picker → parse → bulk subscribe
- [ ] Manual "add by feed URL" fallback
- [ ] Feed fetch + parse → upsert podcast + episodes into drift
- [ ] Library screen (subscribed grid) + Podcast detail (episode list) + pull-to-refresh
- [ ] Repositories exposed via Riverpod async notifiers

### Phase 2 — Playback  ← **v1 milestone**
- [ ] Init `just_audio_background` in main() (notification channel, foreground service)
- [ ] AudioHandler: load episode as MediaItem (title, artwork, duration)
- [ ] Now Playing screen: artwork, scrubber, play/pause/skip ±30s, **speed control**, buffering states
- [ ] Lock-screen / notification controls
- [ ] Persist positionMs periodically + on pause/stop; resume on reopen
- [ ] Auto-mark isPlayed at ~95%
- [ ] Stream-first (no download yet)

### Phase 3 — Downloads / offline
- [ ] Resumable downloads via background_downloader; store under app docs dir
- [ ] Offline playback from localPath; storage usage view; delete

### Phase 4 — Quality of life
- [ ] Sleep timer, up-next queue, in-library search
- [ ] Auto-refresh + auto-download new episodes (workmanager)
- [ ] Playback history; chapters (podcast:chapters / ID3) if present

### Phase 5 — Whisper hook
- **Mac server**: small FastAPI app wrapping existing mlx-whisper pipeline at
  `~/Documents/AI/podcast_transcriber.py`. Endpoint `POST /transcribe {audio_url, language}`
  → downloads, transcribes (mlx-community/whisper-medium-mlx), returns `{text}`.
  Cache by episode GUID. Bearer-token auth.
- **Connectivity**: phone → Mac over **Tailscale** (stable hostname, works off-LAN).
  Fallback: same-Wi-Fi LAN IP.
- **App**: "Transcribe" button on episode detail → call endpoint → show scrollable text →
  store in Transcripts table for offline reuse.

---

## Notes / rationale
- On-device Whisper on a phone is too heavy; the Mac-server design reuses the already-tuned
  mlx pipeline. Only works when the Mac is reachable — acceptable for personal use.
- Keep audio ads: removes the only hard problem (dynamic ad detection). "No ads" = the app's
  own UI shows none.
- iTunes Search API chosen for zero-setup v1 search; Podcast Index API is a drop-in upgrade
  for better metadata later.

## Open items to confirm at build time
- Release keystore creation (needed before first sideload you want to update later)
- Tailscale installed on both Mac and phone (for Phase 5)
