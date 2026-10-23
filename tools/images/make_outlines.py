# Bakes the board's space token, icons and monster pieces at the size the board draws them, each
# with an outline, so they stand out from the scenery. Writes board/space_rim.png,
# icons/<name>_rim.png and monsters/<id>_rim.png (with stand_rim.png) into assets/art/. Run it from the repository root: python tools/images/make_outlines.py .
# The sizes here are the board's: change them together with the constants in src/board/space.gd.
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(sys.argv[1])
ART = ROOT / "assets" / "art"

TOKEN_SIZE = (165, 73)  # space.png squashed into a flat oval
TOKEN_RIM = ((0x1d, 0x12, 0x26), 4)  # dark, and how many px wide
TOKEN_LIFT = 1.3  # the paper is grey, so tints would come out dull; brighten it
ICON_SIZE = 108  # the longest side of an icon's drawn part
ICON_FIT = {"coin": 0.82, "fps": 0.88}
ICON_RIM = ((0xff, 0xf4, 0xdc), 4)
BODY_HEIGHT = 182  # a monster's drawn part, feet to crown
STAND_SIZE = (66, 20)  # stand.png, as drawn under a piece on the board
MONSTERS = ["dracula", "medusa", "frankenstein", "death", "hyde", "cthulhu", "wolfman", "dorian"]
ICONS = ["coin", "spikes", "thief", "church", "pong", "haxball", "racing", "fps"]


def outlined(image, rim):
    """The image with `width` px of solid color all round its shape, anti-aliased, on a larger canvas."""
    color, width = rim
    pad = width + 2
    rgba = np.array(image.convert("RGBA"), dtype=np.float32) / 255.0
    rgba = np.pad(rgba, ((pad, pad), (pad, pad), (0, 0)))
    alpha = rgba[..., 3]
    distance = ndimage.distance_transform_edt(alpha < 0.5)
    ring = np.clip(width + 0.5 - distance, 0.0, 1.0)
    out_alpha = np.maximum(alpha, ring)
    rim_rgb = np.array(color, dtype=np.float32) / 255.0
    paper = rgba[..., :3]
    rgb = rim_rgb * (1.0 - alpha[..., None]) + paper * alpha[..., None]
    result = np.dstack([rgb, out_alpha])
    return Image.fromarray((np.clip(result, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")


def lighten(image, lift):
    rgba = np.array(image.convert("RGBA"), dtype=np.float32)
    rgba[..., :3] = np.clip(rgba[..., :3] * lift, 0, 255)
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


token = Image.open(ART / "board" / "space.png").convert("RGBA").resize(TOKEN_SIZE, Image.LANCZOS)
outlined(lighten(token, TOKEN_LIFT), TOKEN_RIM).save(ART / "board" / "space_rim.png")
for name in ICONS:
    icon = Image.open(ART / "icons" / f"{name}.png").convert("RGBA")
    box = icon.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    scale = ICON_SIZE * ICON_FIT.get(name, 1.0) / max(box[2] - box[0], box[3] - box[1])
    icon = icon.crop(box).resize((round((box[2] - box[0]) * scale), round((box[3] - box[1]) * scale)), Image.LANCZOS)
    outlined(icon, ICON_RIM).save(ART / "icons" / f"{name}_rim.png")
for name in MONSTERS:
    body = Image.open(ART / "monsters" / f"{name}.png").convert("RGBA")
    box = body.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    scale = BODY_HEIGHT / (box[3] - box[1])
    body = body.crop(box).resize((round((box[2] - box[0]) * scale), BODY_HEIGHT), Image.LANCZOS)
    outlined(body, ICON_RIM).save(ART / "monsters" / f"{name}_rim.png")
stand = Image.open(ART / "monsters" / "stand.png").convert("RGBA").resize(STAND_SIZE, Image.LANCZOS)
outlined(stand, TOKEN_RIM).save(ART / "monsters" / "stand_rim.png")
print("done")
