# New image prompts

**All four are made and processed (2026-10-25); this page is kept for reference.** The only images that were still to be generated: the 4 category icons for Shot in the Dark (Microplan 15). Copied from [asset_prompts.md](asset_prompts.md#category-icons-icons), which stays the source for how they are processed. Nothing else in parts 46 to 51 needs a new image, and no new sounds are needed.

## Making an image

1. Make `icons/coin.png`'s image available first (it is already in `images_raw/coin.jfif`). Start a new Gemini chat for each icon and attach it.
2. Paste the whole prompt from the box.
3. Check the result: no text, a flat pure white background, no shadow, no white sticker border, nothing extra in the frame.
4. Save it as Gemini made it in `images_raw/`, with its `.jfif` extension: `images_raw/atlas.jfif`, `archive.jfif`, `lab.jfif`, `stage.jfif`.
5. Tell Claude. It runs `python tools/images/process_images.py . atlas archive lab stage`, and adds them to `make_outlines.py`'s `ICONS`.

## `icons/atlas.png`: The Atlas (geography)

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a small world globe as a flat paper-cutout game icon, seen from the front: a round ball of teal paper with a few simple, blobby continents cut from green paper, tilted slightly on its axis, held in a curved arm of violet paper that ends in a small round violet base.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The globe, its arm and its base only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

## `icons/archive.png`: The Archive (history)

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw an old scroll as a flat paper-cutout game icon, seen from the front: a sheet of warm tan parchment paper, rolled up into a thick curl at the top and at the bottom, with a gap of flat parchment between the two curls, and a round blob of dark red wax stuck on the flat part like a seal, with a short red ribbon hanging from it. The parchment's edges are uneven and a little torn.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The scroll and its seal only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

## `icons/lab.png`: The Lab (science and nature)

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a round-bottomed laboratory flask as a flat paper-cutout game icon, seen from the front: a pale sky-blue flask with a long neck, a small tan cork in its mouth, filled two-thirds full with bright green liquid cut from green paper, with three round bubbles of lighter green rising from the liquid, one of them floating above the flask's neck.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The flask, its liquid and its bubbles only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

## `icons/stage.png`: The Stage (culture and entertainment)

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw two theatre masks as a flat paper-cutout game icon, seen from the front, overlapping: a smiling pumpkin-orange mask in front, and a frowning violet mask behind it, tilted a little to the right. Each mask has two almond-shaped eye holes and a simple curved mouth cut out, and a short yellow ribbon trails from the violet one.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The two masks only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

## Not Gemini prompts

The itch.io cover (630 × 500) and thumbnail (315 × 250) are made by hand; see the end of [asset_prompts.md](asset_prompts.md).
