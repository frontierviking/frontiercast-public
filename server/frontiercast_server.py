#!/usr/bin/env python3
"""FrontierCast transcription server.

Wraps the mlx-whisper pipeline behind a tiny HTTP API the phone calls over
Tailscale. Stdlib only (plus httpx + mlx_whisper from the venv) so it runs on
Python 3.14 without FastAPI/pydantic wheels.

Run:
    ~/Documents/AI/venv/bin/python ~/Documents/AI/frontiercast_server.py

Endpoints:
    GET  /health                         -> {"status":"ok","model":...}
    POST /transcribe  (Bearer auth)      -> {"text":..., "cached":bool}
         body: {"audio_url":..., "guid":..., "title":..., "podcast":...,
                "language":"sv"|null}
"""

import hashlib
import json
import os
import pathlib
import queue as queuelib
import re
import sys
import tempfile
import threading
import types
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import httpx
import mlx_whisper

# --- Progress hook -----------------------------------------------------------
# mlx_whisper.transcribe drives a tqdm(total=content_frames) bar and calls
# pbar.update(frames) as it works. We replace that tqdm with a tiny shim that
# reports the fraction done to a per-request callback, so the phone can show a
# real progress circle. Only one transcription runs at a time (see the lock),
# so a single module-level callback is safe.
_progress_cb = None


class _ProgressBar:
    def __init__(self, *args, total=None, **kwargs):
        self.total = total or 0
        self.n = 0

    def update(self, k=1):
        self.n += k
        cb = _progress_cb
        if cb and self.total:
            try:
                cb(min(1.0, self.n / self.total))
            except Exception:  # noqa: BLE001 - never let progress break transcription
                pass

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def close(self):
        pass


# Patch the module's tqdm reference (the function `mlx_whisper.transcribe`
# shadows the submodule attribute, so reach it via sys.modules).
sys.modules["mlx_whisper.transcribe"].tqdm = types.SimpleNamespace(
    tqdm=_ProgressBar
)

TOKEN = os.environ.get(
    "FRONTIERCAST_TOKEN", "change-me"
)
MODEL = os.environ.get("FRONTIERCAST_MODEL", "mlx-community/whisper-medium-mlx")
PORT = int(os.environ.get("FRONTIERCAST_PORT", "8765"))
# Stored alongside the existing podcast_transcriber.py output, with the same
# "Podcast__Title.txt" naming, so transcripts made either way are shared.
TRANSCRIPT_DIR = pathlib.Path(
    os.environ.get(
        "FRONTIERCAST_TRANSCRIPTS",
        str(pathlib.Path.home() / "Documents" / "AI" / "podcasts" / "transcripts"),
    )
)
TRANSCRIPT_DIR.mkdir(parents=True, exist_ok=True)

# Serialize transcriptions: only one model run at a time (memory + GPU).
_transcribe_lock = threading.Lock()


def _sanitize(name: str) -> str:
    """Match podcast_transcriber.py's filename sanitisation."""
    return re.sub(r"[^\w\s-]", "", name).strip().replace(" ", "_")[:80]


def _cache_path(title, podcast, guid: str) -> pathlib.Path:
    if title:
        stem = (
            f"{_sanitize(podcast)}__{_sanitize(title)}"
            if podcast
            else _sanitize(title)
        )
        if stem:
            return TRANSCRIPT_DIR / f"{stem}.txt"
    digest = hashlib.sha256(guid.encode("utf-8")).hexdigest()[:32]
    return TRANSCRIPT_DIR / f"{digest}.txt"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code: int, obj: dict) -> None:
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _begin_stream(self) -> None:
        """Start a streamed NDJSON response (body ends when the socket closes)."""
        self.send_response(200)
        self.send_header("Content-Type", "application/x-ndjson")
        self.send_header("Connection", "close")
        self.end_headers()
        self.close_connection = True

    def _write_line(self, obj: dict) -> None:
        self.wfile.write((json.dumps(obj) + "\n").encode("utf-8"))
        self.wfile.flush()

    def do_GET(self):  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/health":
            self._send(200, {"status": "ok", "model": MODEL})
            return
        if parsed.path == "/transcript":
            # Poll endpoint: return a cached transcript if it exists, else 204.
            # Lets the phone recover after a dropped streaming connection —
            # the server finishes and caches even if the phone went away.
            if self.headers.get("Authorization", "") != f"Bearer {TOKEN}":
                self._send(401, {"error": "unauthorized"})
                return
            q = urllib.parse.parse_qs(parsed.query)
            guid = (q.get("guid") or [""])[0]
            title = (q.get("title") or [None])[0]
            podcast = (q.get("podcast") or [None])[0]
            if not guid:
                self._send(400, {"error": "guid required"})
                return
            cache_file = _cache_path(title, podcast, guid)
            if cache_file.exists():
                self._send(
                    200,
                    {
                        "ready": True,
                        "text": cache_file.read_text("utf-8"),
                    },
                )
            else:
                self._send(200, {"ready": False})
            return
        self._send(404, {"error": "not found"})

    def do_POST(self):  # noqa: N802
        if self.path != "/transcribe":
            self._send(404, {"error": "not found"})
            return
        if self.headers.get("Authorization", "") != f"Bearer {TOKEN}":
            self._send(401, {"error": "unauthorized"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError) as exc:
            self._send(400, {"error": f"bad request: {exc}"})
            return

        audio_url = payload.get("audio_url")
        guid = payload.get("guid")
        language = payload.get("language")
        title = payload.get("title")
        podcast = payload.get("podcast")
        if not audio_url or not guid:
            self._send(400, {"error": "audio_url and guid are required"})
            return

        cache_file = _cache_path(title, podcast, guid)
        if cache_file.exists():
            self._begin_stream()
            self._write_line(
                {"done": True, "text": cache_file.read_text("utf-8"), "cached": True}
            )
            return

        # Stream progress as NDJSON. The heavy work runs in a worker thread and
        # pushes events onto a queue; this thread drains the queue to the socket.
        self._begin_stream()
        self._write_line({"stage": "starting"})
        events: "queuelib.Queue[dict | None]" = queuelib.Queue()

        def run() -> None:
            global _progress_cb
            tmp_path = None
            try:
                with _transcribe_lock:
                    # Recheck the cache now that we hold the lock. If a request
                    # for the same episode was already in flight when we passed
                    # the initial check and has since finished, use its result
                    # instead of redoing the whole transcription.
                    if cache_file.exists():
                        print(
                            f"[transcribe] cache hit (post-lock) for {guid}",
                            flush=True,
                        )
                        events.put(
                            {
                                "done": True,
                                "text": cache_file.read_text("utf-8"),
                                "cached": True,
                            }
                        )
                        return
                    fd, tmp_path = tempfile.mkstemp(suffix=".audio")
                    os.close(fd)
                    print(f"[transcribe] downloading {audio_url}", flush=True)
                    with httpx.stream(
                        "GET",
                        audio_url,
                        follow_redirects=True,
                        timeout=httpx.Timeout(120.0, read=600.0),
                        headers={"User-Agent": "FrontierCast/1.0"},
                    ) as resp:
                        resp.raise_for_status()
                        total = int(resp.headers.get("content-length") or 0)
                        got = 0
                        marker = 0
                        with open(tmp_path, "wb") as out:
                            events.put({"stage": "downloading", "progress": 0.0})
                            for chunk in resp.iter_bytes(1 << 16):
                                out.write(chunk)
                                got += len(chunk)
                                # Heartbeat every ~4 MB so the socket stays alive.
                                if got - marker >= (4 << 20):
                                    marker = got
                                    events.put(
                                        {
                                            "stage": "downloading",
                                            "progress": (got / total) if total else None,
                                        }
                                    )
                    kwargs = {"path_or_hf_repo": MODEL}
                    if language:
                        kwargs["language"] = language
                    print(f"[transcribe] running whisper (guid={guid})", flush=True)
                    _progress_cb = lambda p: events.put(  # noqa: E731
                        {"stage": "transcribing", "progress": p}
                    )
                    result = mlx_whisper.transcribe(tmp_path, **kwargs)
                    _progress_cb = None
                    text = (result.get("text") or "").strip()
                    cache_file.write_text(text, encoding="utf-8")
                print(f"[transcribe] done ({len(text)} chars)", flush=True)
                events.put({"done": True, "text": text, "cached": False})
            except httpx.HTTPError as exc:
                events.put({"error": f"download failed: {exc}"})
            except Exception as exc:  # noqa: BLE001
                events.put({"error": str(exc)})
            finally:
                _progress_cb = None
                if tmp_path and os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except OSError:
                        pass
                events.put(None)

        worker = threading.Thread(target=run, daemon=True)
        worker.start()
        try:
            while True:
                item = events.get()
                if item is None:
                    break
                self._write_line(item)
        except (BrokenPipeError, ConnectionResetError):
            # Phone went away; the worker still finishes and caches the result.
            pass
        worker.join()

    def log_message(self, *args):  # silence default logging
        pass


def main():
    print(
        f"FrontierCast transcribe server on 0.0.0.0:{PORT} (model {MODEL}, "
        f"transcripts {TRANSCRIPT_DIR})",
        flush=True,
    )
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
