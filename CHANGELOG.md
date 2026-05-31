# Changelog

All notable changes to FrontierCast are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.0] - 2026-05-29

### Added
- Swipe a downloaded episode left in the Downloads tab to remove it and free
  up space. A snackbar with "Undo" appears (Undo re-downloads the episode).
  The existing tap-on-the-green-check shortcut still works.

## [1.5.0] - 2026-05-28

### Added
- Episodes whose audio source fails to load (e.g. a 404 — the publisher removed
  or moved it) are now greyed out and tagged "Unavailable" in the episode list,
  so a still-playable newer episode stands out. The flag clears automatically on
  a successful play or when a feed refresh re-confirms the episode (drift schema
  v9). Transient network failures don't grey episodes.

## [1.4.1] - 2026-05-28

### Fixed
- The mini-player no longer slides under Android's gesture/navigation bar on a
  podcast's episode list. It now respects the bottom system inset when it's the
  bottom-most bar (it didn't need to in the main tabs, where the navigation bar
  already absorbs that inset).

## [1.4.0] - 2026-05-25

### Added
- Real transcription progress. The Mac server now streams progress as it
  downloads the audio and as Whisper works, so the transcript buttons show a
  filling progress circle (with a "Downloading… / Transcribing… N%" label on the
  transcript screen) instead of an indeterminate spinner.
- View the episode description from the Now Playing screen — tap the info
  button in the top bar to open a bottom sheet with the full show notes.

### Changed
- The transcription server streams NDJSON progress over a single request. **The
  Python server must be restarted** to pick this up; older app builds remain
  compatible only with the old server, so update both together.

### Fixed
- Playback failures now surface a snackbar with a friendly message (e.g.
  "Episode unavailable — the audio file couldn’t be loaded. The publisher may
  have removed or moved it.") instead of silently doing nothing — episodes that
  have been dropped from a feed or whose CDN URL has expired are no longer
  mystery dead taps.

## [1.3.1] - 2026-05-24

### Changed
- Transcription progress is now tracked app-wide: the transcript buttons (Now
  Playing, episode sheet, transcript screen) show a spinner while transcribing
  and switch to the filled icon when it's done — even if you navigate away and
  back while the Mac is working.

## [1.3.0] - 2026-05-24

### Added
- Transcript button in the Now Playing screen, so you can open (or generate)
  the transcript of the current episode without leaving the player. The icon
  is filled when a transcript already exists.

## [1.2.1] - 2026-05-24

### Fixed
- Episode/podcast titles with UTF-8 characters (curly apostrophes, em-dashes,
  accents, emoji) no longer appear garbled. Feeds that omit a charset from
  their HTTP Content-Type are now decoded as UTF-8 instead of Latin-1.

## [1.2.0] - 2026-05-23

### Added
- Subscribe directly from the Search tab by pasting an RSS feed URL: the app
  fetches and previews the feed (title, author, artwork) and lets you
  subscribe in one tap. Covers podcasts that aren't in the iTunes catalog,
  such as members-only feeds.
- Podcast Index as a second search source, merged with iTunes results and
  de-duplicated by feed. Enable it by entering a free Podcast Index API key
  and secret in Settings → Search; credentials are stored on-device only.

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

[Unreleased]: https://github.com/frontierviking/frontiercast-public/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.4.0
[1.3.1]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.3.1
[1.3.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.3.0
[1.2.1]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.2.1
[1.2.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.2.0
[1.1.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.1.0
[1.0.0]: https://github.com/frontierviking/frontiercast-public/releases/tag/v1.0.0
