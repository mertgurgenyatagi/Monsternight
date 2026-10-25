# Generates raw images from docs/asset_prompts.md with the Gemini API, one take per file, into images_raw/ as .jfif (JPEG).
# Usage: python make_images.py <repo root> <name> [<name> ...]   (names like sumo, pong_table; "new" means every prompt marked "New in part 26")
# Needs the Gemini API key in the GEMINI_API_KEY environment variable. Skips files that already exist.
# A prompt's "Attach" line names the image to send along; its raw in images_raw/ is attached.
import base64
import io
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(sys.argv[1])
WANTED = set(sys.argv[2:])
KEY = os.environ.get("GEMINI_API_KEY") or sys.exit("Set GEMINI_API_KEY first.")
MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3-pro-image")
URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

doc = (ROOT / "docs" / "asset_prompts.md").read_text(encoding="utf-8")
entries = re.findall(r"^### `\w+/(\w+)\.png`\n\n((?:(?!^###).)*?)```text\n(.*?)\n```", doc, re.S | re.M)

for name, lead, prompt in entries:
    if not (name in WANTED or ("new" in WANTED and lead.startswith("New in part 26"))):
        continue
    out = ROOT / "images_raw" / f"{name}.jfif"
    if out.exists():
        print(f"skip {name} (exists)")
        continue
    parts = []
    if attach := re.search(r"\*\*Attach:\*\* your image for `\w+/(\w+)\.png`", lead):
        raw = ROOT / "images_raw" / f"{attach.group(1)}.jfif"
        parts.append({"inline_data": {"mime_type": "image/jpeg", "data": base64.b64encode(raw.read_bytes()).decode()}})
    parts.append({"text": prompt})
    body = {"contents": [{"parts": parts}], "generationConfig": {"responseModalities": ["IMAGE"]}}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers={"x-goog-api-key": KEY, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            reply = json.load(resp)
    except urllib.error.HTTPError as e:
        sys.exit(f"{name}: HTTP {e.code} {e.read().decode(errors='replace')[:500]}")
    data = next((p["inlineData"]["data"] for c in reply.get("candidates", []) for p in c["content"]["parts"] if "inlineData" in p), None)
    if data is None:
        sys.exit(f"{name}: no image in the reply: {json.dumps(reply)[:500]}")
    Image.open(io.BytesIO(base64.b64decode(data))).convert("RGB").save(out, "JPEG", quality=95)
    print(f"made {out.name}")
