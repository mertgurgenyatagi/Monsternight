# Asset prompts

A Gemini prompt for each of the 94 images in [assets.md](assets.md), except the paper texture, which Claude made with a script. Fonts and sounds aren't included. Every path below is inside `assets/art/`.

**Status:** the first playable's 83 images are made, approved by the user, and processed. The raws are in `images_raw/` as `.jfif` files (JPEG), and `tools/images/process_images.py` turns them into `assets/art/`. The final game adds 10, marked "New in part 26": the sumo and tug of war icons, and the Minigames section at the end.

The prompts are in the order to make them, not the order of assets.md. Some prompts need an earlier image attached so that a set matches: the icons follow the coin, the monsters follow Dracula, each portrait follows its body, the scenery strips follow the village's, and the minigame pieces follow the icons.

## Making an image

1. Start a new Gemini chat for each image, so earlier images don't leak into it.
2. If the prompt has an **Attach** line, attach that image, as Gemini made it.
3. Paste the whole prompt from the box.
4. Check the result. If one thing is wrong, reply in the same chat, for example "Same image, but with no shadow." Look out for:
   - text, letters or numbers (only the logo has any)
   - a background that isn't flat: texture, a gradient, a checkerboard, or a shadow or ground under the subject
   - a white sticker border around the shape
   - anything extra in the frame

   A monster or prop facing left is fine. Processing mirrors it.
5. Save the image as Gemini made it in `images_raw/`, under its file name with no folder, keeping Gemini's `.jfif` extension, for example `images_raw/coin.jfif`. Every name is unique, so the folder in `assets/art/` comes from this doc. Claude processes everything in `images_raw/` into `assets/art/`. `images_raw/` has a `.gdignore` file so Godot doesn't import the raw images.

## How the prompts are built

Every prompt has the four parts of the tested coin prompt: the subject, then Style, Composition and Output.

- **Style** is word for word the same in every prompt, so all the images look like one game.
- **Backgrounds** are pure white, or pure green (#00FF00) for subjects that are pale or have white in them. Each prompt says the subject can't contain its background color, so processing can remove every pixel of that color, including the gaps inside a shape, like the spaces between a tree's branches.
- **Sizes** are described in words, because Gemini doesn't follow exact sizes. Processing sets the final size.
- **Strips that tile** ask for matching ends with nothing eye-catching near the sides. Processing still fixes the seam.
- **Pieces the game colors** (the space and the portrait frame), and two it can color (the stand and the crumpled ball), are neutral light grey, so any color tints them cleanly.

The shared Style block:

> Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

## Processing

Each prompt ends with a one-line note: the background to remove, the final size, and any extra step. `tools/images/process_images.py` reads these notes and does this for each image:

1. Remove the background color everywhere it appears, including gaps inside the shape. Gemini's green isn't pure and drifts across the image, so the script measures each image's real background. Along the outline, it works out how much paper is in each pixel and takes the background back out of its color, so there's no light or green fringe on dark scenes.
2. Trim to the shape.
3. Mirror it, if the note says so and it faces left. Every image was checked, and all of them already face right, so nothing is mirrored.
4. Resize it, keeping its proportions. "600 tall" sets the height. A box size fits the shape inside the box and centers it. The cursor goes in the top-left corner instead.
   - The panel, button, card and curtain fill their box exactly: they're fitted, then their plain middle third is stretched, so the corners keep their shape.
   - Strips are scaled to their width, then cut to their height on the plain side (the earth, water or posts), never on the detailed edge. A strip that comes out too short is extended on its plain side with a mirror image of itself.
   - A strip with only a width, like the rope, keeps the height it comes out at, because both its edges show.
   - The curtain's top border was drawn much narrower than 1920 × 200, so it's made into a seamless strip that repeats twice across its width, cut on its straight top edge.
5. If it tiles, fix the seam: cut each end where the two ends match best, then join them along the line where they differ least, so the copies meet without a visible line or a ghosted double.
6. Save it as a PNG with transparency, under its name and folder in `assets/art/`.

Run it with `python tools/images/process_images.py . [<name> ...]` from the repository root. It rebuilds every image, or only the named ones.

## Icons: `icons/`

### `icons/coin.png`

This is the tested prompt, split into the shared blocks and moved to a white background.

```text
A single gold coin as a flat paper-cutout game icon, seen straight from the front. Made of two or three layered paper circles: a warm, saturated gold base, with a slightly darker gold inner ring as the raised rim. A small, simple bat silhouette cut from darker gold paper in the center.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One coin only, centered, filling most of the frame with a little empty space around it. Perfectly round. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 256 × 256.

### `icons/blood.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a single drop of blood as a flat paper-cutout game icon, seen straight from the front: a plump teardrop, pointed at the top and round at the bottom, cut from deep crimson paper, with a slightly smaller drop of brighter red paper layered on top.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One drop only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/swap.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw two curved arrows chasing each other as a flat paper-cutout game icon, seen straight from the front. Each arrow bends around half of a circle, with its head pointing at the other arrow's tail, so together they form a loop with an empty middle. One arrow is cut from bright violet paper and the other from pumpkin-orange paper.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The two arrows only, centered, filling most of the frame with a little empty space around them. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/spikes.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a row of spikes as a flat paper-cutout game icon, seen from the side: four sharp, tall triangular spikes of slightly different heights rising from a short, flat base strip. They're cut from steel blue-grey paper, with a lighter blue-grey layer on one side of each spike and a little blood-red paper on their tips.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One row of spikes only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/thief.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a sneaky gloved hand as a flat paper-cutout game icon, reaching toward the right with its fingers curled like claws, about to snatch something. A dark purple glove with a short, flared cuff at the wrist, with the fingers shown as layered pieces of slightly lighter purple.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One hand only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 128 × 128.

### `icons/church.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a little chapel as a flat paper-cutout game icon, seen from the front: a small stone chapel with a steep roof and a pointed bell tower with a small cross on top, one arched window in warm yellow and a small red arched door. Lavender-grey stone with a dark slate-blue roof.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One chapel only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/pong.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a game of Pong as a flat paper-cutout game icon, seen straight from the front: two upright cardboard paddles, one near the left and one near the right, with a small round ball between them, a little above the middle. The paddles are tall, thin rectangles with rounded ends, the left one pumpkin orange and the right one violet. The ball is bright yellow.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The two paddles and the ball only, centered, filling most of the frame with a little empty space around them. Nothing else in the frame: no table, net or lines. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/sumo.png`

New in part 26. **Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a game of sumo as a flat paper-cutout game icon, seen straight from above: a round ring of warm clay-brown paper, edged all the way around with a thick braided rope of golden-yellow straw, with two round pieces pressed together in its middle, one pumpkin orange and one violet.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The ring and the two pieces only, centered, filling most of the frame with a little empty space around them. Perfectly round. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/tug_of_war.png`

New in part 26. **Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a tug-of-war rope as a flat paper-cutout game icon: a short, thick, twisted rope of tan paper, pulled tight and running diagonally from the bottom left to the top right, with frayed ends, and a small bright red ribbon tied in a knot around its middle. The rope's twists are slanted strips of slightly darker tan.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One rope only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame: no hands, players or ground. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/haxball.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a ball between two goalposts as a flat paper-cutout game icon, seen straight from the front: two short, upright posts in light steel grey, one near the left and one near the right, with a round ball in the gap between them. The ball is pumpkin orange with a few dark purple patches, like a football.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The two posts and the ball only, centered, filling most of the frame with a little empty space around them. Nothing else in the frame: no net, field or lines. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/racing.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a coffin on wheels as a flat paper-cutout game icon, seen from the side and driving toward the right: a classic six-sided coffin shape lying flat, in dark reddish-brown wood paper with a lighter brown lid layer, on two round black wheels with grey hubs.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One coffin only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame: no road or speed lines. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 128 × 128.

### `icons/fps.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a crosshair as a flat paper-cutout game icon, seen straight from the front: a ring cut from bright red paper, with four short, straight ticks pointing in toward the center from the top, bottom, left and right, and a small round dot in the middle.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One crosshair only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `icons/flag.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a small pennant as a flat paper-cutout game icon: a long triangular flag on a short, thin pole, pointing and waving toward the right. A dark brown pole with a small round knob on top, and a bright orange pennant with a wavy, hand-cut edge.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One pennant only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 128 × 128.

## Board: `board/`

### `board/space.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin, but with no picture on it. Draw a plain round paper token for a board-game space, seen straight from the front: a light grey paper disc with a slightly smaller, paler grey disc layered on top, leaving an even rim all the way around. Completely plain, with no symbol, pattern or decoration. Neutral greys with no color tint, because the game colors it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One token only, centered, filling most of the frame with a little empty space around it. Perfectly round. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 192 × 192.

### `board/die_1.png`

```text
One face of a paper die, seen straight from the front: a square of darker bone-colored paper with softly rounded corners, with a slightly smaller square of pale bone-colored paper layered on top, leaving an even rim all the way around. One round pip cut from deep blood-red paper sits in the exact center. The pip is a plain round dot, not a number.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/die_2.png`

**Attach:** your image for `board/die_1.png`.

```text
One face of a paper die, seen straight from the front, exactly like the attached image (the same paper, colors, rim and pip size), but with two round blood-red pips: one in the top-left corner and one in the bottom-right corner. The pips are plain round dots, not numbers.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/die_3.png`

**Attach:** your image for `board/die_1.png`.

```text
One face of a paper die, seen straight from the front, exactly like the attached image (the same paper, colors, rim and pip size), but with three round blood-red pips: in a diagonal line from the top-left corner, through the center, to the bottom-right corner. The pips are plain round dots, not numbers.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/die_4.png`

**Attach:** your image for `board/die_1.png`.

```text
One face of a paper die, seen straight from the front, exactly like the attached image (the same paper, colors, rim and pip size), but with four round blood-red pips: one in each corner. The pips are plain round dots, not numbers.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/die_5.png`

**Attach:** your image for `board/die_1.png`.

```text
One face of a paper die, seen straight from the front, exactly like the attached image (the same paper, colors, rim and pip size), but with five round blood-red pips: one in each corner and one in the center. The pips are plain round dots, not numbers.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/die_6.png`

**Attach:** your image for `board/die_1.png`.

```text
One face of a paper die, seen straight from the front, exactly like the attached image (the same paper, colors, rim and pip size), but with six round blood-red pips: in two upright rows of three, along the left and right sides. The pips are plain round dots, not numbers.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One die face only, perfectly square, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 160 × 160.

### `board/path_dot.png`

```text
A small scrap of paper, seen straight from the front: a roughly round, slightly irregular piece of cream paper, torn by hand, with a soft, ragged edge.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One scrap only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 32 × 32.

### `board/signpost.png`

```text
A crooked wooden signpost, seen from the front: one upright post, leaning slightly, with two blank boards nailed to it near the top. Both boards are cut in the shape of arrows pointing right: the upper one tilts slightly up and the lower one slightly down. Warm brown wood paper in two tones, with a few dark nail dots and a crack or two. The boards are blank, with no words or symbols.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One signpost only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom of the post ends in a straight line, with no ground, grass or rocks around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, mirror it if it faces left, 400 tall.

### `board/arrow.png`

```text
A chunky paper arrow pointing right, seen straight from the front: a short, thick shaft and a wide triangular head, cut from dark orange paper, with a slightly smaller arrow of bright pumpkin-orange paper layered on top, leaving an even darker rim.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One arrow only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, mirror it if it faces left, 160 × 100.

## Monsters: `monsters/`

### `monsters/dracula.png`

```text
Count Dracula as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A pale grey face with a sharp widow's peak of slicked-back black hair, pointed ears, arched black eyebrows and a sly grin showing two small fangs. A long black cape with a tall, stand-up collar and a bright red lining that shows inside the collar and down the front edges where the cape hangs open. Under it, a black suit with a white shirt front and a deep red waistcoat. Red is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 512 tall.

### `monsters/dracula_portrait.png`

**Attach:** your image for `monsters/dracula.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. The tall collar with its red lining frames his face.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head inside the frame. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, mirror it if it faces left, 256 × 256.

### `monsters/medusa.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Medusa the gorgon as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A pale olive-green face with solid yellow eyes, black slit pupils and a wicked smile. Instead of hair, a crown of about a dozen writhing snakes in two or three shades of green, each with a tiny head and a red forked tongue. A long, flowing emerald-green gown covered in a pattern of darker green scales, with gold armbands. Green is her signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, mirror it if it faces left, 512 tall.

### `monsters/medusa_portrait.png`

**Attach:** your image for `monsters/medusa.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. All of the snakes are in the picture.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head, snakes included, inside the frame. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 256 × 256.

### `monsters/frankenstein.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Frankenstein's Monster as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A tall, flat-topped, square head with a short black fringe of hair, grey-green skin, a heavy brow over small dark eyes, a row of dark stitches across the forehead, and two short steel-grey bolts sticking out of the sides of the neck. A dark brown jacket that is clearly too small, with sleeves ending well above the wrists, dark grey trousers and big, clunky black boots. Small, bright yellow paper lightning bolts crackle out of both neck bolts. Yellow is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, mirror it if it faces left, 512 tall.

### `monsters/frankenstein_portrait.png`

**Attach:** your image for `monsters/frankenstein.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. Both neck bolts and their yellow lightning are in the picture.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head inside the frame. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 256 × 256.

### `monsters/death.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Death, the Grim Reaper as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A long hooded robe in deep violet-black with a ragged, tattered hem, a grinning skull peeking out of the hood with dark, empty eye sockets, and bony hands gripping a tall wooden scythe. The scythe is held upright in front of the body, with its curved steel-grey blade arching over the head toward the right. Behind the whole figure is a slightly larger flat paper shape in bright violet with a soft, wavy edge, like a cut-paper aura: this is his violet glow, made of paper, not light. Violet is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 512 tall.

### `monsters/death_portrait.png`

**Attach:** your image for `monsters/death.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. Show the hood and the skull with the violet paper aura behind them, and the tip of the scythe blade rising behind one shoulder.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole hood inside the frame. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, mirror it if it faces left, 256 × 256.

### `monsters/hyde.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Mr. Hyde as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A hunched, broad-shouldered brute with long, dangling arms and big hands, wild black hair, bushy sideburns, a heavy brow, small beady eyes and a wide, crazed grin full of crooked, yellowed teeth. A torn black Victorian frock coat, ripped at the shoulders and sleeves, over a bright orange waistcoat with brass buttons, and a torn white shirt collar with a loose black cravat. Orange is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 512 tall.

### `monsters/hyde_portrait.png`

**Attach:** your image for `monsters/hyde.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. Show the crazed grin, and the orange waistcoat along the bottom edge.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head inside the frame. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, mirror it if it faces left, 256 × 256.

### `monsters/cthulhu.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Cthulhu as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A big octopus-like head in teal, with a cluster of short, curling tentacles hanging where the mouth and chin would be, and narrow, glaring yellow eyes under a heavy brow. A hulking, hunched body with broad, heavy shoulders, a barrel chest and long, thick arms ending in big hooked claws, with scaly teal skin and clawed feet. Two ragged bat-like wings in a darker teal rise from its back, half spread above the shoulders. An ancient, menacing sea god, not a baby or a pet. Teal is its signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, mirror it if it faces left, 512 tall.

### `monsters/cthulhu_portrait.png`

**Attach:** your image for `monsters/cthulhu.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. Show the face tentacles, with the tips of the wings peeking up behind the shoulders.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head inside the frame. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, mirror it if it faces left, 256 × 256.

### `monsters/wolfman.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. The Wolf Man as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A werewolf with shaggy brown fur, pointed ears, a long snout with a black nose, fierce yellow eyes and a snarl showing small white fangs. A torn blue work shirt with ripped short sleeves, and dark brown trousers ripped off at the shins, showing bare, furry, clawed feet. Blue is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 512 tall.

### `monsters/wolfman_portrait.png`

**Attach:** your image for `monsters/wolfman.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. Show the snarl, the pointed ears and the collar of the blue shirt.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head, ears included, inside the frame. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, mirror it if it faces left, 256 × 256.

### `monsters/dorian.png`

**Attach:** your image for `monsters/dracula.png`.

```text
Match the paper style, proportions and pose of the attached image, but draw a completely different character. Dorian Gray as a flat paper-cutout board-game piece: a full-body character standing still, turned in three-quarter view toward the right side of the image. Chunky, slightly big-headed cartoon proportions, about three heads tall, with the arms close to the body. A handsome young Victorian dandy with neat, wavy chestnut hair and a smug little smile. A fine pink frock coat, a darker pink waistcoat, a white shirt with a white cravat, grey trousers and polished black shoes. In one hand he holds up, at chest height, a small gold picture frame with a painting of his own face inside it, but rotten and monstrous: grey-purple skin, sunken eyes and a wicked grin. Pink is his signature color and should stand out.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One character only, standing upright, full body from head to feet, centered, filling most of the frame's height. Nothing else in the frame: no stand, base, ground or scenery under the feet. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 512 tall.

### `monsters/dorian_portrait.png`

**Attach:** your image for `monsters/dorian.png`.

```text
A head-and-shoulders portrait of the character in the attached image, with the same face, colors, clothes and paper style. Turned in three-quarter view toward the right side of the image, like the original, and cut off in a straight line just below the shoulders. He holds the small framed painting up beside his face, so his handsome face and the rotten painted one sit side by side.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait only, centered, filling most of the frame, with the whole head inside the frame. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, mirror it if it faces left, 256 × 256.

### `monsters/stand.png`

```text
A small paper stand for a board-game piece, seen from the side, like the base that holds up a cardboard figure: a low, wide, flattened half-oval with a straight bottom edge and a gently rounded top. A light grey paper base with a slightly smaller, paler grey layer on top, leaving an even rim. Neutral greys with no color tint, so the game can color it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One stand only, centered, filling the width of the frame with a little empty space around it. Nothing else in the frame: no figure or ground. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, 200 × 60.

### `monsters/crumpled.png`

```text
A crumpled ball of paper, seen straight from the front: a rough, lumpy, roughly round ball, with its creases shown as flat facets in two or three slightly different light greys. Neutral greys with no color tint, so the game can color it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One paper ball only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 256 × 256.

## Interface: `ui/`

### `ui/logo.png`

Check the spelling letter by letter, and retry until it's right.

```text
The game's logo: the single word MONSTERNIGHT, spelled exactly M-O-N-S-T-E-R-N-I-G-H-T, in one line, made of cut-paper letters, like the title of an old monster movie. Tall, sharp gothic letters, hacked out of paper with a knife: jagged edges, thorn-like spikes on the serifs, and letter ends that taper into points like claws and fangs. The letters are uneven and alive: different heights, leaning and crowding into each other, with the first M and the last T bigger than the rest. The O is a glaring yellow eye with a black slit pupil. Each letter is cut from bone-colored paper with a slightly larger black layer behind it, and the whole word sits on one jagged, torn shape of deep blood-red paper. Still easy to read.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: The word only, centered, filling the width of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no other text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, 1600 × 500.

### `ui/cursor.png`

```text
A mouse pointer shaped like a bony skeleton hand, seen flat from the front. The index finger points diagonally up and to the left, with its fingertip at the very top-left of the shape. The other fingers curl into the palm, and a short stub of wrist bone ends toward the bottom right. Chunky, simple bones, each cut from black paper with a slightly smaller cream piece layered on top, leaving a thin black rim all around, so it stays visible on both light and dark screens.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One hand only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 64 × 64, with the fingertip in the top-left corner.

### `ui/panel.png`

```text
A plain paper card with torn edges, seen straight from the front: a square sheet of warm cream paper with all four edges torn by hand, in a soft, slightly ragged tear. The tear looks the same all the way around, with no side or corner more ragged than the others. The middle is completely plain, with no marks, stains or decoration, because the game stretches it and puts text on it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One card only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 512 × 512.

### `ui/button.png`

**Attach:** your image for `ui/panel.png`.

```text
Match the paper of the attached card. Draw a paper tag for a button, seen straight from the front: a wide strip of dark plum paper with softly rounded corners, about three times as wide as it is tall, with a slightly smaller strip of warm cream paper layered on top, leaving an even, thin plum rim all the way around. The top and bottom edges are straight and even along their whole length, and the middle is completely plain, because the game stretches it sideways and puts text on it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tag only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, 400 × 120.

### `ui/card.png`

**Attach:** your image for `ui/panel.png`.

```text
Match the paper of the attached card. Draw a blank playing card, seen straight from the front: an upright rectangle of deep red paper with rounded corners, about one and a half times as tall as it is wide, with a slightly smaller rectangle of warm cream paper layered on top, leaving an even, thin red rim all the way around. The middle is completely plain, because the game puts pictures and text on it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One card only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, 400 × 560.

### `ui/portrait_frame.png`

```text
A square paper frame for a portrait, seen straight from the front: a square of light grey paper with a scalloped, wavy-cut outer edge, with a plain square of paler grey paper layered on its middle, where the portrait goes. The inner square takes up most of the frame. Neutral greys with no color tint, because the game colors it in each monster's color.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One portrait frame only, centered, filling most of the image with a little empty space around it. Nothing else in the image: no portrait inside it. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 300 × 300.

### `ui/candle.png`

```text
A tall, plain candle with no flame, seen straight from the front: a straight column of ivory wax, about three times as tall as it is wide and the same width all the way down, with a few drips running down from its uneven top edge and a short black wick. No holder, plate or base.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One candle only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. Nothing on the wick: no flame, smoke or glow. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, 120 × 400.

### `ui/flame.png`

```text
A single candle flame, seen straight from the front: a teardrop shape with a round bottom and a pointed tip that curls very slightly, built from three nested layers of paper: red-orange on the outside, bright orange inside it, and yellow in the middle.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One flame only, centered, filling most of the frame's height. Nothing else in the frame: no candle, wick, glow or light around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 64 × 96.

### `ui/trophy.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style and gold colors of the attached coin. Draw a trophy cup, seen straight from the front: a wide gold cup with two curved handles, on a short stem and a stepped base. Warm gold paper, with a slightly darker gold layer for the rim of the cup and for the base, and a small bat cut from darker gold paper on the front of the cup.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One trophy only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 256 × 256.

### `ui/curtain.png`

```text
The left half of a closed red theater curtain, seen straight from the front: heavy velvet folds hanging straight down, shown as long, upright strips of paper in three shades of deep red and crimson, overlapping one another. The bottom hem is cut in a gentle wave and edged with a thin gold trim. Both side edges run straight down: the left one meets the side of the stage, and the right one meets the other half of the curtain.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One curtain half only, filling the image from the top edge down to just above the bottom, and from the left edge to the right edge. Nothing else in the frame: no stage, floor, rope or tieback. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 1000 × 1080.

### `ui/curtain_top.png`

**Attach:** your image for `ui/curtain.png`.

```text
Match the paper and colors of the attached curtain. Draw its scalloped top border, seen straight from the front: a long horizontal band of deep red paper whose bottom edge is cut into a row of identical, rounded swags, each edged with a thin gold trim, with a small gold tassel hanging where each pair of swags meets. The top edge is straight.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One band across the full width of the image, running off the left and right edges, along the top of the image and taking up about its top third, with plain background below it. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 1920 × 200.

## Shared scenery: `scenery/`

### `scenery/moon.png`

```text
A big full moon, seen straight from the front: a round disc of pale, creamy yellow paper, with a few craters cut as soft round patches of slightly darker cream paper.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One moon only, centered, filling most of the frame with a little empty space around it. Perfectly round. Nothing else in the frame: no clouds, bats or stars. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 600 × 600.

### `scenery/star.png`

```text
A small star, seen straight from the front: a simple five-pointed star cut from pale warm yellow paper, with slightly chubby, uneven points, and a smaller, paler star layered in its middle.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One star only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove green, 48 × 48.

### `scenery/fog_1.png`

```text
A long, low strip of fog, seen from the side, about four times as wide as it is tall: a soft, cloud-like band with a lumpy top edge made of overlapping rounded puffs, a flatter bottom edge, and ends that taper away. Cut from two layers of pale paper: a lavender-grey back layer and a slightly lighter, smaller front layer.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One fog strip only, centered, filling the width of the frame with a little empty space at both ends. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, 1200 × 300.

### `scenery/fog_2.png`

**Attach:** your image for `scenery/fog_1.png`.

```text
Match the paper, colors and size of the attached fog strip, but give it a different outline. A long, low strip of fog, seen from the side, about four times as wide as it is tall: two big humps of rounded puffs with a dip between them, a flatter bottom edge, and a longer, thinner tail trailing off to the right.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One fog strip only, centered, filling the width of the frame with a little empty space at both ends. Nothing else in the frame. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, 1200 × 300.

### `scenery/bat.png`

```text
A bat with its wings spread wide, seen straight from the front: a small round body with two pointy ears and two tiny yellow eyes, and two big wings stretched out to the sides, each with a scalloped bottom edge ending in three points. Cut from dark plum-purple paper, with a slightly lighter purple layer on the body.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One bat only, centered, with level, matching wings filling the width of the frame. Nothing else in the frame. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 160 × 80.

### `scenery/paper_texture.png`

**Done, no prompt needed.** Gemini kept failing on this one, so Claude made it with a script: soft grain, fibers and flecks in light and dark grey on a transparent image. It tiles perfectly on all four sides. The game sets how faint it is.

## Foggy village: `scenery/`

### `scenery/village_far.png`

```text
The distant skyline of a crooked old village, as a long horizontal strip seen from the side: a row of leaning houses with steep, crooked gables, tilted chimneys and a small pointed tower or two, at different heights, all joined into one paper shape. Two overlapping paper layers: a back row in dusty blue-violet and a front row in deeper indigo-purple. A few small lit windows in warm yellow are scattered across the front row. Below the rooftops, the paper runs down as a solid band to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower half of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 600, tiles sideways.

### `scenery/village_ground.png`

```text
The edge of a cobbled road, as a long horizontal strip seen from the side: along the top, a row of rounded cobblestones of slightly different sizes in slate grey and blue-grey, with a few darker stones. Their tops make a fairly level, gently bumpy top edge. Below them, dark brown earth with a few small pebbles fills the rest of the strip down to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 300, tiles sideways.

### `scenery/village_house_1.png`

```text
A crooked old village house, seen from the front: two stories tall and leaning slightly to one side, with a steep, crooked roof, a tilted chimney, a small arched door, and a few lit windows in warm yellow with dark frames. Plum-purple walls with dark brown timber beams and a slate-blue roof.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One house only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom of the house ends in a straight line, with no ground, street, fence or other buildings around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 600 tall.

### `scenery/village_house_2.png`

**Attach:** your image for `scenery/village_house_1.png`.

```text
Match the paper style of the attached house, but draw a different one. A crooked old village house, seen from the front: tall and narrow, three stories, leaning the other way, with a pointed gable roof, a round attic window, and a few lit windows in warm yellow with dark frames. Dusty teal walls with dark brown timber beams and a dark red roof.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One house only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom of the house ends in a straight line, with no ground, street, fence or other buildings around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 600 tall.

### `scenery/village_lamp.png`

```text
An old gas street lamp, seen from the front: a tall, thin iron post with a curly bracket near the top, holding a four-sided lantern with a pointed cap. Dark slate-blue iron, with the lantern's glass panes in flat warm yellow, as if lit.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One lamp only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The post ends in a small flat foot at the bottom, with no ground around it, and there is no glow or light around the lantern. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 500 tall.

## Graveyard and church: `scenery/`

### `scenery/graveyard_far.png`

**Attach:** your image for `scenery/village_far.png`.

```text
Match the paper style and layering of the attached strip, but show different scenery. Distant graveyard hills, as a long horizontal strip seen from the side: soft rolling hills in two overlapping paper layers, a back layer in muted grey-violet and a front layer in deep mossy teal-green. Small crosses, a few tombstones and a couple of bare, spindly trees stand on the hilltops, cut as part of the same paper. Below the hills, the paper runs down as a solid band to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower half of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 600, tiles sideways.

### `scenery/graveyard_ground.png`

**Attach:** your image for `scenery/village_ground.png`.

```text
Match the paper style of the attached strip, but show different ground. Grassy graveyard earth, as a long horizontal strip seen from the side: a fringe of tufty, mossy green grass along the top edge, with dark brown soil below it filling the rest of the strip down to the bottom of the image. A few tan roots curl through the soil, with a small stone here and there.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 300, tiles sideways.

### `scenery/graveyard_stone_1.png`

```text
A rounded tombstone, seen straight from the front: an upright stone slab with a rounded top, in medium blue-grey paper, with a slightly darker arched panel inset on its face, a small crack near one corner, and a little tuft of green moss at its base. The panel is blank, with no writing or symbols.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tombstone only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom ends in a straight line, with no ground or grass around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 250 tall.

### `scenery/graveyard_stone_2.png`

**Attach:** your image for `scenery/graveyard_stone_1.png`.

```text
Match the paper style and stone colors of the attached tombstone, but draw a different grave marker. A stone cross, seen straight from the front: chunky, short arms, tilted slightly to one side, with a chipped corner and a little green moss on one arm, standing on a small square stone base. Blank, with no writing or symbols.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One cross only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom ends in a straight line, with no ground or grass around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 300 tall.

### `scenery/graveyard_tree.png`

```text
A bare, twisted tree, seen from the side: a thin, crooked trunk that bends and splits into spindly branches curling outward like bony fingers, with no leaves. Dark plum-brown bark paper, with a slightly lighter layer along one side of the trunk, and a few short roots at the base.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tree only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The roots are cut off in a straight line at the bottom, with no ground or grass around them. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 800 tall.

### `scenery/church_hill.png`

**Attach:** your image for `scenery/graveyard_ground.png`.

```text
Match the grass and earth of the attached strip. Draw a low, wide grassy hill, seen from the side, as one big paper shape about four times as wide as it is tall: a gently rounded mound, not a dome. Its sides rise slowly from the bottom at each end into a long, broad, almost flat top. A fringe of tufty, mossy green grass runs along the whole top edge, over dark brown earth with a few roots and stones. The bottom edge is straight, and the top curve is smooth and even, with nothing on it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One hill only, centered, filling the width of the frame with a little empty space at both ends. Nothing else in the frame: no church, trees, gravestones or sky. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2400 × 800.

### `scenery/church_building.png`

```text
A small stone church, seen from the side: a short main hall with a steep roof and two arched windows, and a tall bell tower at one end with a pointed spire, an open arch holding a bell, and a small cross on top. Lavender-grey stone paper with darker stone blocks, a dark slate-blue roof, a gold bell, warm yellow lit windows and a red arched door.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One church only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom ends in a straight line, with no hill, ground, graves or trees around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 1000 tall.

## Dark forest: `scenery/`

### `scenery/forest_far.png`

**Attach:** your image for `scenery/village_far.png`.

```text
Match the paper style and layering of the attached strip, but show different scenery. A dense line of distant forest, as a long horizontal strip seen from the side: tall, pointed fir trees of uneven heights packed close together, joined into one jagged paper skyline, in two overlapping layers: a back layer in muted teal-blue and a front layer in deep pine green with a hint of plum. Below the treetops, the paper runs down as a solid band to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower half of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 600, tiles sideways.

### `scenery/forest_ground.png`

**Attach:** your image for `scenery/village_ground.png`.

```text
Match the paper style of the attached strip, but show different ground. Dark forest floor, as a long horizontal strip seen from the side: a fringe of dark green moss and fallen leaves in orange, red and ochre along the top edge, with dark brown earth below it filling the rest of the strip down to the bottom of the image, crossed by a few gnarled roots in lighter brown.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 300, tiles sideways.

### `scenery/forest_tree_1.png`

```text
A big, gnarled, twisted tree, seen from the side: a thick trunk that twists as it rises, with a spooky face in the bark (two hollow eyes and a gaping mouth, cut from near-black paper), long, crooked branches and a few jagged clumps of dark green leaves. Dark brown bark paper with a lighter brown layer along one side, and thick roots at the base.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tree only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The roots are cut off in a straight line at the bottom, with no ground or grass around them. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 900 tall.

### `scenery/forest_tree_2.png`

**Attach:** your image for `scenery/forest_tree_1.png`.

```text
Match the paper style and colors of the attached tree, but draw a different tree with no face. A big, gnarled, twisted tree, seen from the side: leaning to one side, with a trunk that splits in two, a dark knothole, differently shaped crooked branches and jagged clumps of dark green leaves, and thick roots at the base.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tree only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The roots are cut off in a straight line at the bottom, with no ground or grass around them. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 900 tall.

### `scenery/forest_mushrooms.png`

```text
A cluster of glowing toadstools, seen from the side: four toadstools of different heights growing from one small clump, with round, domed caps in bright cyan and acid yellow-green, dotted with lemon-yellow spots, on pale lilac stems. They look lit up through their bright colors alone, with no halo or light around them.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One cluster only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The clump is cut off in a straight line at the bottom, with no other ground, grass or leaves around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 200 tall.

## Swamp: `scenery/`

### `scenery/swamp_far.png`

**Attach:** your image for `scenery/village_far.png`.

```text
Match the paper style and layering of the attached strip, but show different scenery. Distant swamp trees, as a long horizontal strip seen from the side: low, squat trees with wide, flat crowns and long moss hanging from their branches, in two overlapping paper layers: a back layer in soft, hazy blue-green that looks misty, and a front layer in deeper murky olive-green. Below the trees, the paper runs down as a solid band to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower half of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 600, tiles sideways.

### `scenery/swamp_ground.png`

**Attach:** your image for `scenery/village_ground.png`.

```text
Match the paper style of the attached strip, but show different ground. A muddy swamp bank, as a long horizontal strip seen from the side: dark olive-brown mud with a soft, sloppy, wavy top edge, with a few pebbles, broken twigs and patches of darker mud, filling the strip down to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 300, tiles sideways.

### `scenery/swamp_water.png`

```text
Murky swamp water, as a long horizontal strip seen from the side: a band of deep, murky green water whose top edge is cut into small, even, rounded waves, with a slightly lighter green wave layer just below the top. A few small bubbles and floating duckweed dots in yellow-green. The water fills the strip down to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 200, tiles sideways.

### `scenery/swamp_boardwalk.png`

```text
A rickety wooden boardwalk, as a long horizontal strip seen from the side: a walkway of uneven planks seen edge-on along the top, slightly crooked and gapped, held up by thin wooden posts that go straight down at even spacing, with a few crossed braces between them. The posts end in a straight line at the bottom. Weathered brown wood in two tones, with a few dark nail dots.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges, in the middle of the frame and taking up about a fifth of its height, with plain background above and below it. Nothing else in the frame: no water, railings or plants. The left and right ends look alike, with the walkway at the same height on both sides and the posts evenly spaced, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 1024 × 150, tiles sideways.

### `scenery/swamp_tree.png`

```text
A bald cypress tree hung with moss, seen from the side: a trunk that flares out wide at the base into buttress roots, with a couple of knobbly cypress knees poking up beside it, and crooked branches spreading near the top. Long curtains of moss hang from the branches in grey-green strands. Dark grey-brown bark paper.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One tree only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The base is cut off in a straight line at the bottom, with no water, mud or ground around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 900 tall.

### `scenery/swamp_reeds.png`

```text
A clump of reeds and cattails, seen from the side: tall, thin blades of grass-green and olive reeds fanning out from one clump, some of them bent over, with three or four cattails on thin stalks topped with plump brown seed heads.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One clump only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The clump is cut off in a straight line at the bottom, with no water or ground around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 300 tall.

## Dracula's castle: `scenery/`

### `scenery/castle_far.png`

**Attach:** your image for `scenery/village_far.png`.

```text
Match the paper style and layering of the attached strip, but show different scenery. Distant jagged mountains, as a long horizontal strip seen from the side: sharp, crooked peaks of uneven heights in two overlapping paper layers, a back layer in dusky crimson-purple and a front layer in deep wine-purple. Below the peaks, the paper runs down as a solid band to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower half of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 600, tiles sideways.

### `scenery/castle_ground.png`

**Attach:** your image for `scenery/village_ground.png`.

```text
Match the paper style of the attached strip, but show different ground. An old stone road, as a long horizontal strip seen from the side: along the top, a row of large, worn, uneven stone blocks in dark grey-violet, with cracks and chipped corners. Below them, darker purple-grey rubble and earth fill the rest of the strip down to the bottom of the image.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous strip across the full width of the image, running off the left and right edges and filling the lower third of the image down to the bottom edge, with plain background above it. Nothing else in the frame. The left and right ends look alike and sit at the same height, with nothing eye-catching near either side, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 2048 × 300, tiles sideways.

### `scenery/castle.png`

```text
Dracula's castle on a cliff, seen from the side: a cluster of tall, thin towers of different heights with pointed, needle-sharp roofs, packed together on top of a jagged rocky cliff that narrows toward the bottom. Many small lit windows in warm yellow, and a few small red pennants on the tallest spires. Dark slate-purple stone paper, deep red roofs and a grey-brown cliff.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One castle only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The cliff ends in a straight line at the bottom, with no moon, bats, sky or other mountains around it. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 1600 tall.

### `scenery/castle_gate.png`

**Attach:** your image for `scenery/castle.png`.

```text
Match the stone and colors of the attached castle, but draw its front gate on its own. A big castle gate, seen straight from the front: a tall, pointed stone archway holding two heavy, closed wooden doors, banded with black iron straps and studs, with big iron ring handles, and a small red bat emblem above the arch. Dark slate-purple stone blocks around the arch, and dark brown wood for the doors.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One gate only, standing upright, centered, filling most of the frame's height. Nothing else in the frame. The bottom ends in a straight line, with no walls, towers, road or ground on either side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, 700 tall.

### `scenery/castle_torch.png`

```text
An old wall torch with no fire, seen from the side: a wooden torch handle with a few strips of dark cloth wrapped around its top, held in a black iron wall bracket with a small plate at the back, the torch tilting slightly out toward the right. The top of the torch is a dark, empty cup with nothing burning in it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One torch only, centered, filling most of the frame's height. Nothing else in the frame: no flame, smoke, glow or wall. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove white, mirror it if it faces left, 250 tall.

## Minigames: `minigames/`

New in part 26: the minigames' pieces, for the painted table of [minigames.md](minigames.md). Make the two icons above first, because the ring follows the sumo icon. The paddle and the boot are grey, so the game can tint them in each monster's color.

### `minigames/pong_table.png`

**Attach:** your image for `icons/coin.png`.

```text
Match the paper style of the attached coin. Draw a Pong table seen straight from above, like a painted ping-pong table: a wide rectangle of deep bottle-green paper with slightly rounded corners, about twice as wide as it is tall, with a thin pale-yellow strip running all the way around its edge and a dashed pale-yellow line running straight down its middle from top to bottom. The rest of the table is completely plain.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One table only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame: no net, paddles, ball, legs or floor. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 1600 × 900.

### `minigames/paddle.png`

**Attach:** your image for `icons/pong.png`.

```text
Match the paper style and the paddle shape of the attached icon. Draw a single cardboard paddle seen straight from above: a tall, thin, upright rectangle with rounded ends, about five times as tall as it is wide, cut from light grey paper with a slightly smaller, paler grey layer on top, leaving an even rim all the way around. Neutral greys with no color tint, so the game can color it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One paddle only, standing upright, centered, filling most of the frame's height. Nothing else in the frame: no ball or table. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, 300 tall.

### `minigames/sumo_ring.png`

**Attach:** your image for `icons/sumo.png`.

```text
Match the paper style and colors of the ring in the attached icon. Draw a sumo ring seen straight from above: a big round disc of warm clay-brown paper, edged all the way around with a thick braided rope of golden-yellow straw. The clay inside the rope is completely plain, with nothing standing on it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One ring only, centered, filling most of the frame with a little empty space around it. Perfectly round. Nothing else in the frame: no pieces, players or floor. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 1000 × 1000.

### `minigames/goal.png`

```text
A football goal seen exactly from the side, as in a side-on 2D football game, with its open mouth facing right: one upright post on the right made of a big cream-colored bone, a crossbar made of another bone running from the top of the post back to the left, and a net of thin dark grey string hanging from the crossbar down to the ground behind the post, in a loose square grid with large open gaps between the strings.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One goal only, standing upright, centered, filling most of the frame's height. Nothing else in the frame: no ground, field, ball or players. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a tall image, taller than it is wide.
```

**Processing:** remove green, mirror it if it faces left, 500 tall.

### `minigames/ball.png`

**Attach:** your image for `icons/haxball.png`.

```text
Match the paper style and colors of the ball in the attached icon. Draw a single football seen straight from the front: a round ball of pumpkin-orange paper with a few dark purple patches, like the panels of a football.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One ball only, centered, filling most of the frame with a little empty space around it. Perfectly round. Nothing else in the frame: no goalposts or ground. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.

### `minigames/boot.png`

```text
A little boot for a cardboard game piece, seen from the side with its toe pointing right: a short, chunky ankle boot with a big rounded toe and a low flat heel, cut from light grey paper, with a darker grey sole and a few darker grey laces. Neutral greys with no color tint, so the game can color it.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One boot only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame: no leg, foot, ball or ground. Plain, flat, pure green background (#00FF00), and no green anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove green, mirror it if it faces left, 160 × 100.

### `minigames/rope.png`

**Attach:** your image for `icons/tug_of_war.png`.

```text
Match the paper style and colors of the rope in the attached icon. Draw a long, thick, twisted rope as a horizontal strip seen from the side, lying perfectly straight and level: tan paper, with its twists shown as evenly spaced, slanted strips of slightly darker tan. No knots, ribbon or frayed ends.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One continuous rope across the full width of the image, running off the left and right edges, in the middle of the frame and taking up about a tenth of its height, with plain background above and below it. Nothing else in the frame. The left and right ends look alike, with the rope at the same height and thickness on both sides and its twists evenly spaced, so copies can be placed side by side. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a wide image, wider than it is tall.
```

**Processing:** remove white, 1024 wide, tiles sideways.

### `minigames/ribbon.png`

**Attach:** your image for `icons/tug_of_war.png`.

```text
Match the paper style and colors of the ribbon in the attached icon. Draw a bright red cloth ribbon tied in a tight knot, seen from the front: a small round knot in the middle, with two short, wavy tails hanging down from it at slightly different angles, their ends cut in a V. A slightly darker red layer shows the folds of the knot.

Style: flat construction-paper cutout, like the South Park movie's paper animation. Built from a few layered pieces of colored paper with slightly uneven hand-cut edges and a faint paper-fiber texture. Few colors, each one flat. Playful and spooky, colorful rather than bleak, not realistic. No shine, glow, gradients, outlines or 3D effects.

Composition: One ribbon only, centered, filling most of the frame with a little empty space around it. Nothing else in the frame: no rope. Plain, flat, pure white background (#FFFFFF), and no white anywhere on the subject. No shadow, no border or outline around the shape, and no text, letters or numbers.

Output: a square image.
```

**Processing:** remove white, 128 × 128.
