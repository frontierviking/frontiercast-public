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
import re
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import httpx
import mlx_whisper

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

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            self._send(200, {"status": "ok", "model": MODEL})
        else:
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
            self._send(200, {"text": cache_file.read_text("utf-8"), "cached": True})
            return

        tmp_path = None
        try:
            with _transcribe_lock:
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
                    with open(tmp_path, "wb") as out:
                        for chunk in resp.iter_bytes(65536):
                            out.write(chunk)
                kwargs = {"path_or_hf_repo": MODEL}
                if language:
                    kwargs["language"] = language
                print(f"[transcribe] running whisper (guid={guid})", flush=True)
                result = mlx_whisper.transcribe(tmp_path, **kwargs)
                text = (result.get("text") or "").strip()
                cache_file.write_text(text, encoding="utf-8")
            print(f"[transcribe] done ({len(text)} chars)", flush=True)
            self._send(200, {"text": text, "cached": False})
        except httpx.HTTPError as exc:
            self._send(502, {"error": f"download failed: {exc}"})
        except Exception as exc:  # noqa: BLE001
            self._send(500, {"error": str(exc)})
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except OSError:
                    pass

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
