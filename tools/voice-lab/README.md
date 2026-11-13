# SOMETHING Voice Lab

Local voice audition environment for choosing the alarm voice.

## Install

```powershell
Set-Location F:\claude\Today\V1\tools\voice-lab
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

The first install downloads Python packages. The first Kokoro generation also
downloads the Apache-2.0 Kokoro-82M model and the selected Chinese voice pack.
If Hugging Face is not directly reachable, `download_models.ps1` resolves a
reachable address through DNS-over-HTTPS while keeping TLS hostname checks.

## Run

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Or use the desktop VBS launcher.

Open `http://127.0.0.1:8765`.

## What To Compare

Use the same text for every voice:

```text
12点半到了，吃饭。
```

Judge:

- warmth and intimacy
- clarity at low volume
- naturalness of the number and pause
- whether it sounds like a bedside reminder rather than an advertisement

Kokoro code and model weights are Apache-2.0. Verify the final selected voice
pack card before shipping.

The model files are stored under `models/Kokoro-82M` and excluded from Git.

## Taiwan Mandarin Samples

The three `samples/taiwan-*.mp3` files are online Edge TTS reference
recordings. They are for audition only and must not be treated as an embedded,
offline, or production-licensed voice pack.
