# Builds the sound review page from docs/sound_prompts.md and the processed files in assets/audio/.
# Usage: python build_review.py <repo root> <template> <out.html> [--raw] [<name> ...]
#   --raw reviews the raw files in audio_raw/ instead, with the thief in two parts. Names limit the page to those sounds.
# The processed review also decodes each OGG to a WAV in review_wav/ next to the page, for browsers that can't play OGG.
# That needs ffmpeg on the PATH, or its path in the FFMPEG environment variable.
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
TEMPLATE = Path(sys.argv[2])
OUT = Path(sys.argv[3])
RAW = "--raw" in sys.argv[4:]
WANTED = set(sys.argv[4:]) - {"--raw"}

# Parts that processing joins into one file, as in process_sounds.py
JOIN = {"sfx/thief": ["sfx/thief", "sfx/thief_giggle"]}
PARTS = {p for parts in JOIN.values() for p in parts[1:]}

doc = (ROOT / "docs" / "sound_prompts.md").read_text(encoding="utf-8")
entries = re.findall(
    r"^### (.+?)\n\n\*\*Settings:\*\*.*?```text\n(.*?)(?:\n\n[^`]*?)?\n```\n\n\*\*Processing:\*\* ([\d.]+) s, (one-shot|seamless loop)",
    doc,
    re.S | re.M,
)

sounds = []
for heading, subject, seconds, kind in entries:
    for path in re.findall(r"`([^`]+)\.ogg`", heading):
        folder, name = path.split("/")
        sounds.append(dict(path=path, folder=folder, name=name, subject=subject, seconds=float(seconds), loop=kind != "one-shot"))

# Voices: drop the monster's shared opening line, keep only what happens
by_monster = {}
for s in sounds:
    if s["folder"] == "voices":
        by_monster.setdefault(s["name"].rsplit("_", 1)[0], []).append(s)
for group in by_monster.values():
    prefix = os.path.commonprefix([s["subject"] for s in group])
    prefix = prefix[: prefix.rfind(". ") + 1]  # back to the end of the shared sentence
    for s in group:
        s["subject"] = s["subject"][len(prefix):].strip()

if RAW:
    for s in sounds:
        assert (ROOT / "audio_raw" / f"{s['path']}.wav").exists(), s["path"]
        s["src"] = f"audio_raw/{s['path']}.wav"
    assert len(sounds) == 61, len(sounds)  # 60 files, with the thief in two parts
else:
    by_path = {s["path"]: s for s in sounds}
    for path, parts in JOIN.items():
        by_path[path]["subject"] = " Then: ".join(by_path[p]["subject"] for p in parts)
        by_path[path]["seconds"] = round(sum(by_path[p]["seconds"] for p in parts), 2)
    sounds = [s for s in sounds if s["path"] not in PARTS]
    for s in sounds:
        assert (ROOT / "assets" / "audio" / f"{s['path']}.ogg").exists(), s["path"]
        s["src"] = f"assets/audio/{s['path']}.ogg"
        s["fallback"] = f"review_wav/{s['path']}.wav"
    assert len(sounds) == 60, len(sounds)

if WANTED:
    assert WANTED <= {s["name"] for s in sounds}, WANTED - {s["name"] for s in sounds}
    sounds = [s for s in sounds if s["name"] in WANTED]

if not RAW:
    ffmpeg = os.environ.get("FFMPEG") or shutil.which("ffmpeg") or sys.exit("Install ffmpeg or set FFMPEG first.")
    for s in sounds:
        wav = OUT.parent / s["fallback"]
        wav.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(ROOT / s["src"]), "-c:a", "pcm_s16le", str(wav)], check=True)

html = TEMPLATE.read_text(encoding="utf-8").replace("/*SOUNDS*/[]", json.dumps(sounds, ensure_ascii=False))
if not RAW:
    html = html.replace("<title>Monsternight Sound Review</title>", "<title>Monsternight Processed Sounds</title>")
OUT.write_text(html, encoding="utf-8", newline="\n")
print(f"{len(sounds)} sounds -> {OUT}")
