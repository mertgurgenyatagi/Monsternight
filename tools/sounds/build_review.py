# Builds the sound review page from docs/sound_prompts.md and the files in audio_raw/.
# Usage: python build_review.py <repo root> <template> <out.html> [<name> ...]   (names limit the page to those sounds)
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
TEMPLATE = Path(sys.argv[2])
OUT = Path(sys.argv[3])
WANTED = set(sys.argv[4:])

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
        assert (ROOT / "audio_raw" / f"{path}.wav").exists(), path
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

assert len(sounds) == 61, len(sounds)  # 60 files, with the thief in two parts
if WANTED:
    assert WANTED <= {s["name"] for s in sounds}, WANTED - {s["name"] for s in sounds}
    sounds = [s for s in sounds if s["name"] in WANTED]
html = TEMPLATE.read_text(encoding="utf-8").replace("/*SOUNDS*/[]", json.dumps(sounds, ensure_ascii=False))
OUT.write_text(html, encoding="utf-8", newline="\n")
print(f"{len(sounds)} sounds -> {OUT}")
