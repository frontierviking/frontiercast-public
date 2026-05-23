# Changelog

All notable changes to FrontierCast are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-05-23

### Added
- Library sort menu (Manual, Alphabetical, Date added, Recently updated,
  Unplayed first), defaulting to Manual.
- Manual drag-reorder of the library grid — long-press a tile and drag; the
  order persists across launches.
- "Mark all episodes as played" action in Settings.
- Quiet background refresh of all feeds on app open and resume (throttled so
  foreground switches don't hammer the network).

### Changed
- Feed parsing now runs on a background isolate, and the startup refresh is
  deferred a few seconds, so the app stays responsive at launch.
- Switched to release (AOT) builds for daily use — smooth scrolling throughout.
- Playback prefers the downloaded file whenever it exists, and switches a
  streaming episode over to its local file once the download finishes.
- Removed pull-to-refresh from the Library (refresh lives in Settings and also
  runs automatically on open).

### Fixed
- Downloaded episodes no longer stream from the network; a dropped stream no
  longer wedges playback — it recovers at your last saved position.
- Now Playing reflects the real download state instead of a stale snapshot.
- A dropped stream's premature "completed" no longer marks a long episode as
  played or loses your place.

## [1.0.0] - 2026-05-22

Initial release — a personal, ad-free Android podcast player.

### Added
- Subscriptions: OPML import (bundled + file/URL), iTunes search, and RSS/Atom
  feed parsing.
- Playback via just_audio + audio_service with lock-screen/notification controls
  and configurable skip intervals (including 5s and custom; long-press to
  change).
- Downloads / offline listening with per-episode state and color-coded
  indicators.
- Sleep timer, up-next queue, and in-library search.
- Whisper transcription: a local Mac server plus in-app transcript viewing.
- Castbox-inspired UI: red accent, true-black theme, blurred podcast header with
  an edge-straddling subscribe button, per-episode artwork, unplayed
  badges/dots, and an episode detail sheet with one-tap play.
- Share a podcast or an episode via its original source link.
- Now Playing screen with download button, queue, sleep timer, and instant open.
- README with features, build/run, and transcription setup.

[Unreleased]: https://github.com/frontierviking/frontiercast-public/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.1.0
[1.0.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.0.0
