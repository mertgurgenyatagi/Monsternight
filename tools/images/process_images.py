# Processes the raw images in images_raw/ into assets/art/, following the Processing lines in docs/asset_prompts.md.
# Usage: python process_images.py <repo root> [<name> ...]   (names like coin, die_1; none means all)
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(sys.argv[1])
WANTED = set(sys.argv[2:])

# Every image the doc marks "mirror it if it faces left" was checked by eye, and all of them already face right.
MIRROR = set()
# Pieces the game stretches, or that must reach the screen edges, fill their box by stretching their plain middle.
STRETCH = {"panel", "button", "card", "curtain"}
# The curtain's top border is far wider than Gemini drew it, so it becomes a seamless strip repeated across its width.
REPEATS = {"curtain_top": 2}
# Strips are cut or extended on their plain side, which is the bottom except for these.
PLAIN_TOP = {"curtain_top"}

# Alpha ramps from 0 to 1 as a pixel's distance from the background goes from LO to HI (0-255 scale).
# The green raws have far more JPEG noise in the background than the white ones.
RAMP = {"white": (14, 40), "green": (40, 100)}
EDGE = 4  # px along the outline where paper and background mix; everything further in is solid
SPECK = 0.0002  # opaque bits smaller than this share of the image are JPEG noise
PINHOLE = 0.000006  # and so are holes smaller than this (a few px); real gaps are far bigger
SEAM_SEARCH = 0.15  # tiling strips look for their best cut within this share of each end
SEAM_OVERLAP = 0.05  # and then overlap this share of their width, joining along the path where the two ends match best

doc = (ROOT / "docs" / "asset_prompts.md").read_text(encoding="utf-8")
entries = re.findall(r"^### `(\w+)/(\w+)\.png`\n(?:(?!^###).)*?^\*\*Processing:\*\* (.*?)$", doc, re.S | re.M)


def fit_background(rgb, bg_name):
    """Fits a smooth quadratic to the background pixels, because Gemini's backgrounds drift a little across the image."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if bg_name == "white":
        sure = (rgb.min(-1) > 225) & (rgb.max(-1) - rgb.min(-1) < 20)
    else:
        greenness = g - np.maximum(r, b)
        sure = greenness > 0.8 * np.percentile(greenness, 99)
    sure = ndimage.binary_erosion(sure, iterations=3)  # stay clear of edge fringes
    ys, xs = np.nonzero(sure)
    pick = np.linspace(0, len(ys) - 1, min(len(ys), 20000)).astype(int)
    ys, xs = ys[pick], xs[pick]
    h, w = r.shape
    terms = lambda y, x: np.stack([np.ones_like(x), x, y, x * x, x * y, y * y], -1)
    coef, *_ = np.linalg.lstsq(terms(ys / h, xs / w), rgb[ys, xs], rcond=None)
    yy, xx = np.mgrid[0:h, 0:w]
    model = terms(yy / h, xx / w) @ coef
    seen = rgb[ys, xs]
    return np.clip(model, seen.min(0), seen.max(0))


def cut_out(rgb, bg_name):
    """Returns premultiplied RGBA (0-1) with the background removed everywhere, including gaps inside the shape."""
    bg = fit_background(rgb, bg_name)
    dist = np.abs(rgb - bg).max(-1)
    lo, hi = RAMP[bg_name]
    soft = np.clip((dist - lo) / (hi - lo), 0, 1)

    solid = soft > 0.5
    labels, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, n + 1))
    solid = np.isin(labels, 1 + np.nonzero(sizes >= SPECK * solid.size)[0])
    inner = ndimage.binary_erosion(solid, iterations=EDGE)
    near = ndimage.binary_dilation(solid, iterations=EDGE)

    # Along the outline, each pixel is a mix of the nearest solid paper and the background: measure how much paper is in it.
    # A plain distance ramp would keep the light, half-mixed rim as solid paper, which shows as a halo on dark scenes.
    iy, ix = ndimage.distance_transform_edt(~inner, return_distances=False, return_indices=True)
    toward = rgb[iy, ix] - bg
    span = (toward**2).sum(-1)
    mix = np.clip(((rgb - bg) * toward).sum(-1) / np.maximum(span, 1), 0, 1)
    edge = np.where(span > 60**2, mix, soft)  # paper too close to the background color falls back to the ramp
    alpha = np.where(inner, 1.0, np.where(near, edge, 0.0))
    alpha[alpha < 0.05] = 0

    # Each edge pixel is a mix of paper and background: take the background back out of its color
    a = np.maximum(alpha, 1e-3)[..., None]
    color = np.clip(bg + (rgb - bg) / a, 0, 255)

    # Pinholes are light flecks in the paper, not real gaps like the ones between branches: paper them over
    holes = ndimage.binary_fill_holes(solid) & ~solid
    labels, n = ndimage.label(holes)
    sizes = ndimage.sum(holes, labels, range(1, n + 1))
    pinholes = ndimage.binary_dilation(np.isin(labels, 1 + np.nonzero(sizes < PINHOLE * holes.size)[0]))
    alpha[pinholes] = 1
    color[pinholes] = rgb[iy, ix][pinholes]
    if bg_name == "green":
        color[..., 1] = np.minimum(color[..., 1], np.maximum(color[..., 0], color[..., 2]))
    return np.dstack([color / 255 * alpha[..., None], alpha])


def to_image(pm):
    return Image.fromarray(np.round(pm * 255).astype(np.uint8), "RGBa")


def from_image(im):
    return np.asarray(im.convert("RGBa"), dtype=np.float64) / 255


def resize(pm, w, h):
    return from_image(to_image(pm).resize((w, h), Image.LANCZOS)).clip(0, 1)


def trim(pm, sideways=True):
    rows = np.nonzero(pm[..., 3].max(1) > 0)[0]
    cols = np.nonzero(pm[..., 3].max(0) > 0)[0] if sideways else [0, pm.shape[1] - 1]
    return pm[rows[0] : rows[-1] + 1, cols[0] : cols[-1] + 1]


def seam_cost(a, b):
    """For overlapping columns a and b (..., h, k, 4), the cheapest top-to-bottom path cost ending at each pixel."""
    diff = a - b
    diff[..., 3] *= 2  # the outline matters more than the color
    cost = (diff**2).sum(-1)
    cost[..., [0, -1]] = 1e9  # the path stays inside, so the first column is all a and the last all b
    pad = [(0, 0)] * (cost.ndim - 2) + [(1, 1)]
    for y in range(1, cost.shape[-2]):
        prev = np.pad(cost[..., y - 1, :], pad, constant_values=1e18)
        cost[..., y, :] += np.minimum(np.minimum(prev[..., :-2], prev[..., 1:-1]), prev[..., 2:])
    return cost


def join(a, b):
    """Joins a on the left to b on the right along the top-to-bottom path where they differ least, so nothing is ghosted."""
    cost = seam_cost(a, b)
    h, k = cost.shape
    path = np.empty(h, int)
    path[-1] = np.argmin(cost[-1])
    for y in range(h - 2, -1, -1):
        x = path[y + 1]
        lo = max(0, x - 1)
        path[y] = lo + np.argmin(cost[y, lo : x + 2])
    take_b = (np.arange(k)[None, :] >= path[:, None]).astype(float)
    take_b = ndimage.uniform_filter1d(take_b, 3, axis=1)[..., None]  # a 1 px feather
    return a * (1 - take_b) + b * take_b


def tile_sideways(pm, width):
    """Cuts the strip where its two ends match best, scales it to the width, and joins the ends so copies tile."""
    # The tile is [xl, xr), so the copy after it starts at xl and must continue from xr: they overlap there.
    # Try every pair of cuts on a quarter-size copy and keep the one with the cheapest seam.
    h, w = pm.shape[:2]
    small = resize(pm, w // 4, h // 4)
    sw = small.shape[1]
    reach, overlap = int(sw * SEAM_SEARCH), int(sw * SEAM_OVERLAP)
    heads = np.stack([small[:, x : x + overlap] for x in range(reach)])
    best = (np.inf, 0, 0)
    for xr in range(sw - reach - overlap, sw - overlap):
        costs = seam_cost(small[None, :, xr : xr + overlap], heads)[:, -1].min(-1)
        best = min(best, (costs.min(), int(costs.argmin()), xr))
    _, xl, xr = best
    xl, xr, overlap = xl * w / sw, xr * w / sw, overlap * w / sw

    scale = width / (xr - xl)
    big = resize(pm, round(w * scale), round(h * scale))
    xl, xr = round(xl * scale), round(xl * scale) + width
    k = min(round(overlap * scale), big.shape[1] - xr)
    out = big[:, xl:xr].copy()
    out[:, :k] = join(big[:, xr : xr + k], big[:, xl : xl + k])
    return out


def fit_height(pm, height, plain_top=False):
    """Cuts or extends a strip on its plain side, so it is exactly this tall."""
    if plain_top:
        return fit_height(pm[::-1], height)[::-1]
    # The raws' last rows are often a thin, half-transparent sliver along the image edge: drop them
    cover = pm[..., 3].mean(1)
    typical = np.median(cover[-max(1, len(cover) // 10) :])
    end = len(cover)
    while end > 1 and cover[end - 1] < 0.95 * typical:
        end -= 1
    pm = pm[:end]
    h = pm.shape[0]
    if h >= height:
        return pm[:height]
    extra = height - h
    mirrored = pm[::-1]
    while mirrored.shape[0] < extra:
        mirrored = np.concatenate([mirrored, mirrored[::-1]])
    return np.concatenate([pm, mirrored[:extra]])


def place(pm, w, h, top_left=False):
    """Scales the shape to fit inside w x h, keeping its proportions, on a transparent canvas of that size."""
    ph, pw = pm.shape[:2]
    s = min(w / pw, h / ph)
    nw, nh = max(1, round(pw * s)), max(1, round(ph * s))
    canvas = np.zeros((h, w, 4))
    x, y = (0, 0) if top_left else ((w - nw) // 2, (h - nh) // 2)
    canvas[y : y + nh, x : x + nw] = resize(pm, nw, nh)
    return canvas


def stretch(pm, w, h):
    """Scales the shape to fit inside w x h, then stretches its middle third to fill the rest, so corners keep their shape."""
    ph, pw = pm.shape[:2]
    s = min(w / pw, h / ph)
    pm = resize(pm, min(w, round(pw * s)), min(h, round(ph * s)))
    if pm.shape[1] < w:
        third = pm.shape[1] // 3
        middle = resize(pm[:, third:-third], w - 2 * third, pm.shape[0])
        pm = np.concatenate([pm[:, :third], middle, pm[:, -third:]], axis=1)
    if pm.shape[0] < h:
        third = pm.shape[0] // 3
        middle = resize(pm[third:-third], w, h - 2 * third)
        pm = np.concatenate([pm[:third], middle, pm[-third:]])
    return pm


def process(name, line):
    bg_name = re.match(r"remove (white|green)", line).group(1)
    rgb = np.asarray(Image.open(ROOT / "images_raw" / f"{name}.jfif").convert("RGB"), dtype=np.float64)
    strip = "tiles sideways" in line or name in REPEATS
    pm = trim(cut_out(rgb, bg_name), sideways=not strip)
    if name in MIRROR:
        pm = pm[:, ::-1]
    if tall := re.search(r"(\d+) tall", line):
        h = int(tall.group(1))
        return resize(pm, max(1, round(pm.shape[1] * h / pm.shape[0])), h)
    w, h = map(int, re.search(r"(\d+) × (\d+)", line).groups())
    if strip:
        n = REPEATS.get(name, 1)
        return fit_height(np.concatenate([tile_sideways(pm, w // n)] * n, axis=1), h, name in PLAIN_TOP)
    if name in STRETCH:
        return stretch(pm, w, h)
    return place(pm, w, h, top_left="top-left" in line)


done = set()
for folder, name, line in entries:
    if WANTED and name not in WANTED:
        continue
    if not (ROOT / "images_raw" / f"{name}.jfif").exists():
        print(f"skip {name} (no raw)")
        continue
    out = ROOT / "assets" / "art" / folder / f"{name}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    pm = process(name, line)
    to_image(pm).convert("RGBA").save(out, optimize=True)
    done.add(name)
    print(f"made {out.relative_to(ROOT)} ({pm.shape[1]} x {pm.shape[0]})")

if WANTED - done:
    print(f"not processed: {sorted(WANTED - done)}")
