#!/bin/bash
# Serve the release APK over Tailscale so the phone can install it from Chrome.
#
# Why this exists: adb over a Tailscale DERP relay (i.e. away from home, or on a
# hotel/guest Wi-Fi with client isolation) fails during its TLS handshake, so
# `adb install` isn't available on the road. Plain HTTP over the same relay works
# fine. Range support matters — a dropped 65MB transfer must resume rather than
# restart.
#
# Usage:  tools/serve-apk.sh          # serves the existing build
#         tools/serve-apk.sh --build  # rebuild first, then serve
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="$REPO/build/app/outputs/flutter-apk/app-release.apk"
PORT=8088
SERVE_DIR="$(mktemp -d)"
trap 'rm -rf "$SERVE_DIR"' EXIT

if [[ "${1:-}" == "--build" ]]; then
  echo "==> Building release APK…"
  (cd "$REPO" && flutter build apk --release)
fi

[[ -f "$APK" ]] || { echo "No APK at $APK — run with --build first." >&2; exit 1; }

VERSION="$(grep '^version:' "$REPO/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"
NAME="frontiercast-${VERSION}.apk"
cp "$APK" "$SERVE_DIR/$NAME"

TS_IP="$(tailscale ip -4 2>/dev/null | head -1)"
[[ -n "$TS_IP" ]] || { echo "Tailscale isn't up on this Mac." >&2; exit 1; }

cat > "$SERVE_DIR/serve.py" <<'PY'
import os, re, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
DIR = os.path.dirname(os.path.abspath(__file__))

class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def _resolve(self):
        name = os.path.basename(self.path.split("?")[0].lstrip("/"))
        p = os.path.join(DIR, name)
        return p if name and os.path.isfile(p) and name.endswith(".apk") else None
    def do_HEAD(self): self._serve(True)
    def do_GET(self): self._serve(False)
    def _serve(self, head_only):
        path = self._resolve()
        if not path:
            self.send_response(404); self.send_header("Content-Length","0"); self.end_headers(); return
        size = os.path.getsize(path); start, end = 0, size - 1; partial = False
        rng = self.headers.get("Range")
        if rng:
            m = re.match(r"bytes=(\d*)-(\d*)", rng.strip())
            if m:
                s, e = m.group(1), m.group(2)
                if s: start = int(s); end = int(e) if e else size - 1
                elif e: start = max(0, size - int(e))
                start = min(start, size - 1); end = min(end, size - 1); partial = True
        length = end - start + 1
        self.send_response(206 if partial else 200)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(length))
        if partial: self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        if head_only: return
        sent = 0
        try:
            with open(path, "rb") as f:
                f.seek(start); remaining = length
                while remaining > 0:
                    chunk = f.read(min(65536, remaining))
                    if not chunk: break
                    self.wfile.write(chunk); remaining -= len(chunk); sent += len(chunk)
            print(f"[serve] sent {sent}/{length} bytes", flush=True)
        except (BrokenPipeError, ConnectionResetError):
            print(f"[serve] client dropped at {sent}/{length} bytes — resumable", flush=True)
    def log_message(self, fmt, *a):
        print(f"[serve] {self.address_string()} {fmt % a}", flush=True)

ThreadingHTTPServer(("0.0.0.0", int(sys.argv[1])), H).serve_forever()
PY

echo
echo "  Open this on the phone (Chrome, type http:// explicitly):"
echo
echo "      http://$TS_IP:$PORT/$NAME"
echo
echo "  Range/resume enabled. Ctrl-C to stop."
echo
python3 "$SERVE_DIR/serve.py" "$PORT"
