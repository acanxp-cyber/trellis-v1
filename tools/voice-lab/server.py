from __future__ import annotations

import hashlib
import json
import mimetypes
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
CACHE_DIR = ROOT / "cache"
MODEL_DIR = ROOT / "models" / "Kokoro-82M"
CACHE_DIR.mkdir(parents=True, exist_ok=True)
HOST = "127.0.0.1"
PORT = 8765

PIPELINE = None
PIPELINE_ERROR = None
PIPELINE_LOCK = threading.Lock()

VOICES = [
    {
        "id": "zf_xiaobei",
        "label": "候选 A · 温柔低语",
        "description": "偏轻、偏慢，重点试听亲密感和清晰度",
    },
    {
        "id": "zf_xiaoni",
        "label": "候选 B · 轻柔女声",
        "description": "偏柔和，适合日常提醒",
    },
    {
        "id": "zf_xiaoxiao",
        "label": "候选 C · 清晰女声",
        "description": "更清楚，适合信息型闹钟",
    },
    {
        "id": "zf_xiaoyi",
        "label": "候选 D · 轻声女声",
        "description": "用于对比低语感与自然度",
    },
    {
        "id": "zm_yunxi",
        "label": "候选 E · 沉稳男声",
        "description": "作为女声参照，检查句子的可信度",
    },
]


def ensure_pipeline():
    global PIPELINE, PIPELINE_ERROR
    if PIPELINE is not None:
        return PIPELINE
    with PIPELINE_LOCK:
        if PIPELINE is not None:
            return PIPELINE
        try:
            import torch
            from kokoro import KPipeline
            from kokoro.model import KModel

            config_path = MODEL_DIR / "config.json"
            model_path = MODEL_DIR / "kokoro-v1_0.pth"
            if not config_path.exists() or not model_path.exists():
                raise FileNotFoundError(
                    "Kokoro model files are missing. Run download_models.ps1 first."
                )

            model = KModel(
                repo_id="hexgrad/Kokoro-82M",
                config=str(config_path),
                model=str(model_path),
            )
            PIPELINE = KPipeline(lang_code="z", model=model, device="cpu")
            for item in VOICES:
                voice_path = MODEL_DIR / "voices" / f"{item['id']}.pt"
                if not voice_path.exists():
                    raise FileNotFoundError(
                        f"Voice pack is missing: {voice_path.name}. "
                        "Run download_models.ps1 again."
                    )
                PIPELINE.voices[item["id"]] = torch.load(
                    voice_path,
                    map_location="cpu",
                    weights_only=True,
                )
            PIPELINE_ERROR = None
        except Exception as exc:  # pragma: no cover - environment dependent
            PIPELINE_ERROR = f"{type(exc).__name__}: {exc}"
            raise
    return PIPELINE


def synthesize(text: str, voice: str, speed: float) -> tuple[Path, bool]:
    import numpy as np
    import soundfile as sf

    pipeline = ensure_pipeline()
    key_text = json.dumps(
        {"text": text, "voice": voice, "speed": speed, "engine": "kokoro"},
        ensure_ascii=False,
        sort_keys=True,
    )
    key = hashlib.sha256(key_text.encode("utf-8")).hexdigest()
    output = CACHE_DIR / f"{key}.wav"
    if output.exists():
        return output, True

    chunks = []
    for result in pipeline(text, voice=voice, speed=speed):
        if result.audio is None:
            continue
        chunks.append(result.audio.detach().cpu().numpy())
    if not chunks:
        raise RuntimeError("Kokoro returned no audio.")

    audio = np.concatenate(chunks)
    temporary = output.with_suffix(".tmp.wav")
    sf.write(temporary, audio, 24000)
    os.replace(temporary, output)
    return output, False


class Handler(BaseHTTPRequestHandler):
    server_version = "TrellisVoiceLab/1.0"

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)

    def send_json(self, status: int, payload: dict):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            self.send_json(
                200,
                {
                    "ok": True,
                    "engine": "kokoro",
                    "ready": PIPELINE is not None,
                    "model_downloaded": (
                        (MODEL_DIR / "config.json").exists()
                        and (MODEL_DIR / "kokoro-v1_0.pth").exists()
                    ),
                    "error": PIPELINE_ERROR,
                },
            )
            return
        if path == "/api/voices":
            self.send_json(200, {"voices": VOICES})
            return
        if path == "/" or path == "/index.html":
            body = (ROOT / "index.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        static_prefixes = {
            "/cache/": CACHE_DIR,
            "/samples/": ROOT / "samples",
        }
        for prefix, directory in static_prefixes.items():
            if not path.startswith(prefix):
                continue
            file_name = Path(path).name
            file_path = directory / file_name
            if not file_path.exists():
                self.send_error(404)
                return
            body = file_path.read_bytes()
            content_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_error(404)

    def do_POST(self):
        path = urlparse(self.path).path
        if path != "/api/tts":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
            text = str(payload.get("text", "")).strip()
            voice = str(payload.get("voice", "")).strip()
            speed = min(1.3, max(0.65, float(payload.get("speed", 0.9))))
            valid_voices = {item["id"] for item in VOICES}
            if not text:
                raise ValueError("请输入需要朗读的文字。")
            if voice not in valid_voices:
                raise ValueError("未知语音。")

            output, was_cached = synthesize(text, voice, speed)
            self.send_json(
                200,
                {
                    "url": f"/cache/{output.name}",
                    "cached": was_cached,
                },
            )
        except Exception as exc:
            self.send_json(
                503,
                {
                    "error": f"{type(exc).__name__}: {exc}",
                    "hint": "请先运行 setup.ps1 和 download_models.ps1。",
                },
            )


if __name__ == "__main__":
    print(f"Voice Lab: http://{HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
