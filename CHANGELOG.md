# Changelog

All notable changes to FrontierCast are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.14.0] - 2026-09-04

### Added
- **Backup & transfer** in Settings, for moving to a new phone (the app has no
  cloud sync, so everything lived in one file on the device with no way out).
  - *Back up everything* writes a consistent snapshot via `VACUUM INTO` — a raw
    file copy can miss recent writes sitting in the WAL — covering
    subscriptions, played state, positions, transcripts and the manual order.
  - *Restore from backup* stages the picked file and swaps it in on the next
    launch, before SQLite opens anything; overwriting a live database corrupts
    it. The staged file is header-checked first, and the outgoing database is
    kept as `.pre-restore` rather than deleted, so a bad restore can't destroy
    a working library.
  - *Export subscriptions (OPML)* for a portable, any-app-readable copy.

## [1.13.0] - 2026-08-22

### Changed
- Progress keeps flowing after a dropped connection. The server now tracks live
  stage/progress per job and reports it from `/transcript`, so a phone that lost
  the streaming connection shows a real percentage instead of an indeterminate
  bar for the rest of the run.
- Clearer wording while a job runs in the background: "Transcribing on your Mac
  — running in the background, safe to leave this screen" replaces the
  alarming-sounding "Reconnected — waiting for the result".

### Changed (server)
- **Restart the transcription server** to pick up per-job progress tracking on
  the `/transcript` poll endpoint.

## [1.12.0] - 2026-08-21

### Changed
- The transcript screen now shows a progress **bar** instead of a spinner while
  a transcription runs, with the stage as a headline ("Transcribing on your
  Mac"), a plain-language sub-label, and the percentage beside the bar. Easier
  to tell at a glance that a long run is alive and how far along it is.

### Added
- `tools/serve-apk.sh` — serves the release APK over Tailscale for install from
  the phone's browser. `adb` can't complete its TLS handshake over a Tailscale
  DERP relay, so this is the deploy path when away from the home network (or on
  guest Wi-Fi that blocks device-to-device traffic). Supports HTTP Range, so a
  dropped transfer resumes instead of restarting.

## [1.11.0] - 2026-08-04

### Added
- LAN auto-discovery for the transcription server. If no configured address
  answers, the app sweeps its own /24 subnet for the Mac and remembers where it
  found it. Home routers hand out a new IP whenever they re-lease (which
  silently broke the previously hardcoded address), and Android won't resolve
  the Mac's `.local` mDNS name, so discovery is the only route that self-heals.

### Fixed
- A failed transcription no longer vanishes silently: the queue surfaces a
  specific error (e.g. Tailscale down vs. nothing reachable on either route)
  instead of dropping the job without a word.

## [1.10.0] - 2026-07-27

### Added
- Transcription can now reach the Mac over **Wi-Fi/LAN as well as Tailscale**.
  The default "Auto" mode tries the LAN address first and falls back to
  Tailscale, so a dropped tailnet at home no longer blocks transcription.
  Settings → Transcription has separate Wi-Fi/LAN and Tailscale URLs plus a
  Connection selector (Auto / LAN only / Tailscale only).
- The transcript view shows which route is in use ("Connected via Wi-Fi / LAN")
  and has a "Change connection" shortcut.
- "Test connection" now probes both routes and reports each one separately, so
  it's obvious which is down.

### Fixed
- Transcription failures are no longer silent. A failed job now raises a clear
  message naming the cause — e.g. "Can't reach your Mac over Tailscale —
  Tailscale looks down. Reconnect it on your phone, or switch to Wi-Fi/LAN in
  Settings." (The queue added in 1.9.0 had been swallowing these.)

## [1.9.1] - 2026-07-11

### Fixed
- A brief network drop (e.g. Tailscale re-routing) no longer fails a
  transcription outright with "could not reach the transcription server." The
  app now retries the initial connection up to 3 times with backoff before
  giving up. (Mid-run drops were already handled by the poll-to-recover path.)

## [1.9.0] - 2026-07-11

### Added
- Transcription queue. Kicking off several transcriptions at once now enqueues
  them and processes one at a time (the Mac transcribes one episode at a time),
  instead of firing simultaneous connections that could pile up and wedge the
  server. Each job shows its status: Queued → Downloading % → Transcribing %.
- The Downloads tab has a "Transcribing" section listing the queue with live
  status and a per-job cancel/remove button.

## [1.8.0] - 2026-07-09

### Fixed
- Long transcriptions no longer fail with "empty transcript returned" when the
  phone's connection drops mid-run (common for multi-hour episodes). The server
  keeps working and caches the result even after a disconnect; the app now
  detects the interruption and polls a new `/transcript` endpoint until the
  result is ready, keeping the progress indicator visible the whole time
  ("Finishing on your Mac… (reconnected)").
- The server rechecks its cache after acquiring the transcription lock, so a
  retry that raced an in-flight run returns the just-finished result instead of
  redoing the whole (expensive) transcription.

### Changed
- **The transcription server must be restarted** to pick up the new
  `/transcript` poll endpoint and the post-lock cache recheck. (If you run it
  via the launchd agent: `launchctl kickstart -k gui/$(id -u)/com.frontiercast.transcribe`.)

## [1.7.0] - 2026-06-06

### Added
- Episodes with a stored transcript now show a coloured **Transcript** pill
  badge in the episode list, so you can scan a podcast and spot the
  transcribed episodes at a glance instead of opening Now Playing to check
  the icon. Backed by a single stream of transcribed episode ids so the
  per-tile cost stays trivial.

## [1.6.3] - 2026-05-29

### Fixed
- Returning to the Library from a podcast no longer flashes a brief reload of
  the cover thumbnails. The in-memory image cache is now large enough
  (256 MB / 500 entries) to keep all library thumbnails decoded even after
  Now Playing's full-res artwork passes through.

## [1.6.2] - 2026-05-29

### Changed
- Tapping a downloaded episode in the Downloads tab now opens the episode
  detail sheet (where you choose to play) instead of starting playback and
  jumping straight into Now Playing.
- The Android system back button now returns to the Library tab from any other
  tab before exiting the app, so back from Search/Downloads/Settings no longer
  drops you out unexpectedly.

## [1.6.1] - 2026-05-29

### Changed
- Tapping an already-subscribed search result (or feed-URL preview) now opens
  the podcast's episode list directly, instead of being a no-op. The + button
  still subscribes new ones.

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
