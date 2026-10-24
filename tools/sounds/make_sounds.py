# Generates sounds from docs/sound_prompts.md with the ElevenLabs API, one take per file.
# Usage: python make_sounds.py <repo root> <name> [<name> ...]   (names like ui_click, hop_1)
# Needs the ElevenLabs API key in the ELEVENLABS_API_KEY environment variable.
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(sys.argv[1])
WANTED = set(sys.argv[2:])
KEY = os.environ.get("ELEVENLABS_API_KEY") or sys.exit("Set ELEVENLABS_API_KEY first.")
MODEL = "eleven_text_to_sound_v3"
FORMAT, EXT = ("wav_48000", "wav") if os.environ.get("SOUND_FORMAT") != "mp3" else ("mp3_44100_192", "mp3")
URL = f"https://api.elevenlabs.io/v1/sound-generation?output_format={FORMAT}"

doc = (ROOT / "docs" / "sound_prompts.md").read_text(encoding="utf-8")
entries = re.findall(
    r"^### (.+?)\n\n\*\*Settings:\*\* duration ([\d.]+) s, looping (on|off), prompt influence (\d+)%\..*?```text\n(.*?)\n```",
    doc,
    re.S | re.M,
)

for heading, duration, looping, influence, prompt in entries:
    for path in re.findall(r"`([^`]+)\.ogg`", heading):
        if WANTED != {"all"} and Path(path).name not in WANTED:
            continue
        out = ROOT / "audio_raw" / f"{path}.{EXT}"
        if out.exists():
            print(f"skip {out} (exists)")
            continue
        body = {
            "text": prompt,
            "model_id": MODEL,
            "duration_seconds": float(duration),
            "loop": looping == "on",
            "prompt_influence": int(influence) / 100,
        }
        req = urllib.request.Request(
            URL,
            data=json.dumps(body).encode(),
            headers={"xi-api-key": KEY, "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req) as resp:
                audio = resp.read()
        except urllib.error.HTTPError as e:
            sys.exit(f"{path}: HTTP {e.code} {e.read().decode(errors='replace')}")
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(audio)
        WANTED.discard(Path(path).name)
        print(f"made {out} ({len(audio)} bytes)")

if WANTED - {"all"}:
    print(f"not found in the doc: {sorted(WANTED)}")
